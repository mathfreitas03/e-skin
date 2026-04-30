import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  DiscoveredDevice? esp32;

  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;

  String _rxBuffer = "";

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  // ✅ UUIDs (corrigidos conforme Python)
  final serviceControl = Uuid.parse("6ebf5001-8765-4f67-8f4f-95f56ac3a1a0");

  final charNotify = Uuid.parse("6ebf5002-8765-4f67-8f4f-95f56ac3a1a0"); // 📥 NOTIFY (RX)
  final charWrite  = Uuid.parse("6ebf5003-8765-4f67-8f4f-95f56ac3a1a0"); // 📤 WRITE (TX)

  // ===== SCAN =====
  Future<bool> scanForEsp() async {
    final status = await ble.statusStream.firstWhere(
      (s) => s == BleStatus.ready,
      orElse: () => BleStatus.unknown,
    );

    if (status != BleStatus.ready) {
      print("Bluetooth não está pronto: $status");
      return false;
    }

    print("Bluetooth pronto, iniciando scan...");

    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.id == "DC:06:75:F6:57:5E") {
        esp32 = device;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();

    if (esp32 == null) {
      print("Nao foi possivel encontrar o dispositivo");
    }

    return esp32 != null;
  }

  // ===== CONNECT =====
  Future<bool> connect() async {
    if (esp32 == null) return false;

    try {
      await ble.connectToDevice(id: esp32!.id).first;

      await _startNotificationListener();

      _connectionController.add(ConnectionStatus.connected);
      print("Conectado!");
      return true;
    } catch (e) {
      print("Erro conexão: $e");
      _connectionController.add(ConnectionStatus.disconnected);
      return false;
    }
  }

  // ===== NOTIFICATION LISTENER =====
  Future<void> _startNotificationListener() async {
    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
      characteristicId: charNotify, 
    );

    ble.subscribeToCharacteristic(characteristic).listen((data) {
      final chunk = utf8.decode(data, allowMalformed: true);

      if (chunk.isEmpty) return;

      _rxBuffer += chunk;
          
      while (_rxBuffer.contains("@")) {
        final index = _rxBuffer.indexOf("@");

        final completed = _rxBuffer.substring(0, index);
        _rxBuffer = _rxBuffer.substring(index + 1);

        final block = "$completed@";

        print("RX COMPLETO: $block");
        _messageController.add(block);
      }
    });
  }

  // ===== ENVIO DE MENSAGENS =====
  Future<void> sendMessage(String text) async {
    if (esp32 == null) return;

    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
      characteristicId: charWrite, // ✅ 5003 (igual Python)
    );

    final payload = utf8.encode(text);
    const chunkSize = 180;

    for (int i = 0; i < payload.length; i += chunkSize) {
      final chunk = payload.sublist(
        i,
        i + chunkSize > payload.length ? payload.length : i + chunkSize,
      );

      await ble.writeCharacteristicWithResponse(
        characteristic,
        value: chunk,
      );

      await Future.delayed(const Duration(milliseconds: 5));
    }

  }

  // ===== LISTENER PARA IZController =====
  void listenIZData(void Function(String block) onBlock) {
    messageStream.listen((block) => onBlock(block));
  }
}