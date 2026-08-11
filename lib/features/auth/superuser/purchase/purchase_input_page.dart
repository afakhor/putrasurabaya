import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class PurchaseInputPage extends ConsumerStatefulWidget {
  const PurchaseInputPage({super.key});
  @override
  ConsumerState<PurchaseInputPage> createState() => _PurchaseInputPageState();
}

class _PurchaseInputPageState extends ConsumerState<PurchaseInputPage> {
  final invoiceCtrl = TextEditingController();
  SupplierData? selectedSupplier;
  DateTime orderDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));
  final List<PurchaseItemsCompanion> items = [];
  final Map<String, ProductData> productCache = {};
  String bayarMode = 'TEMPO'; // CASH / TEMPO / DP
  final dpCtrl = TextEditingController(text: '0');
  File? notaFoto;
  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _pickFoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
    if (x != null) setState(() => notaFoto = File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final total = items.fold(0.0, (p, e) => p + (e.buyPrice.value * e.quantity.value));
    final dp = double.tryParse(dpCtrl.text) ?? 0;
    final sisa = bayarMode == 'CASH' ? 0.0 : bayarMode == 'DP' ? (total - dp).clamp(0, double.infinity).toDouble() : total;

    return Scaffold(
      appBar: AppBar(title: const Text('Kulak - Invoice Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        TextField(controller: invoiceCtrl, decoration: InputDecoration(labelText: 'No. Invoice Supplier * cek ganda', hintText: 'FAK-SUP-001', prefixIcon: const Icon(Icons.receipt), suffixIcon: IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickFoto), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        if (notaFoto != null) Padding(padding: const EdgeInsets.only(top: 8), child: Stack(children: [Image.file(notaFoto!, height: 120), Positioned(right: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => notaFoto = null)))])),
        const SizedBox(height: 10),
        // 2C: supplier autocomplete - FIX watchAllSuppliers tidak ada
        StreamBuilder<List<SupplierData>>(
          stream: db.select(db.suppliers).watch(),
          builder: (c, snap) {
            final all = snap.data ?? [];
            return Autocomplete<SupplierData>(
              displayStringForOption: (s) => s.name,
              optionsBuilder: (t) => t.text.isEmpty ? all : all.where((s) => s.name.toLowerCase().contains(t.text.toLowerCase())),
              onSelected: (s) => setState(() => selectedSupplier = s),
              fieldViewBuilder: (ctx, ctrl, focus, onSub) => TextField(controller: ctrl, focusNode: focus, decoration: InputDecoration(labelText: 'Supplier * Auto Complete', prefixIcon: const Icon(Icons.store), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ListTile(dense: true, title: const Text('Tgl Order', style: TextStyle(fontSize: 10)), subtitle: Text(DateFormat('dd MMM yyyy').format(orderDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDate: orderDate); if (d != null) setState(() => orderDate = d); })),
          Expanded(child: ListTile(dense: true, title: const Text('Jatuh Tempo', style: TextStyle(fontSize: 10)), subtitle: Text(DateFormat('dd MMM yyyy').format(dueDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: dueDate); if (d != null) setState(() => dueDate = d); })),
        ]),
        const Divider(),
        const Text('Mode Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Row(children: [ _chip('CASH','Lunas'), _chip('TEMPO','Tempo'), _chip('DP','DP') ]),
        if (bayarMode == 'DP') TextField(controller: dpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal DP'), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Item', style: TextStyle(fontWeight: FontWeight.bold)), ElevatedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Tambah'), onPressed: () => _addBarang(db))]),
        ...items.map((it) => Card(child: ListTile(dense: true, title: Text('${productCache[it.productId.value]?.name ?? it.productId.value} x${it.quantity.value}', style: const TextStyle(fontSize: 12)), subtitle: Text(fmt.format(it.buyPrice.value * it.quantity.value), style: const TextStyle(fontSize: 10)), trailing: IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => setState(() => items.remove(it)))))),
        const SizedBox(height: 12),
        Card(color: Colors.grey.shade100, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text(fmt.format(total), style: const TextStyle(fontWeight: FontWeight.bold))]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sisa Hutang ($bayarMode)'), Text(fmt.format(sisa), style: TextStyle(fontWeight: FontWeight.bold, color: sisa>0?Colors.red:Colors.green))]),
        ]))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800), icon: const Icon(Icons.save, color: Colors.white), label: Text('SIMPAN ${invoiceCtrl.text} -> ${sisa>0?'HUTANG':'LUNAS'}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), onPressed: items.isEmpty || selectedSupplier == null || invoiceCtrl.text.isEmpty ? null : () => _simpan(db, total, sisa))),
      ]),
    );
  }

  Widget _chip(String v, String l) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(l, style: const TextStyle(fontSize: 11)), selected: bayarMode == v, onSelected: (_) => setState(() => bayarMode = v)));

  void _addBarang(LocalDatabase db) {
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    ProductData? sel;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('Tambah Barang'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      StreamBuilder<List<ProductData>>(stream: db.productDao.watchActiveProducts(), builder: (cc, snap) {
        final all = snap.data ?? [];
        return Autocomplete<ProductData>(displayStringForOption: (p) => '${p.code} ${p.name}', optionsBuilder: (t) => t.text.isEmpty ? all.take(10) : all.where((p) => p.name.toLowerCase().contains(t.text.toLowerCase()) || (p.code??'').toLowerCase().contains(t.text.toLowerCase())).take(10), onSelected: (p) { setD(() { sel = p; priceCtrl.text = p.buyPrice.toStringAsFixed(0); }); }, fieldViewBuilder: (c2, ctrl, foc, onSub) => TextField(controller: ctrl, focusNode: foc, decoration: const InputDecoration(labelText: 'Ketik Kode/Nama', prefixIcon: Icon(Icons.search))));
      }),
      Row(children: [Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))), const SizedBox(width: 8), Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli')))]),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')), ElevatedButton(onPressed: () { if (sel==null) return; final q = double.tryParse(qtyCtrl.text)??0; final pr = double.tryParse(priceCtrl.text)??0; if (q<=0||pr<=0) return; setState(() { productCache[sel!.id]=sel!; items.add(PurchaseItemsCompanion.insert(id: '${DateTime.now().microsecondsSinceEpoch}_${sel!.id}', purchaseId: drift.Value(invoiceCtrl.text.trim()), productId: drift.Value(sel!.id), quantity: drift.Value(q), buyPrice: drift.Value(pr), conversionFactor: const drift.Value(1), subtotal: drift.Value(q*pr))); }); Navigator.pop(c); }, child: const Text('Tambah'))])));
  }

  Future<void> _simpan(LocalDatabase db, double total, double sisa) async {
    final id = invoiceCtrl.text.trim();
    final dup = await (db.select(db.purchases)..where((t) => t.invoiceNo.equals(id))).getSingleOrNull();
    if (dup != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice $id sudah ada - duplikat!'), backgroundColor: Colors.red));
      return;
    }
    try {
      // FIX: insert tanpa Value untuk required field
      await db.prosesPembelianPenyimpanan(
        dataPembelian: PurchasesCompanion.insert(
          id: id,
          invoiceNo: id,
          supplierId: selectedSupplier!.id,
          totalAmount: total,
          paidAmount: total - sisa,
          debtAmount: sisa,
          dueDate: drift.Value(dueDate),
          userId: 'owner-01',
          createdAt: drift.Value(orderDate),
          status: drift.Value('completed'),
        ),
        itemPembelian: items.map((e) => e.copyWith(purchaseId: drift.Value(id))).toList(),
      );
      if (bayarMode == 'DP' && (double.tryParse(dpCtrl.text)??0) >0) {
        final payable = await (db.select(db.payables)..where((t) => t.purchaseId.equals(id))).getSingleOrNull();
        if (payable != null) {
          await db.payablesDao.bayarAngsuranHutang(payableId: payable.id, nominalBayar: double.parse(dpCtrl.text), paymentMethod: 'DP CASH', notes: 'DP awal $id');
        }
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sukses $id'))); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error $e'), backgroundColor: Colors.red)); }
  }
}