import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class FoundBleDevice {
  final DiscoveredDevice discoveredDevice;
  // Checagem de validade baseada em nome do dispositivo.
  // Sugiro alterar o firmware da sonda para permitir validação durante o handshake
  late bool isValid;

  FoundBleDevice(this.discoveredDevice);
}