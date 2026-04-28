import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  DiscoveredDevice? esp32;

  // Buffer para comunicação
  String _rxBuffer = "";

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  // UUID do serviço e característica principal de controle
  final serviceControl = Uuid.parse("87654321-4321-4321-4321-0987654321ba");
  final charControl = Uuid.parse("87654321-4321-4321-4321-0987654321bb");

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
      if (device.name == "Bioimpedance device") {
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

      // Inicia listener de notificações
      await _startNotificationListener();

      print("Conectado!");
      return true;
    } catch (e) {
      print("Erro conexão: $e");
      return false;
    }
  }

  // ===== NOTIFICATION LISTENER =====
  Future<void> _startNotificationListener() async {
    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
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

  // ===== ENVIO DE MENSAGENS =====
  Future<void> sendMessage(String text) async {
    if (esp32 == null) return;

    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
      characteristicId: charControl,
    );

    final payload = utf8.encode(text);
    const chunkSize = 20;

    for (int i = 0; i < payload.length; i += chunkSize) {
      final chunk = payload.sublist(
        i,
        i + chunkSize > payload.length ? payload.length : i + chunkSize,
      );

      await ble.writeCharacteristicWithoutResponse(characteristic, value: chunk);
      await Future.delayed(const Duration(milliseconds: 5));
    }

    print("Mensagem enviada: $text");
  }

  // ===== LISTENER PARA IZController =====
  void listenIZData(void Function(String block) onBlock) {
    messageStream.listen((block) => onBlock(block));
  }
}