import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';

class StockMutationPage extends ConsumerStatefulWidget {
  const StockMutationPage({super.key});
  @override ConsumerState<StockMutationPage> createState() => _StockMutationPageState();
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
              const SizedBox(height: 14),
              _buildAssetSummaryCard(isOwner, db),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['semua', 'masuk', 'keluar', 'opname'].map((tipe) {
                    final bool isSelected = _selectedFilterType == tipe;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tipe.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00A65A),
                        onSelected: (bool selected) { if (selected) setState(() => _selectedFilterType = tipe); },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<StockMutationData>>(
                  stream: db.select(db.stockMutations).watch(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada log mutasi.'));
                    final dataMutasi = snapshot.data!.where((m) => _selectedFilterType == 'semua' ? true : m.type.toLowerCase() == _selectedFilterType).toList();
                    return ListView.builder(
                      itemCount: dataMutasi.length,
                      itemBuilder: (ctx, idx) {
                        final item = dataMutasi[idx];
                        final bool isMasuk = item.type == 'masuk' || item.type == 'retur';
                        return Card(
                          color: Colors.white, elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? Colors.green : Colors.red),
                            title: Text('Ref: ${item.referenceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text('ID: ${item.productId}\nHPP saat itu: ${formatRupiah(item.hppSnapshot)}', style: const TextStyle(fontSize: 11)),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${isMasuk ? "+" : "-"}${item.quantity.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red)),
                              Text('Sisa: ${item.currentStockSnapshot.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ]),
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
      floatingActionButton: isOwner ? FloatingActionButton(backgroundColor: const Color(0xFF00A65A), onPressed: () => _showOpnameDialog(context, db), child: const Icon(Icons.add_box, color: Colors.white)) : null,
    );
  }

  Widget _buildAssetSummaryCard(bool isOwner, LocalDatabase db) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: StreamBuilder<List<ProductData>>(
        stream: db.select(db.products).watch(), // <-- pakai watch biar sinkron realtime dengan product_page
        builder: (ctx, snapshot) {
          double totalStokReady = 0; double totalNilaiAset = 0;
          if (snapshot.hasData) { for (var p in snapshot.data!) { totalStokReady += p.stock; totalNilaiAset += (p.stock * p.buyPrice); } }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('STATISTIK INVENTARIS READY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('Total Qty: ${totalStokReady.toStringAsFixed(0)} Pcs', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Divider(),
            if (!isOwner) const Text('NILAI MODAL ASET: [ RESTRICTED ]', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
            else Text('Total Valuasi Modal: ${formatRupiah(totalNilaiAset)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue)),
          ]);
        },
      ),
    );
  }

  void _showOpnameDialog(BuildContext context, LocalDatabase db) {
    final pIdController = TextEditingController(); final qtyController = TextEditingController(); final noteController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Stock Opname', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: pIdController, decoration: const InputDecoration(labelText: 'SKU / ID Produk')),
        TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Fisik Real')),
        TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Catatan')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
          if (pIdController.text.isNotEmpty && qtyController.text.isNotEmpty) {
            await db.catatMutasiStok(productId: pIdController.text, type: 'opname', qty: double.parse(qtyController.text), hargaBeliMasuk: 0, refNo: 'OPM-${DateTime.now().millisecondsSinceEpoch}', catatan: noteController.text);
            if (context.mounted) { Navigator.pop(ctx); }
          }
        }, child: const Text('Eksekusi', style: TextStyle(color: Colors.white)))
      ],
    ));
  }
}