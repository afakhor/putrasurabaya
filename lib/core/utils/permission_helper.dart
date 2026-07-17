import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();

  print('Android Bluetooth permission status: $statuses');
}
