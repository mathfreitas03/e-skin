import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBlePermissions() async {
  final statusScan = await Permission.bluetoothScan.request();
  final statusConnect = await Permission.bluetoothConnect.request();
  final statusLocation = await Permission.location.request();

  return statusScan.isGranted &&
         statusConnect.isGranted &&
         statusLocation.isGranted;
}
