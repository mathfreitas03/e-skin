import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'dart:convert';

// UUIDs do ESP32
const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String charHolaUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a1";
final Uuid counterCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a2");
final Uuid rxCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a3");

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();

  DiscoveredDevice? espDevice;

  Future<bool> scanForEsp() async {
    print("➡️ Iniciando scan...");

    StreamSubscription<DiscoveredDevice>? scanStream;

    scanStream = ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == "ESP32 BLE test APP") {
        print("✅ ESP encontrado: ${device.id}");
        espDevice = device;
        scanStream?.cancel();
      }
    });

    await Future.delayed(const Duration(seconds: 8));

    await scanStream.cancel();

    return espDevice != null;
  }

  Future<bool> connect() async {
    if (espDevice == null) {
      print("❌ Nenhum dispositivo ESP foi encontrado para conectar.");
      return false;
    }

    print("➡️ Conectando ao ESP32...");

    try {
      await ble.connectToDevice(id: espDevice!.id).first;
      print("✅ Conectado ao ESP32!");
      return true;
    } catch (e) {
      print("❌ Erro ao conectar: $e");
      return false;
    }
  }

  Stream<String> subscribeHola(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(charHolaUuid),
      deviceId: deviceId,
    );

    return ble.subscribeToCharacteristic(characteristic).map((data) {
      return utf8.decode(data); // Converte bytes → string
    });
  }

  Stream<int> subscribeCounter(String deviceId) {
    return ble
        .subscribeToCharacteristic(
          QualifiedCharacteristic(
            deviceId: deviceId,
            serviceId: Uuid.parse(serviceUuid),
            characteristicId: counterCharUuid,
          ),
        )
        .map((data) {
          final text = String.fromCharCodes(data);
          return int.tryParse(text) ?? 0;
        });
  }

  // Função para enviar número ao ESP32
  Future<bool> writeRx(String deviceId, String value) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUuid),
        characteristicId: rxCharUuid,
      );

      await ble.writeCharacteristicWithResponse(
        characteristic,
        value: value.codeUnits, // envia string
      );

      print("📤 Enviado para RX: $value");
      return true;
    } catch (e) {
      print("❌ Erro ao enviar para RX: $e");
      return false;
    }
  }

  // === Característica 4: Quadrado ===
  Stream<String> subscribeSquare(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a4"),
      deviceId: deviceId,
    );

    return ble
        .subscribeToCharacteristic(characteristic)
        .map((data) => String.fromCharCodes(data))
        .handleError((e) {
          print("❌ Erro ao ler quadrado: $e");
        });
  }
}
