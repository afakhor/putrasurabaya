import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ud_putra_kasir/core/services/printer_service.dart'; // Sesuaikan path

class StrukDispatcherService {
  
  // ===========================================================================
  // 1. 3-PLAY WHATSAPP (Kirim Gambar ke Owner, Sales, Customer)
  // ===========================================================================
  static Future<void> sendToWhatsApp({
    required Uint8List imageBytes,
    required List<String> phoneNumbers,
  }) async {
    // 1. Konversi bytes ke file yang bisa dishare
    final xFile = XFile.fromData(
      imageBytes,
      mimeType: 'image/png',
      name: 'struk_transaksi_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    // 2. Share ke list nomor
    // Catatan: Share Plus akan membuka dialog sharing sistem Android.
    // User memilih WhatsApp, lalu aplikasi akan meminta memilih chat/kontak.
    // Ini cara paling aman dan stabil di Android modern.
    await Share.shareXFiles(
      [xFile],
      text: "UD. PUTRA SURABAYA: Berikut adalah struk transaksi Anda.",
    );
  }

  // ===========================================================================
  // 2. 2-PLAY THERMAL (Cetak 2x Opsional)
  // ===========================================================================
  static Future<void> printThermal({
    required List<int> bytes,
    required PrinterService printerService,
    int copies = 2,
  }) async {
    final bool isConnected = await printerService.isConnected();
    
    if (!isConnected) {
      debugPrint("Printer tidak terhubung!");
      return;
    }

    for (int i = 0; i < copies; i++) {
      bool success = await printerService.printBytes(bytes);
      if (success) {
        debugPrint("Cetak copy ke-${i + 1} berhasil");
      }
      
      // Jeda 1 detik antar cetak agar buffer printer tidak penuh/hang
      if (i < copies - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
