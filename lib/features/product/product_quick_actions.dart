import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/local_database.dart';
import 'product_form_dialogs.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_form_dialogs.dart';

class ProductQuickActions {
  /// Menampilkan Bottom Sheet Pilihan Pintasan Cepat
  static void showQuickActionsMenu({
    required BuildContext context,
    required VoidCallback onScanBarcode,
    required VoidCallback onQuickStockAdjustment,
    required VoidCallback onPrintThermalLabel,
    required Function(String categoryName) onCategoryAdded,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ProductQuickActionsSheet(
        onScanBarcode: onScanBarcode,
        onQuickStockAdjustment: onQuickStockAdjustment,
        onPrintThermalLabel: onPrintThermalLabel,
        onCategoryAdded: onCategoryAdded,
      ),
    );
  }
}

class ProductQuickActionsSheet extends ConsumerWidget {
  final VoidCallback onScanBarcode;
  final VoidCallback onQuickStockAdjustment;
  final VoidCallback onPrintThermalLabel;
  final Function(String categoryName) onCategoryAdded;

  const ProductQuickActionsSheet({
    super.key,
    required this.onScanBarcode,
    required this.onQuickStockAdjustment,
    required this.onPrintThermalLabel,
    required this.onCategoryAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF007F00)),
              const SizedBox(width: 8),
              const Text(
                'Menu Pintasan Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // LIST OPSI PINTASAN
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFF00A65A)),
            ),
            title: const Text('Scan Barcode / Cari SKU', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Pindai fisik produk untuk cek detail atau stok'),
            onTap: () {
              Navigator.pop(context);
              onScanBarcode();
            },
          ),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.edit_note, color: Colors.blue),
            ),
            title: const Text('Koreksi / Penyesuaian Stok Cepat', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Input stok masuk/keluar tanpa buka Form Master'),
            onTap: () {
              Navigator.pop(context);
              onQuickStockAdjustment();
            },
          ),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade50,
              child: const Icon(Icons.print, color: Colors.amber),
            ),
            title: const Text('Cetak Label Barcode Thermal', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Kirim antrean cetak ke printer Bluetooth/USB'),
            onTap: () {
              Navigator.pop(context);
              onPrintThermalLabel();
            },
          ),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade50,
              child: const Icon(Icons.category, color: Colors.purple),
            ),
            title: const Text('Tambah Kategori Baru', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Buat grup klasifikasi produk baru'),
            onTap: () async {
              Navigator.pop(context);
              String? newCat = await ProductFormDialogs.showQuickTextDialog(
                context: context,
                title: 'Tambah Kategori Baru',
                labelField: 'Nama Kategori',
              );
              if (newCat != null && newCat.isNotEmpty) {
                onCategoryAdded(newCat);
              }
            },
          ),
        ],
      ),
    );
  }
}
