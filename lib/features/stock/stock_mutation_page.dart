import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';

class StockMutationPage extends ConsumerStatefulWidget {
  const StockMutationPage({super.key});
  @override
  ConsumerState<StockMutationPage> createState() => _StockMutationPageState();
}

class _StockMutationPageState extends ConsumerState<StockMutationPage> {
  String _selectedFilterType = 'semua';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final user = ref.watch(currentUserProvider);
    final bool isOwner = user?['role'] == 'owner';

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KARTU MUTASI STOK & AUDIT LOG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007F00))),
              const Text('Sistem Pencatatan Riwayat Inventaris Gudang Terpusat', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 14),

              // 1. Ringkasan Nilai Aset Bergerak Terproteksi RBAC
              _buildAssetSummaryCard(isOwner, db),
              const SizedBox(height: 14),

              // 2. Filter Tipe Mutasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['semua', 'masuk', 'keluar', 'opname'].map((tipe) {
                  final bool isSelected = _selectedFilterType == tipe;
                  return ChoiceChip(
                    label: Text(tipe.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00A65A),
                    onSelected: (bool selected) {
                      if (selected) setState(() => _selectedFilterType = tipe);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 3. List Item Logger Kartu Stok dari SQLite Lokal (Realtime Stream Future)
              Expanded(
                child: FutureBuilder<List<StockMutationData>>(
                  future: db.select(db.stockMutations).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Belum ada log mutasi stock barang terekam.'));
                    }

                    final dataMutasi = snapshot.data!.where((m) {
                      if (_selectedFilterType == 'semua') return true;
                      return m.type.toLowerCase() == _selectedFilterType;
                    }).toList();

                    return ListView.builder(
                      itemCount: dataMutasi.length,
                      itemBuilder: (ctx, idx) {
                        final item = dataMutasi[idx];
                        final bool isMasuk = item.type == 'masuk' || item.type == 'retur';

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isMasuk ? Colors.green : Colors.red,
                            ),
                            title: Text('Ref: ${item.referenceNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Produk ID: ${item.productId}'),
                                Text('Waktu: ${item.date.toIso8601String().substring(0, 16)}'),
                                if (item.notes != null) Text('Memo: ${item.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isMasuk ? "+" : "-"}${item.quantity.toStringAsFixed(0)} Unit',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red, fontSize: 16),
                                ),
                                Text('Sisa: ${item.currentStockSnapshot.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Tombol Trigger Eksekusi Opname Fisik Khusus Owner
      floatingActionButton: isOwner 
        ? FloatingActionButton(
            backgroundColor: const Color(0xFF00A65A),
            child: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () {
              _showOpnameDialog(context, db);
            },
          )
        : null,
    );
  }

  // Widget: Ringkasan Nilai Aset Terkondisi Berdasarkan Role Pengguna (RBAC Aman)
  Widget _buildAssetSummaryCard(bool isOwner, LocalDatabase db) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: FutureBuilder<List<ProductData>>(
        future: db.getAllProducts(),
        builder: (ctx, snapshot) {
          double totalStokReady = 0;
          double totalNilaiAset = 0;

          if (snapshot.hasData) {
            for (var p in snapshot.data!) {
              totalStokReady += p.stock;
              totalNilaiAset += (p.stock * p.buyPrice); // Kalkulasi total nilai rupiah barang modal di gudang
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATISTIK INVENTARIS READY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Text('Total Qty Seluruh Barang: ${totalStokReady.toStringAsFixed(0)} Pcs', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Divider(),
              if (!isOwner)
                // Salesman dibatasi tidak bisa melihat total rupiah modal bisnis gudang
                const Text('NILAI MODAL ASET: [ RESTRICTED FOR SALESMAN ]', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
              else
                // Owner bisa memonitor total pergerakan rupiah aset
                Text('Total Nilai Valuasi Aset Modal: ${formatRupiah(totalNilaiAset)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue)),
            ],
          );
        },
      ),
    );
  }

  // Dialog Eksekusi Pencatatan Kartu Stok / Stock Opname Fisik
  void _showOpnameDialog(BuildContext context, LocalDatabase db) {
    final pIdController = TextEditingController();
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat Stock Opname Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pIdController, decoration: const InputDecoration(labelText: 'Masukkan Kode SKU / ID Produk')),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Fisik Real')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Catatan Dokumen Audit')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
            onPressed: () async {
              if (pIdController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                await db.catatMutasiStok(
                  productId: pIdController.text,
                  type: 'opname',
                  qty: double.parse(qtyController.text),
                  hargaBeliMasuk: 0,
                  refNo: 'OPM-${DateTime.now().millisecondsSinceEpoch}',
                  catatan: noteController.text,
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              }
            },
            child: const Text('Eksekusi Adjust Stok', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
