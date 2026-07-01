import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'dart:convert';
import 'package:eprobe/models/connection_status.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;
  DiscoveredDevice? esp32;

  final _connectionController = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get connectionStream => _connectionController.stream;

  String _rxBuffer = "";

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  // Constantes idênticas ao código Python
  final serviceControl = Uuid.parse("6ebf5001-8765-4f67-8f4f-95f56ac3a1a0");
  
  // Alinhado com o Python: TX (...002) envia dados para o app (Notify)
  final charNotify = Uuid.parse("6ebf5002-8765-4f67-8f4f-95f56ac3a1a0"); 
  // Alinhado com o Python: RX (...003) recebe dados do app (Write)
  final charWrite  = Uuid.parse("6ebf5003-8765-4f67-8f4f-95f56ac3a1a0"); 

  // Tamanho do Chunk idêntico ao Python
  static const int bleWriteChunkSize = 180;

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
      // Endereço padrão definido no Python
      if (device.id == "DC:06:75:F6:57:5E") {
        esp32 = device;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();

    if (esp32 == null) {
      print("Não foi possível encontrar o dispositivo");
    }

    return esp32 != null;
  }

  // ===== CONNECT =====
  Future<bool> connect() async {
    if (esp32 == null) return false;

    try {
      _connectionSub = ble
          .connectToDevice(
            id: esp32!.id,
            connectionTimeout: const Duration(seconds: 10), 
          )
          .listen((update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connecting:
            print("Conectando...");
            _connectionController.add(BleConnectionStatus.connecting);
            break;

          case DeviceConnectionState.connected:
            print("Conectado!");
            _connectionController.add(BleConnectionStatus.connected);
            _rxBuffer = ""; 

            negotiateMTU(ble, esp32!.id);
            await _startNotificationListener();
            break;

          case DeviceConnectionState.disconnecting:
            print("Desconectando...");
            break;

          case DeviceConnectionState.disconnected:
            print("Desconectado!");
            _cleanupOnDisconnect();
            break;
        }
      });

      return true;
    } catch (e) {
      print("Erro conexão: $e");
      _cleanupOnDisconnect();
      return false;
    }
  }

  void negotiateMTU(FlutterReactiveBle connection, String deviceId, {int mtu = 512}) async {
    try {
      await connection.requestMtu(deviceId: deviceId, mtu: mtu);
      print("MTU negociado: $mtu");
    } catch (e) {
      print("Error negotiating MTU: $e");
    }
  }

  // ===== NOTIFICATION LISTENER =====
  Future<void> _startNotificationListener() async {
    await _notifySub?.cancel();

    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
      characteristicId: charNotify,
    );

    _notifySub = ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        // utf8.decode trata os bytes de texto vindos do Python perfeitamente
        final chunk = utf8.decode(data, allowMalformed: true);

        if (chunk.isEmpty) return;

        _rxBuffer += chunk;

        while (_rxBuffer.contains("@")) {
          final index = _rxBuffer.indexOf("@");
          final completed = _rxBuffer.substring(0, index);
          
          // Avança o buffer ignorando o "@" atual
          _rxBuffer = _rxBuffer.substring(index + 1);

          final block = "$completed@";
          _messageController.add(block);
        }
      },
      onError: (Object e) {
        print("Erro na notificação: $e");
      },
    );
  }

  // ===== ENVIO DE MENSAGENS =====
  Future<void> sendMessage(String text) async {
    if (esp32 == null || _connectionSub == null) return;

    final characteristic = QualifiedCharacteristic(
      deviceId: esp32!.id,
      serviceId: serviceControl,
      characteristicId: charWrite, 
    );

    final payload = utf8.encode(text);

    for (int i = 0; i < payload.length; i += bleWriteChunkSize) {
      final chunk = payload.sublist(
        i,
        i + bleWriteChunkSize > payload.length ? payload.length : i + bleWriteChunkSize,
      );

      // Alterado para WITHOUT response para bater com o Python (response=False)
      await ble.writeCharacteristicWithoutResponse(
        characteristic,
        value: chunk,
      );

      // Delay de 5ms idêntico ao Python para evitar estouro de buffer no ESP32
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  void _cleanupOnDisconnect() {
    _rxBuffer = "";
    _notifySub?.cancel();
    _notifySub = null;
    _connectionController.add(BleConnectionStatus.disconnected);
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    _cleanupOnDisconnect();
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
  }

  // ===== LISTENER =====
  void listenIZData(void Function(String block) onBlock) {
    messageStream.listen((block) => onBlock(block));
  }
}