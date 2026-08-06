import 'package:eprobe/models/found_ble_device.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'dart:convert';
import 'package:eprobe/models/connection_status.dart';

class BleController {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;
  
  // Guarda o ID do dispositivo atualmente conectado ou em processo de conexão
  String? _connectedDeviceId;

  final _connectionController = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get connectionStream => _connectionController.stream;

  String _rxBuffer = "";

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  final serviceControl = Uuid.parse("6ebf5001-8765-4f67-8f4f-95f56ac3a1a0");
  final charNotify = Uuid.parse("6ebf5002-8765-4f67-8f4f-95f56ac3a1a0"); 
  final charWrite   = Uuid.parse("6ebf5003-8765-4f67-8f4f-95f56ac3a1a0"); 
  static const int bleWriteChunkSize = 180;

  // ===== SCAN =====
  Future<List<FoundBleDevice>> scanForDevices() async {
    final status = await ble.statusStream.firstWhere(
      (s) => s == BleStatus.ready,
      orElse: () => BleStatus.unknown,
    );

    if (status != BleStatus.ready) {
      // print("[DEBUG SCAN] Bluetooth não está pronto: $status");
      return [];
    }

    // print("[DEBUG SCAN] Bluetooth pronto, iniciando scan...");
    
    final Map<String, FoundBleDevice> foundDevices = {};

    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.name.isNotEmpty) {
        FoundBleDevice newDevice = FoundBleDevice(device);
        newDevice.isValid = device.name.contains("Bioimpedance device");
        foundDevices[device.id] = newDevice;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();    
    return foundDevices.values.toList();
  }

  // Mantido caso reversão seja necessária. No momento, não é mais utilizado

  Future<bool> scanForEsp() async {
    final status = await ble.statusStream.firstWhere(
      (s) => s == BleStatus.ready,
      orElse: () => BleStatus.unknown,
    );

    if (status != BleStatus.ready) {
      debugPrint("Bluetooth não está pronto: $status");
      return false;
    }

    debugPrint("Bluetooth pronto, iniciando scan...");
    bool found = false;

    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.id == "DC:06:75:F6:57:5E") {
        found = true;
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();

    return found;
  }

// Variável de controle para evitar cliques duplos/chamadas concorrentes
  bool _isConnecting = false;

  Future<bool> connect(FoundBleDevice device) async {
    if (_isConnecting) {
      debugPrint("Já existe uma tentativa de conexão em andamento...");
      return false;
    }

    if(!device.isValid) {
      return false;
    }

    try {
      _isConnecting = true;
      _connectedDeviceId = device.discoveredDevice.id;

      // 2. Garante o cancelamento de qualquer inscrição/conexão antiga ativa
      await _connectionSub?.cancel();
      _connectionSub = null;

      _connectionSub = ble
          .connectToDevice(
            id: device.discoveredDevice.id,
            connectionTimeout: const Duration(seconds: 10), 
          )
          .listen((update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connecting:
            debugPrint("Conectando a ${device.discoveredDevice.name}...");
            _connectionController.add(BleConnectionStatus.connecting);
            break;

          case DeviceConnectionState.connected:
            debugPrint("Conectado com sucesso!");
            _isConnecting = false; // Libera o estado
            _connectionController.add(BleConnectionStatus.connected);
            _rxBuffer = ""; 

            negotiateMTU(ble, device.discoveredDevice.id);
            await _startNotificationListener(device.discoveredDevice.id); 
            break;

          case DeviceConnectionState.disconnecting:
            debugPrint("Desconectando...");
            break;

          case DeviceConnectionState.disconnected:
            debugPrint("Desconectado!");
            _isConnecting = false; // Libera o estado
            _cleanupOnDisconnect();
            break;
        }
      }, onError: (Object error) {
        debugPrint("Erro no stream de conexão: $error");
        _isConnecting = false;
        _cleanupOnDisconnect();
      });

      return true;
    } catch (e) {
      debugPrint("Erro inicial de conexão: $e");
      _isConnecting = false;
      _cleanupOnDisconnect();
      return false;
    }
  }

  void negotiateMTU(FlutterReactiveBle connection, String deviceId, {int mtu = 512}) async {
    try {
      await connection.requestMtu(deviceId: deviceId, mtu: mtu);
      debugPrint("MTU negociado: $mtu");
    } catch (e) {
      debugPrint("Error negotiating MTU: $e");
    }
  }

  // ===== NOTIFICATION LISTENER =====
  // CORREÇÃO: Recebe dinamicamente o ID correto do dispositivo conectado
  Future<void> _startNotificationListener(String deviceId) async {
    await _notifySub?.cancel();

    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId, // CORRIGIDO: Usa o deviceId dinâmico e remove o "esp32!"
      serviceId: serviceControl,
      characteristicId: charNotify,
    );

    _notifySub = ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        final chunk = utf8.decode(data, allowMalformed: true);

        if (chunk.isEmpty) return;

        _rxBuffer += chunk;

        while (_rxBuffer.contains("@")) {
          final index = _rxBuffer.indexOf("@");
          final completed = _rxBuffer.substring(0, index);
          
          _rxBuffer = _rxBuffer.substring(index + 1);

          final block = "$completed@";
          _messageController.add(block);
        }
      },
      onError: (Object e) {
        debugPrint("Erro na notificação: $e");
      },
    );
  }

  // ===== ENVIO DE MENSAGENS =====
  Future<void> sendMessage(String text) async {
    // CORREÇÃO: Valida contra a nova propriedade de ID conectado
    if (_connectedDeviceId == null || _connectionSub == null) return;

    final characteristic = QualifiedCharacteristic(
      deviceId: _connectedDeviceId!, // CORRIGIDO: Usa o ID dinâmico
      serviceId: serviceControl,
      characteristicId: charWrite, 
    );

    final payload = utf8.encode(text);

    for (int i = 0; i < payload.length; i += bleWriteChunkSize) {
      final chunk = payload.sublist(
        i,
        i + bleWriteChunkSize > payload.length ? payload.length : i + bleWriteChunkSize,
      );

      await ble.writeCharacteristicWithoutResponse(
        characteristic,
        value: chunk,
      );

      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  void _cleanupOnDisconnect() {
    _rxBuffer = "";
    _connectedDeviceId = null; // Reseta o ID salvo
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