import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

Future<void> requestBluetoothPermissions() async {
  if (kIsWeb) return;

  // Minta izin secara bertahap atau kolektif yang aman untuk Android baru & lama
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
  ].request();

  print('Bluetooth permission status: $statuses');
}
