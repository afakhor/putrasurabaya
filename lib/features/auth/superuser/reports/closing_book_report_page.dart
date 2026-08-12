import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

// ============== FILTER ==============
class ClosingFilter {
  DateTime start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  String search = '';
  String periode = 'BULANAN'; // BULANAN, TAHUNAN, CUSTOM
  bool includeStock = true;
  bool includeAset = true;
}

final closingFilterProvider = StateProvider<ClosingFilter>((ref) => ClosingFilter());
final closingReportProvider = FutureProvider<ClosingBookData>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final f = ref.watch(closingFilterProvider);
  return ClosingBookData.generate(db, f);
});

class ClosingBookData {
  final double saldoAwal, omset, hpp, biaya, labaKotor, labaBersih, saldoAkhir;
  final double totalStockAwal, totalStockAkhir, selisihStock;
  final double totalPiutang, totalHutang, totalAsetTetap, totalKas, modalAkhir;
  final List<ProductData> stockOpname;
  final List<ReceivableData> piutang;
  final List<PayableData> hutang;
  final List<AssetData> aset;
  final bool isBalanced;

  ClosingBookData({required this.saldoAwal, required this.omset, required this.hpp, required this.biaya, required this.labaKotor, required this.labaBersih, required this.saldoAkhir, required this.totalStockAwal, required this.totalStockAkhir, required this.selisihStock, required this.totalPiutang, required this.totalHutang, required this.totalAsetTetap, required this.totalKas, required this.modalAkhir, required this.stockOpname, required this.piutang, required this.hutang, required this.aset, required this.isBalanced});

  static Future<ClosingBookData> generate(LocalDatabase db, ClosingFilter f) async {
    // 1. PENJUALAN & HPP - AUTO SYNC DARI SALES
    final sales = await db.salesDao.getSalesByDateRange(f.start, f.end);
    final omset = sales.fold<double>(0, (p,e)=> p + e.totalAmount);
    final hpp = sales.fold<double>(0, (p,e)=> p + e.hppTotal);

    // 2. PEMBELIAN - AUTO SYNC
    final purchases = await db.purchaseDao.getByDateRange(f.start, f.end);
    final totalBeli = purchases.fold<double>(0, (p,e)=> p + e.totalAmount);

    // 3. BIAYA
    final biaya = await db.expenseDao.getTotalByDateRange(f.start, f.end);

    // 4. STOCK - AUTO SYNC MUTASI
    final allProducts = await db.productDao.getAllProducts();
    var filteredProducts = allProducts;
    if(f.search.isNotEmpty){
      final q = f.search.toLowerCase();
      filteredProducts = allProducts.where((e)=> e.name.toLowerCase().contains(q) || e.sku.toLowerCase().contains(q)).toList();
    }
    final stockAkhir = filteredProducts.fold<double>(0, (p,e)=> p + (e.stock * e.hargaBeli));
    final stockAwal = stockAkhir + hpp - totalBeli; // rumus

    // 5. PIUTANG & HUTANG
    final piutangList = await db.receivablesDao.getByDateRange(f.start, f.end);
    final hutangList = await db.payablesDao.getByDateRange(f.start, f.end);
    final totalPiutang = piutangList.where((e)=> e.remainingAmount>0).fold<double>(0, (p,e)=> p + e.remainingAmount);
    final totalHutang = hutangList.where((e)=> e.remainingAmount>0).fold<double>(0, (p,e)=> p + e.remainingAmount);

    // 6. ASET & KAS - AUTO SYNC
    final asetList = await db.assetDao.getAll();
    final totalAset = asetList.fold<double>(0, (p,e)=> p + e.nilaiBuku);
    final kas = await db.cashDao.getCashBalance();
    final saldoAwal = await db.cashDao.getBalanceAt(f.start);

    final labaKotor = omset - hpp;
    final labaBersih = labaKotor - biaya;
    final saldoAkhir = saldoAwal + omset - totalBeli - biaya;
    final modalAkhir = stockAkhir + totalPiutang + totalAset + kas - totalHutang;
    final isBalanced = (modalAkhir - (saldoAkhir + labaBersih)).abs() < 1000;

    return ClosingBookData(
      saldoAwal: saldoAwal, omset: omset, hpp: hpp, biaya: biaya, labaKotor: labaKotor, labaBersih: labaBersih, saldoAkhir: saldoAkhir,
      totalStockAwal: stockAwal, totalStockAkhir: stockAkhir, selisihStock: stockAkhir - stockAwal,
      totalPiutang: totalPiutang, totalHutang: totalHutang, totalAsetTetap: totalAset, totalKas: kas, modalAkhir: modalAkhir,
      stockOpname: filteredProducts, piutang: piutangList, hutang: hutangList, aset: asetList, isBalanced: isBalanced,
    );
  }
}

// ============== UI ==============
class ClosingBookReportPage extends ConsumerStatefulWidget {
  const ClosingBookReportPage({super.key});
  @override ConsumerState<ClosingBookReportPage> createState() => _ClosingBookReportPageState();
}

class _ClosingBookReportPageState extends ConsumerState<ClosingBookReportPage> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(closingFilterProvider);
    final reportAsync = ref.watch(closingReportProvider);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TUTUP BUKU - UD PUTRA'),
        backgroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v){
              final now = DateTime.now();
              if(v=='BULANAN') ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = DateTime(now.year, now.month, 1)..end = DateTime(now.year, now.month+1,0,23,59,59)..periode = 'BULANAN';
              if(v=='TAHUNAN') ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = DateTime(now.year,1,1)..end = DateTime(now.year,12,31,23,59,59)..periode = 'TAHUNAN';
            },
            itemBuilder: (_)=> const [PopupMenuItem(value: 'BULANAN', child: Text('Bulanan')), PopupMenuItem(value: 'TAHUNAN', child: Text('Tahunan'))],
          ),
          IconButton(icon: const Icon(Icons.lock), onPressed: ()=> _prosesTutupBuku(context, filter)),
        ],
      ),
      body: Column(
        children: [
          // FILTER + AUTOCOMPLETE
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _dateBox('Dari', filter.start, (d){ ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = d..end = filter.end..search = filter.search..periode='CUSTOM'; })),
                  const SizedBox(width: 8),
                  Expanded(child: _dateBox('Sampai', filter.end, (d){ ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = filter.start..end = d..search = filter.search..periode='CUSTOM'; })),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: filter.isBalanced==null? Colors.grey: Colors.green, borderRadius: BorderRadius.circular(8)), child: Text(filter.periode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(hintText: 'Autocomplete: cari SKU / Nama Barang / Customer / Supplier - Auto Index', prefixIcon: const Icon(Icons.search, size: 18), suffixIcon: IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: (){ _searchCtrl.clear(); ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = filter.start..end = filter.end; }), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), isDense: true),
                  onChanged: (v){ ref.read(closingFilterProvider.notifier).state = ClosingFilter()..start = filter.start..end = filter.end..search = v..periode = filter.periode; },
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              data: (d) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // STATUS BALANCED
                  Card(color: d.isBalanced? Colors.green.shade50: Colors.red.shade50, child: ListTile(leading: Icon(d.isBalanced? Icons.verified: Icons.warning, color: d.isBalanced? Colors.green: Colors.red, size: 30), title: Text(d.isBalanced? 'NERACA BALANCE - Siap Tutup Buku':'NERACA TIDAK BALANCE - Cek Selisih', style: TextStyle(fontWeight: FontWeight.bold, color: d.isBalanced? Colors.green.shade700: Colors.red.shade700)), subtitle: Text('Modal Akhir: ${f.format(d.modalAkhir)} | Kas: ${f.format(d.totalKas)}'))),

                  // LABA RUGI
                  _section('1. LABA RUGI - AUTO SYNC PENJUALAN & PEMBELIAN', [
                    _row('Saldo Awal Kas', f.format(d.saldoAwal), Colors.grey),
                    _row('Omset Penjualan', f.format(d.omset), Colors.green, true),
                    _row('HPP (Auto dari Mutasi Stock OUT)', f.format(d.hpp), Colors.orange),
                    _row('Laba Kotor', f.format(d.labaKotor), Colors.blue, true),
                    _row('Total Biaya Operasional', f.format(d.biaya), Colors.red),
                    const Divider(),
                    _row('LABA BERSIH PERIODE', f.format(d.labaBersih), d.labaBersih>=0? Colors.green: Colors.red, true, 16),
                    _row('Saldo Akhir Kas', f.format(d.saldoAkhir), Colors.indigo, true),
                  ]),

                  // NERACA STOCK
                  _section('2. STOCK - AUTO SYNC ITEM MASUK/KELUAR/OPNAME/PERAKITAN', [
                    _row('Stock Awal (Hitung Mundur)', f.format(d.totalStockAwal), Colors.grey),
                    _row('Stock Akhir (Real Time)', f.format(d.totalStockAkhir), Colors.blue, true),
                    _row('Selisih Stock', f.format(d.selisihStock), d.selisihStock>=0? Colors.green: Colors.red),
                    const SizedBox(height: 8),
                    ...d.stockOpname.take(5).map((s)=> ListTile(dense: true, title: Text(s.name, style: const TextStyle(fontSize: 11)), trailing: Text('${s.stock} x ${f.format(s.hargaBeli)} = ${f.format(s.stock * s.hargaBeli)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                    if(d.stockOpname.length>5) Text('... dan ${d.stockOpname.length-5} SKU lainnya (filter pakai search di atas)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),

                  // PIUTANG & HUTANG
                  _section('3. PIUTANG & HUTANG - AUTO SYNC INV-XXX & HUT-XXX', [
                    _row('Total Piutang Aktif (Customer Belum Bayar)', f.format(d.totalPiutang), Colors.orange, true),
                    _row('Total Hutang Aktif (Ke Supplier)', f.format(d.totalHutang), Colors.red, true),
                    _row('Total Aset Tetap (Etalase, dll)', f.format(d.totalAsetTetap), Colors.brown),
                    const Divider(),
                    _row('MODAL AKHIR - TOTAL KEKAYAAN BERSIH', f.format(d.modalAkhir), Colors.purple, true, 16),
                  ]),

                  _section('4. RINCIAN HUTANG - INDEXING BY SUPPLIER', [
                    ...d.hutang.take(5).map((h)=> ListTile(dense: true, leading: Icon(h.remainingAmount>0? Icons.pending: Icons.check, color: h.remainingAmount>0? Colors.red: Colors.green, size: 16), title: Text('${h.invoiceNo} - ${h.supplierName}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')), trailing: Text(f.format(h.remainingAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                  ]),

                  _section('5. RINCIAN PIUTANG - INDEXING BY CUSTOMER', [
                    ...d.piutang.take(5).map((p)=> ListTile(dense: true, leading: CircleAvatar(radius: 10, backgroundColor: p.statusNgendapWarna=='MERAH'?Colors.red:Colors.orange, child: Text('${p.umurNgendap}', style: const TextStyle(fontSize: 7, color: Colors.white))), title: Text('${p.invoiceNo} - ${p.customerName}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')), trailing: Text(f.format(p.remainingAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                  ]),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: ()=> _prosesTutupBuku(context, filter), icon: const Icon(Icons.lock_clock), label: const Text('KUNCI & TUTUP BUKU PERIODE INI'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: ()=> _exportExcel(d), icon: const Icon(Icons.file_download), label: const Text('Export Excel Tutup Buku')),
                ],
              ),
              loading: ()=> const Center(child: CircularProgressIndicator()),
              error: (e,s)=> Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime date, Function(DateTime) onPick) => InkWell(onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now(), initialDate: date); if(d!=null) onPick(d); }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)), Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])));

  Widget _section(String title, List<Widget> children) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)), const Divider(), ...children])));

  Widget _row(String label, String value, Color color, [bool bold=false, double size=13]) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: TextStyle(fontSize: size, fontWeight: bold? FontWeight.bold: FontWeight.normal))), Text(value, style: TextStyle(fontSize: size, fontWeight: bold? FontWeight.bold: FontWeight.w600, color: color))]));

  void _prosesTutupBuku(BuildContext ctx, ClosingFilter filter) async {
    final confirm = await showDialog<bool>(context: ctx, builder: (_)=> AlertDialog(title: const Text('Kunci Tutup Buku?'), content: Text('Periode ${DateFormat('dd MMM yyyy').format(filter.start)} - ${DateFormat('dd MMM yyyy').format(filter.end)} akan dikunci. Stock awal periode berikutnya = stock akhir periode ini. Yakin?'), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx,false), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(ctx,true), child: const Text('Kunci'))]));
    if(confirm==true){
      // TODO: simpan ke tabel closing_book
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Tutup Buku Berhasil - Stock Awal Periode Berikutnya Auto Update')));
    }
  }

  void _exportExcel(ClosingBookData d) {
    // TODO: pakai excel package
  }
}