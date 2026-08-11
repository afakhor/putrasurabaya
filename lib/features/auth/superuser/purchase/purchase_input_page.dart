import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class PurchaseInputPage extends ConsumerStatefulWidget {
  const PurchaseInputPage({super.key});
  @override
  ConsumerState<PurchaseInputPage> createState() => _PurchaseInputPageState();
}

class _PurchaseInputPageState extends ConsumerState<PurchaseInputPage> {
  final invoiceCtrl = TextEditingController();
  final keywordCtrl = TextEditingController(); // untuk auto index
  SupplierData? selectedSupplier;
  DateTime orderDate = DateTime.now();
  DateTime? dueDate;
  final List<PurchaseItemsCompanion> items = [];
  final Map<String, ProductData> productCache = {};
  
  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final fmtDate = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    invoiceCtrl.dispose();
    keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kulak Barang - Supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // === HEADER INVOICE SUPPLIER + KEYWORD AUTO INDEX ===
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                // Keyword pencarian faktur (auto complete)
                TextField(
                  controller: keywordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cari Faktur / Supplier / Tanggal (Auto Index)',
                    hintText: 'Ketik INV-xxx, Nama Supplier, atau 12 Agu',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => keywordCtrl.clear()),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Invoice Asli dari Supplier
                TextField(
                  controller: invoiceCtrl,
                  decoration: InputDecoration(
                    labelText: 'No. Invoice Supplier * WAJIB',
                    hintText: 'Contoh: FAK-SUP-2024-001',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                // Autocomplete Supplier
                StreamBuilder<List<SupplierData>>(
                  stream: db.supplierDao.watchAllSuppliers(),
                  builder: (c, snap) {
                    final allSup = snap.data ?? [];
                    // filter by keyword auto index
                    final filtered = keywordCtrl.text.isEmpty ? allSup : allSup.where((s) => 
                      s.name.toLowerCase().contains(keywordCtrl.text.toLowerCase()) || 
                      s.id.toLowerCase().contains(keywordCtrl.text.toLowerCase())
                    ).toList();
                    
                    return Autocomplete<SupplierData>(
                      displayStringForOption: (s) => s.name,
                      optionsBuilder: (text) {
                        if (text.text.isEmpty) return filtered;
                        return filtered.where((s) => s.name.toLowerCase().contains(text.text.toLowerCase()));
                      },
                      onSelected: (s) => setState(() => selectedSupplier = s),
                      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                        if (selectedSupplier != null && ctrl.text.isEmpty) {
                          ctrl.text = selectedSupplier!.name;
                        }
                        return TextField(
                          controller: ctrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            labelText: 'Supplier *',
                            prefixIcon: const Icon(Icons.store),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      optionsViewBuilder: (ctx, onSel, opts) {
                        return Align(alignment: Alignment.topLeft, child: Material(elevation: 4, child: SizedBox(width: 300, child: ListView.builder(shrinkWrap: true, itemCount: opts.length, itemBuilder: (_, i) {
                          final s = opts.elementAt(i);
                          return ListTile(title: Text(s.name), subtitle: Text(s.id), onTap: () => onSel(s));
                        }))));
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ListTile(dense: true, title: const Text('Tgl Order', style: TextStyle(fontSize: 11)), subtitle: Text(fmtDate.format(orderDate), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime(2030), initialDate: orderDate);
                    if (d != null) setState(() => orderDate = d);
                  })),
                  Expanded(child: ListTile(dense: true, title: const Text('Jatuh Tempo', style: TextStyle(fontSize: 11)), subtitle: Text(dueDate == null ? 'Pilih' : fmtDate.format(dueDate!), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now().add(const Duration(days: 30)));
                    if (d != null) setState(() => dueDate = d);
                  })),
                ]),
              ]),
            ),
          ),

          const SizedBox(height: 12),
          // === LIST BARANG ===
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Item Barang', style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Tambah Barang'), onPressed: () => _showAddBarangDialog(db)),
          ]),
          const SizedBox(height: 8),
          if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada barang, tambah dulu')))),
          ...items.map((it) {
            final prod = productCache[it.productId.value];
            return Card(margin: const EdgeInsets.only(bottom: 4), child: ListTile(dense: true, title: Text('${prod?.name ?? it.productId.value} x${it.quantity.value}'), subtitle: Text('Beli ${fmt.format(it.buyPrice.value)} | Sub ${fmt.format(it.buyPrice.value * it.quantity.value)}'), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => setState(() => items.remove(it)))));
          }),

          const SizedBox(height: 16),
          // === TOTAL ===
          Card(color: Colors.grey.shade100, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kulak:'), Text(fmt.format(items.fold(0.0, (p, e) => p + (e.buyPrice.value * e.quantity.value))), style: const TextStyle(fontWeight: FontWeight.bold))]),
          ]))),

          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, padding: const EdgeInsets.all(14)), icon: const Icon(Icons.save, color: Colors.white), label: const Text('SIMPAN KULAK -> AUTO MASUK HUTANG SUPPLIER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), onPressed: items.isEmpty || selectedSupplier == null || invoiceCtrl.text.isEmpty ? null : () => _simpanKulak(db))),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAddBarangDialog(LocalDatabase db) {
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    ProductData? selectedProd;

    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('Tambah Barang Kulak'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // Auto Complete Produk
        StreamBuilder<List<ProductData>>(stream: db.productDao.watchActiveProducts(), builder: (cc, snap) {
          final allProd = snap.data ?? [];
          return Autocomplete<ProductData>(
            displayStringForOption: (p) => '${p.code} - ${p.name}',
            optionsBuilder: (txt) {
              if (txt.text.isEmpty) return allProd.take(10);
              final k = txt.text.toLowerCase();
              return allProd.where((p) => p.name.toLowerCase().contains(k) || (p.code ?? '').toLowerCase().contains(k)).take(10);
            },
            onSelected: (p) { setD(() { selectedProd = p; priceCtrl.text = p.buyPrice.toStringAsFixed(0); }); },
            fieldViewBuilder: (c2, ctrl, focus, onSub) => TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: 'Ketik Nama / Kode Barang', prefixIcon: Icon(Icons.search))),
          );
        }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli'))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          if (selectedProd == null) return;
          final qty = double.tryParse(qtyCtrl.text) ?? 0;
          final price = double.tryParse(priceCtrl.text) ?? 0;
          if (qty <=0 || price <=0) return;
          setState(() {
            productCache[selectedProd!.id] = selectedProd!;
            items.add(PurchaseItemsCompanion.insert(productId: drift.Value(selectedProd!.id), quantity: drift.Value(qty), buyPrice: drift.Value(price), conversionFactor: const drift.Value(1), subtotal: drift.Value(qty * price)));
          });
          Navigator.pop(c);
        }, child: const Text('Tambah')),
      ],
    )));
  }

  Future<void> _simpanKulak(LocalDatabase db) async {
    final total = items.fold(0.0, (p, e) => p + (e.buyPrice.value * e.quantity.value));
    final id = invoiceCtrl.text.trim(); // pakai invoice supplier sebagai ID
    
    try {
      // RULE EMAS: 1 Faktur = 1 Payable = 1 Mutasi
      await db.prosesPembelianPenyimpanan(
        dataPembelian: PurchasesCompanion.insert(
          id: id,
          invoiceNo: drift.Value(id),
          supplierId: drift.Value(selectedSupplier!.id),
          totalAmount: drift.Value(total),
          paidAmount: const drift.Value(0), // full hutang dulu
          debtAmount: drift.Value(total),
          dueDate: drift.Value(dueDate ?? DateTime.now().add(const Duration(days: 30))),
          userId: drift.Value('owner-01'),
          createdAt: drift.Value(orderDate),
          status: const drift.Value('completed'),
        ),
        itemPembelian: items.map((e) => e.copyWith(purchaseId: drift.Value(id))).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kulak $id berhasil! Stok nambah + Hutang masuk Daftar Hutang Supplier Rp ${fmt.format(total)}')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}