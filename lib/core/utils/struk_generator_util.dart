import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Import model Anda
import 'package:ud_putra_kasir/features/pos/pos_state.dart'; 

// ===========================================================================
// 1. ENGINE: GENERATOR (Captures Widget as Image)
// ===========================================================================
class StrukGeneratorUtil {
  static final ScreenshotController _screenshotController = ScreenshotController();

  /// Mengubah Widget Struk menjadi Gambar (Uint8List)
  /// Cocok untuk dikirim ke WhatsApp agar tidak bisa diedit (Anti-Fraud)
  static Future<Uint8List?> generateStrukImage(Widget content, String qrData) async {
    return await _screenshotController.captureFromWidget(
      Material(
        color: Colors.white,
        child: Container(
          width: 300, // Lebar standar struk thermal
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Watermark
              const Text("UD. PUTRA SURABAYA", 
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
              const Divider(),
              
              content, // Isi konten (Template POS, Faktur, dll)
              
              const Divider(),
              // QR Code Keamanan
              QrImageView(data: qrData, version: QrVersions.auto, size: 80.0),
              const Text("SCAN UNTUK VERIFIKASI", style: TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
      delay: const Duration(milliseconds: 100), // Delay agar rendering selesai
    );
  }
}

// ===========================================================================
// 2. COMPONENTS: REUSABLE UI
// ===========================================================================
class StrukRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const StrukRow(this.label, this.value, {this.isBold = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        ],
      ),
    );
  }
}

// ===========================================================================
// 3. TEMPLATES: LAYOUTS (POS, FAKTUR, PENAGIHAN)
// ===========================================================================

/// Template 1: POS Kasir
class PosReceiptTemplate extends StatelessWidget {
  final PosCartState cart;
  const PosReceiptTemplate({required this.cart, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("STRUK KASIR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Divider(),
        ...cart.items.map((it) => StrukRow("${it.productName} x ${it.quantity}", "Rp ${it.subtotal}")),
        const Divider(),
        StrukRow("TOTAL:", "Rp ${cart.total}", isBold: true),
        if (cart.paymentMethod == 'cash') StrukRow("KEMBALI:", "Rp ${cart.change}"),
      ],
    );
  }
}

/// Template 2: Faktur Penjualan (UNPAID)
class FakturUnpaidTemplate extends StatelessWidget {
  final dynamic data; // Ganti 'dynamic' dengan model Invoice Anda
  const FakturUnpaidTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("FAKTUR PENJUALAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text("STATUS: UNPAID", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        const Divider(),
        // ... (Loop item faktur di sini)
        const Divider(),
        StrukRow("TOTAL TAGIHAN:", "Rp ${data.total}", isBold: true),
      ],
    );
  }
}
