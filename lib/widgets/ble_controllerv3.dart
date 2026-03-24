import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  DiscoveredDevice? esp32;

  //  Buffer para a nova comunicação 
  String _rxBuffer = "";

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  // ==== UUIDs ====
  final service1 = Uuid.parse("12345678-1234-1234-1234-1234567890ab");

  final charFreq = Uuid.parse("12345678-1234-1234-1234-1234567890ac");
  final charCap = Uuid.parse("12345678-1234-1234-1234-1234567890ad");
  final charRes = Uuid.parse("12345678-1234-1234-1234-1234567890ae");
  final charMod = Uuid.parse("12345678-1234-1234-1234-1234567890af");

  final service2 = Uuid.parse("87654321-4321-4321-4321-0987654321ba");
  final charControl = Uuid.parse("87654321-4321-4321-4321-0987654321bb");
  final charLed = Uuid.parse("87654321-4321-4321-4321-0987654321bc");

  final service3 = Uuid.parse("11223344-5566-7788-9900-aabbccddeeff");
  final charTemp = Uuid.parse("11223344-5566-7788-9900-aabbccddee01");
  final charPressao = Uuid.parse("11223344-5566-7788-9900-aabbccddee02");

  Future<bool> scanForEsp() async {
    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == "ESP32-BIA") {
        esp32 = device;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();

    return esp32 != null;
  }

  // ===== CONNECT =====
  Future<bool> connect() async {
    if (esp32 == null) return false;

    try {
      await ble.connectToDevice(id: esp32!.id).first;

      await _startNotificationListener();

      print("Conectado!");
      return true;
    } catch (e) {
      print("Erro conexão: $e");
      return false;
    }
  }

  // ===== NOTIFICATION HANDLER (igual a versão do Python) =====
  Future<void> _startNotificationListener() async {
    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service2,
      characteristicId: charControl,
    );

    ble.subscribeToCharacteristic(characteristic).listen((data) {
      final chunk = utf8.decode(data, allowMalformed: true);

      if (chunk.isEmpty) return;

      _rxBuffer += chunk;

      while (_rxBuffer.contains("@")) {
        final parts = _rxBuffer.split("@");
        final completed = parts.first;
        _rxBuffer = parts.sublist(1).join("@");

        final message = "$completed@";

        print("RX COMPLETO: $message");

        _messageController.add(message);
      }
    });
  }

  // Envio em chunks

  Future<void> sendMessage(String text) async {
    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service2,
      characteristicId: charControl,
    );

    final payload = utf8.encode(text);

    const chunkSize = 20;

    for (int i = 0; i < payload.length; i += chunkSize) {
      final chunk = payload.sublist(
        i,
        i + chunkSize > payload.length ? payload.length : i + chunkSize,
      );

      await ble.writeCharacteristicWithoutResponse(
        characteristic,
        value: chunk,
      );

      await Future.delayed(const Duration(milliseconds: 5));
    }

    print("TX: $text");
  }

  // ===== PARSER DE DADOS (igual _handle_completed_block) =====
  void listenIZData(void Function(String block) onBlock) {
    messageStream.listen((block) {
      onBlock(block);
    });
  }

  // ===== TEMPERATURA =====
  Stream<double> subscribeTemp() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service3,
      characteristicId: charTemp,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final tempStr = utf8.decode(data);
      return double.tryParse(tempStr) ?? 0.0;
    });
  }

  // ===== PRESSÃO =====
  Stream<int> subscribePressao() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service3,
      characteristicId: charPressao,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final pressaoStr = utf8.decode(data);
      return int.tryParse(pressaoStr) ?? 0;
    });
  }

  // Código do Fernando
  
  Future<int?> writeLed(int state) async {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service2,
      characteristicId: charLed,
    );

    try {
      final data = [state]; // 0 ou 1
      await ble.writeCharacteristicWithResponse(c, value: data);

      // O ESP32 ENVIA o estado atual do LED (ler confirmação)
      final status = await ble.readCharacteristic(c);
      return status.isNotEmpty ? status.first : null;
    } catch (e) {
      print("❌ Erro ao controlar LED: $e");
      return null;
    }
  }
}