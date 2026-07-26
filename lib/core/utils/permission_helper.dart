import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Helper untuk manajemen izin (permission) Bluetooth
class PermissionHelper {
  static Future<bool> requestBluetoothPermissions() async {
    try {
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse, // Diperlukan untuk scan Bluetooth pada Android 11 ke bawah
      ].request();

      return statuses.values.every((s) => s.isGranted);
    } catch (e) {
      return false;
    }
  }
}

/// Wrapper fungsi global untuk kemudahan pemanggilan mandiri
Future<bool> requestBluetoothPermissions() =>
    PermissionHelper.requestBluetoothPermissions();

/// Service Pengelola Printer Bluetooth Thermal ESC/POS
class PrinterService {
  /// Cek dan minta izin Bluetooth
  Future<bool> checkAndRequestPermissions() async {
    return await PermissionHelper.requestBluetoothPermissions();
  }

  /// Scan perangkat Bluetooth yang sudah ter-pairing (bonded)
  Future<List<BluetoothInfo>> getPairedDevices() async {
    // 1. Minta izin Bluetooth via permission_handler
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return [];

    // 2. Verifikasi status izin pada library printer
    final bool isPermissionGranted =
        await PrintBluetoothThermal.isPermissionGranted;
    if (!isPermissionGranted) return [];

    // 3. Ambil daftar perangkat Bluetooth
    return await PrintBluetoothThermal.pairedBluetoothBytes;
  }

  /// Hubungkan ke printer berdasarkan Mac Address
  Future<bool> connect(String macAddress) async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return false;

    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  /// Putuskan koneksi dari printer
  Future<bool> disconnect() async {
    return await PrintBluetoothThermal.disconnect;
  }

  /// Cek status koneksi printer saat ini
  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Kirim bytes ESC/POS ke printer thermal
  Future<bool> printBytes(List<int> bytes) async {
    final bool connected = await isConnected();
    if (!connected) return false;

    return await PrintBluetoothThermal.writeBytes(bytes);
  }
}

/// Provider Riverpod untuk PrinterService
final printerServiceProvider =
    Provider<PrinterService>((ref) => PrinterService());
