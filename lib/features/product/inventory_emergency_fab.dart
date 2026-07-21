import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';

/// Floating Action Button Khusus Mode Darurat yang bisa dipasang mandiri
class InventoryEmergencyFab extends ConsumerWidget {
  const InventoryEmergencyFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      heroTag: 'inventory_emergency_btn',
      backgroundColor: Colors.red.shade900,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: const Text('DARURAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: () => InventoryEmergencyDialogs.showEmergencyMenuModal(context, ref),
    );
  }
}

/// Helper Dialog & Logika Aksi Darurat Inventaris
class InventoryEmergencyDialogs {
  /// Modal Pilihan Menu Darurat
  static void showEmergencyMenuModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: Colors.red.shade800),
                const SizedBox(width: 8),
                Text(
                  'Aksi Darurat Inventaris',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.gavel_rounded, color: Colors.red.shade700),
              title: const Text('Penyesuaian Stok Paksa (Opname)'),
              subtitle: const Text('Koreksi stok langsung untuk barang rusak/hilang'),
              onTap: () {
                Navigator.pop(ctx);
                showEmergencyStockDialog(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on, color: Colors.amber.shade900),
              title: const Text('Ubah Harga Jual Darurat'),
              subtitle: const Text('Timpa harga jual umum secara kilat'),
              onTap: () {
                Navigator.pop(ctx);
                showQuickPriceDialog(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.backup_rounded, color: Colors.purple.shade700),
              title: const Text('Ekspor JSON Cadangan Darurat'),
              subtitle: const Text('Salin mentah data katalog jika sistem kendala'),
              onTap: () {
                Navigator.pop(ctx);
                performEmergencyBackup(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Dialog Koreksi Stok Paksa
  static void showEmergencyStockDialog(BuildContext context, WidgetRef ref) {
    final skuCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String alasan = 'Rusak';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade800),
            const SizedBox(width: 8),
            const Text('Koreksi Stok Fisik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(
                labelText: 'Scan Barcode / Input SKU',
                prefixIcon: Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Jumlah Penyesuaian (Contoh: -5 atau 10)',
                prefixIcon: Icon(Icons.exposure),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: alasan,
              items: ['Rusak', 'Hilang / Pencurian', 'Salah Input', 'Expired']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => alasan = v ?? 'Rusak',
              decoration: const InputDecoration(
                labelText: 'Alasan Penyesuaian',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              final sku = skuCtrl.text.trim();
              final qtyChange = double.tryParse(qtyCtrl.text.trim()) ?? 0;

              if (sku.isNotEmpty && qtyChange != 0) {
                final db = ref.read(localDatabaseProvider);
                
                // Eksekusi update langsung ke database SQLite
                final product = await (db.select(db.products)..where((t) => t.id.equals(sku))).getSingleOrNull();
                
                if (product != null) {
                  final newStock = product.stock + qtyChange;
                  await (db.update(db.products)..where((t) => t.id.equals(sku)))
                      .write(ProductsCompanion(stock: Value(newStock)));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Stok ${product.name} diperbarui menjadi $newStock Pcs ($alasan)'),
                      backgroundColor: Colors.red.shade800,
                    ));
                    Navigator.pop(ctx);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SKU tidak ditemukan di database!')),
                    );
                  }
                }
              }
            },
            child: const Text('EKSEKUSI STOK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  /// 2. Dialog Timpa Harga Kilat
  static void showQuickPriceDialog(BuildContext context, WidgetRef ref) {
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Harga Jual Kilat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(labelText: 'Kode Barang / SKU', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga Jual Baru (Rp)', prefixText: 'Rp ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
            onPressed: () async {
              final sku = skuCtrl.text.trim();
              final newPrice = double.tryParse(priceCtrl.text.trim()) ?? 0;

              if (sku.isNotEmpty && newPrice > 0) {
                final db = ref.read(localDatabaseProvider);
                final updatedRows = await (db.update(db.products)..where((t) => t.id.equals(sku)))
                    .write(ProductsCompanion(sellPriceGeneral: Value(newPrice)));

                if (context.mounted) {
                  if (updatedRows > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Harga SKU $sku berhasil diubah menjadi Rp $newPrice'),
                      backgroundColor: Colors.amber.shade900,
                    ));
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SKU Produk tidak terdaftar.')),
                    );
                  }
                }
              }
            },
            child: const Text('UPDATE HARGA', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  /// 3. Ekspor Data Cadangan JSON Darurat
  static Future<void> performEmergencyBackup(BuildContext context, WidgetRef ref) async {
    final db = ref.read(localDatabaseProvider);
    final allProducts = await db.select(db.products).get();

    List<Map<String, dynamic>> dumpList = allProducts.map((p) => {
      'id': p.id,
      'name': p.name,
      'barcode': p.barcode,
      'buyPrice': p.buyPrice,
      'sellPriceGeneral': p.sellPriceGeneral,
      'stock': p.stock,
      'categoryId': p.categoryId,
    }).toList();

    String rawJsonDump = const JsonEncoder.withIndent('  ').convert(dumpList);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.purple),
              SizedBox(width: 8),
              Text('Ekspor JSON Darurat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data katalog mentah berhasil di-generate. Anda dapat menyalin teks ini:', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    rawJsonDump,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('TUTUP')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teks data cadangan disiapkan untuk disalin.')),
                );
              },
              child: const Text('SALIN TEKS', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }
}
