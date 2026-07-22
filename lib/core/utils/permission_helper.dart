import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestBluetoothPermissions() async {
    try {
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    } catch (e) {
      return false;
    }
  }
}

Future<void> requestBluetoothPermissions() => PermissionHelper.requestBluetoothPermissions();