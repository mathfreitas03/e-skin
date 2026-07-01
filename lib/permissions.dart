import 'package:permission_handler/permission_handler.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';

Future<bool> requestBlePermissions() async {
  final statusScan = await Permission.bluetoothScan.request();
  final statusConnect = await Permission.bluetoothConnect.request();
  final statusLocation = await Permission.location.request();

  return statusScan.isGranted &&
         statusConnect.isGranted &&
         statusLocation.isGranted;
}

Future<void> enableBluetooth() async {
  try {
    String result = await BluetoothEnable.enableBluetooth;
    if (result == "true") {
      print("Bluetooth ativado com sucesso pelo usuário.");
    } else {
      print("Usuário recusou ativar o Bluetooth.");
    }
  } catch (e) {
    print("Erro ao tentar ativar o Bluetooth: $e");
  }
}