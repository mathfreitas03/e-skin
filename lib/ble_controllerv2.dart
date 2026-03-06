import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  DiscoveredDevice? esp32;

  // ==== UUIDs SERVIÇO 1 - Bioimpedancia ====
  final service1 = Uuid.parse("12345678-1234-1234-1234-1234567890ab");

  final charFreq = Uuid.parse("12345678-1234-1234-1234-1234567890ac");
  final charCap = Uuid.parse("12345678-1234-1234-1234-1234567890ad");
  final charRes = Uuid.parse("12345678-1234-1234-1234-1234567890ae");
  final charMod = Uuid.parse("12345678-1234-1234-1234-1234567890af");

  // ==== UUIDs SERVIÇO 2 - Controle (Novo) ====
  final service2 = Uuid.parse("87654321-4321-4321-4321-0987654321ba");
  final charControl = Uuid.parse("87654321-4321-4321-4321-0987654321bb");
  final charLed = Uuid.parse("87654321-4321-4321-4321-0987654321bc");

  // ==== UUIDs SERVIÇO 3 - Temperatura e Pressao (Novo) ====
  final service3 = Uuid.parse("11223344-5566-7788-9900-aabbccddeeff");
  final charTemp = Uuid.parse("11223344-5566-7788-9900-aabbccddee01"); // Corrigindo: use os UUIDs corretos do serviço 3
  final charPressao = Uuid.parse("11223344-5566-7788-9900-aabbccddee02"); // Corrigindo: use os UUIDs corretos do serviço 3

  // ===== SCAN =====
  Future<bool> scanForEsp() async {
    print("🔍 Scaneando...");

    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == "ESP32-BIA") {
        print("✅ Encontrado: ${device.id}");
        esp32 = device;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();

    return esp32 != null;
  }

  // ==== CONEXÃO ====
  Future<bool> connect() async {
    if (esp32 == null) return false;

    try {
      await ble.connectToDevice(id: esp32!.id).first;
      print("🔗 Conectado!");
      return true;
    } catch (e) {
      print("❌ Erro ao conectar: $e");
      return false;
    }
  }

  // Stream<List<double>> subscribeFreq() já está ok.
  Stream<List<double>> subscribeFreq() {
  final c = QualifiedCharacteristic(
    deviceId: esp32!.id,
    serviceId: service1,
    characteristicId: charFreq,
  );

  // 🕵️‍♂️ Passo 1: Imprimir antes de subscrever
  print("🟡 BLEController: Tentando subscrever a Frequência (${c.characteristicId})...");

  return ble.subscribeToCharacteristic(c).map((data) {
    // 🕵️‍♂️ Passo 2: Imprimir cada vez que o map é executado
    final csv = utf8.decode(data);
    print("🟢 BLEController: Dados CSV de Frequência decodificados: ${csv.substring(0, 15)}..."); 
    
    return csv.split(",").map((e) => double.tryParse(e) ?? 0).toList();
  });
}

  // Stream<List<double>> subscribeRes() já está ok.
  Stream<List<double>> subscribeRes() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service1,
      characteristicId: charRes,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final csv = utf8.decode(data);
      // 🔍 Local para o print (Dados crus em CSV)
      print("RESISTÊNCIA - CSV Recebido: $csv");
      return csv.split(",").map((e) => double.tryParse(e) ?? 0).toList();
    });
  }

  // Stream<List<double>> subscribeCap() já está ok.
  Stream<List<double>> subscribeCap() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service1,
      characteristicId: charCap,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final csv = utf8.decode(data);
      // 🔍 Local para o print (Dados crus em CSV)
      print("CAPACITÂNCIA - CSV Recebido: $csv");
      return csv.split(",").map((e) => double.tryParse(e) ?? 0).toList();
    });
  }

  // Novo: Assinatura para o Módulo
  Stream<List<double>> subscribeMod() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service1,
      characteristicId: charMod,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final csv = utf8.decode(data);
      return csv.split(",").map((e) => double.tryParse(e) ?? 0).toList();
    });
  }

  // ==== ASSINATURAS DO SERVIÇO 3 (Temperatura e Pressão) ====

  // Novo: Assinatura para Temperatura (String para double)
  Stream<double> subscribeTemp() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service3,
      characteristicId: charTemp,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final tempStr = utf8.decode(data); // Exemplo: "25.3"
      return double.tryParse(tempStr) ?? 0.0;
    });
  }

  // Novo: Assinatura para Pressão (String para double/int)
  Stream<int> subscribePressao() {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service3,
      characteristicId: charPressao,
    );

    return ble.subscribeToCharacteristic(c).map((data) {
      final pressaoStr = utf8.decode(data); // Exemplo: "1040"
      print("Pressao $pressaoStr");
      return int.tryParse(pressaoStr) ?? 0;
    });
  }

  // ==== FUNÇÕES DE ESCRITA DO SERVIÇO 2 (Controle) ====

  // Novo: Envia comando de controle (IZxF)
  Future<String?> writeControl(String command) async {
    final c = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: service2,
      characteristicId: charControl,
    );

    try {
      final data = utf8.encode(command);
      await ble.writeCharacteristicWithResponse(c, value: data);

      // O ESP32 ENVIA o comando recebido como confirmação
      final confirmation = await ble.readCharacteristic(c);
      return utf8.decode(confirmation);
    } catch (e) {
      print("❌ Erro ao enviar comando de controle: $e");
      return null;
    }
  }

  // Novo: Controla o LED
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
