import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

Future<void> requestBluetoothPermissions() async {
  if (kIsWeb) return;

  // Android 12+ pakai bluetoothConnect & bluetoothScan
  // Android di bawah 12 pakai bluetooth + location
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
  ].request();

  print('Bluetooth permission: $statuses');
}