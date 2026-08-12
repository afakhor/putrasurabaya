import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

// ================= PROVIDERS =================
final monthlyFilterProvider = StateProvider<MonthlyFilter>((ref) => MonthlyFilter());

class MonthlyFilter {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String search = '';
  String kategori = 'SEMUA'; // SEMUA, HUTANG, PIUTANG, STOCK
  String status = 'SEMUA'; // SEMUA, LUNAS, BELUM, OVERDUE
  String sortBy = 'TANGGAL_DESC'; // TANGGAL_DESC, NOMINAL_DESC, UMUR_DESC
}

final monthlyReportProvider = FutureProvider<MonthlyReport>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final filter = ref.watch(monthlyFilterProvider);
  return MonthlyReport.generate(db, filter);
});

class MonthlyReport {
  final List<PayableData> hutangList;
  final List<ReceivableData> piutangList;
  final List<ProductData> stockList;
  final double totalHutang, totalPiutang, totalStockValue;
  final double hutangLunas, hutangBelum, piutangLunas, piutangBelum;
  final int totalSKU, stockMati, stockFast;

  MonthlyReport({required this.hutangList, required this.piutangList, required this.stockList, required this.totalHutang, required this.totalPiutang, required this.totalStockValue, required this.hutangLunas, required this.hutangBelum, required this.piutangLunas, required this.piutangBelum, required this.totalSKU, required this.stockMati, required this.stockFast});

  static Future<MonthlyReport> generate(LocalDatabase db, MonthlyFilter f) async {
    final start = DateTime(f.month.year, f.month.month, 1);
    final end = DateTime(f.month.year, f.month.month + 1, 0, 23, 59, 59);

    // HUTANG - AUTO SYNC DARI PURCHASE
    var hutangAll = await db.payablesDao.getByDateRange(start, end);
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      hutangAll = hutangAll.where((e) => (e.supplierName??'').toLowerCase().contains(q) || (e.invoiceNo??'').toLowerCase().contains(q)).toList();
    }
    if (f.status == 'LUNAS') hutangAll = hutangAll.where((e) => e.remainingAmount <= 0).toList();
    if (f.status == 'BELUM') hutangAll = hutangAll.where((e) => e.remainingAmount > 0).toList();

    // PIUTANG - AUTO SYNC DARI SALES
    var piutangAll = await db.receivablesDao.getByDateRange(start, end);
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      piutangAll = piutangAll.where((e) => (e.customerName??'').toLowerCase().contains(q) || (e.invoiceNo??'').toLowerCase().contains(q)).toList();
    }
    if (f.status == 'OVERDUE') piutangAll = piutangAll.where((e) => e.umurNgendap > 30).toList();

    // STOCK - AUTO SYNC DARI MUTASI + PURCHASE + SALES + ASET
    var stockAll = await db.productDao.getAllProducts();
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      stockAll = stockAll.where((e) => e.name.toLowerCase().contains(q) || e.sku.toLowerCase().contains(q)).toList();
    }
    // Sorting & Indexing
    if (f.sortBy == 'NOMINAL_DESC') {
      hutangAll.sort((a,b)=> b.remainingAmount.compareTo(a.remainingAmount));
      piutangAll.sort((a,b)=> b.remainingAmount.compareTo(a.remainingAmount));
      stockAll.sort((a,b)=> (b.stock * b.hargaBeli).compareTo(a.stock * a.hargaBeli));
    }

    final totalHutang = hutangAll.fold<double>(0, (p,e)=> p + e.remainingAmount);
    final totalPiutang = piutangAll.fold<double>(0, (p,e)=> p + e.remainingAmount);
    final totalStock = stockAll.fold<double>(0, (p,e)=> p + (e.stock * e.hargaBeli));

    return MonthlyReport(
      hutangList: hutangAll, piutangList: piutangAll, stockList: stockAll,
      totalHutang: totalHutang, totalPiutang: totalPiutang, totalStockValue: totalStock,
      hutangLunas: hutangAll.where((e)=> e.remainingAmount<=0).fold(0, (p,e)=> p + e.totalAmount),
      hutangBelum: hutangAll.where((e)=> e.remainingAmount>0).fold(0, (p,e)=> p + e.remainingAmount),
      piutangLunas: piutangAll.where((e)=> e.remainingAmount<=0).fold(0, (p,e)=> p + e.totalAmount),
      piutangBelum: piutangAll.where((e)=> e.remainingAmount>0).fold(0, (p,e)=> p + e.remainingAmount),
      totalSKU: stockAll.length,
      stockMati: stockAll.where((e)=> e.stock>0 && e.lastSoldAt!=null && DateTime.now().difference(e.lastSoldAt!).inDays>60).length,
      stockFast: stockAll.where((e)=> e.lastSoldAt!=null && DateTime.now().difference(e.lastSoldAt!).inDays<=7).length,
    );
  }
}

// ================= UI =================
class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});
  @override ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(monthlyFilterProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan - Rekap'),
        backgroundColor: Colors.indigo.shade700,
        bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'HUTANG'), Tab(text: 'PIUTANG'), Tab(text: 'STOCK')]),
      ),
      body: Column(
        children: [
          // FILTER BULAN + SEARCH AUTOCOMPLETE
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: InkWell(onTap: () async {
                    final picked = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now(), initialDate: filter.month, initialDatePickerMode: DatePickerMode.year);
                    if(picked!=null) ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = DateTime(picked.year, picked.month, 1)..search = filter.search..kategori = filter.kategori..status = filter.status..sortBy = filter.sortBy;
                  }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo)), child: Row(children: [const Icon(Icons.calendar_month, size: 16), const SizedBox(width: 8), Text(DateFormat('MMMM yyyy','id_ID').format(filter.month), style: const TextStyle(fontWeight: FontWeight.bold))])))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(value: filter.status, items: const [DropdownMenuItem(value: 'SEMUA', child: Text('Semua')), DropdownMenuItem(value: 'BELUM', child: Text('Belum Lunas')), DropdownMenuItem(value: 'LUNAS', child: Text('Lunas')), DropdownMenuItem(value: 'OVERDUE', child: Text('Overdue'))], onChanged: (v){ ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month..search = filter.search..status = v!..sortBy = filter.sortBy; }),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.sort), onPressed: (){ ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month..search = filter.search..status = filter.status..sortBy = filter.sortBy=='TANGGAL_DESC'?'NOMINAL_DESC':'TANGGAL_DESC'; }),
                ]),
                const SizedBox(height: 8),
                // SEARCH AUTOCOMPLETE - AUTO SYNC
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(hintText: 'Cari supplier / customer / SKU... auto index', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: (){ _searchCtrl.clear(); ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month; }), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onChanged: (v){ ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month..search = v..status = filter.status..sortBy = filter.sortBy; },
                ),
              ],
            ),
          ),
          // SUMMARY CARDS
          reportAsync.when(
            data: (r) => Container(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                _sumCard('Hutang', f.format(r.totalHutang), '${r.hutangList.length} faktur', Colors.red),
                const SizedBox(width: 6),
                _sumCard('Piutang', f.format(r.totalPiutang), '${r.piutangList.length} INV', Colors.orange),
                const SizedBox(width: 6),
                _sumCard('Stock', f.format(r.totalStockValue), '${r.totalSKU} SKU', Colors.blue),
              ]),
            ),
            loading: ()=> const LinearProgressIndicator(),
            error: (_,__)=> const SizedBox(),
          ),
          Expanded(
            child: reportAsync.when(
              data: (r) => TabBarView(controller: _tab, children: [
                _hutangTab(r, f),
                _piutangTab(r, f),
                _stockTab(r, f),
              ]),
              loading: ()=> const Center(child: CircularProgressIndicator()),
              error: (e,_)=> Center(child: Text('Error $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumCard(String title, String nominal, String sub, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)), Text(nominal, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)), Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey))])));

  Widget _hutangTab(MonthlyReport r, NumberFormat f) => ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.hutangList.length, itemBuilder: (_, i){
    final h = r.hutangList[i];
    return Card(child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: h.remainingAmount>0?Colors.red:Colors.green, child: Text('${h.umurHutang??0}d', style: const TextStyle(fontSize: 9, color: Colors.white))), title: Text('${h.invoiceNo} - ${h.supplierName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')), subtitle: Text('Total: ${f.format(h.totalAmount)} | Sisa: ${f.format(h.remainingAmount)} | ${h.status??""}', style: const TextStyle(fontSize: 10)), trailing: Icon(h.remainingAmount>0? Icons.warning_amber_rounded: Icons.check_circle, color: h.remainingAmount>0?Colors.red:Colors.green)));
  });

  Widget _piutangTab(MonthlyReport r, NumberFormat f) => ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.piutangList.length, itemBuilder: (_, i){
    final p = r.piutangList[i];
    Color c = Colors.green; if(p.statusNgendapWarna=='MERAH') c=Colors.red; if(p.statusNgendapWarna=='ORANGE') c=Colors.orange;
    return Card(child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: c, child: Text('${p.umurNgendap}d', style: const TextStyle(fontSize: 9, color: Colors.white))), title: Text('${p.invoiceNo} - ${p.customerName}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')), subtitle: Text('${p.kenapaNgendap} | Sales: ${p.salesmanId??"-"}', style: TextStyle(fontSize: 10, color: c)), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(f.format(p.remainingAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(f.format(p.totalAmount), style: const TextStyle(fontSize: 9))]))));
  });

  Widget _stockTab(MonthlyReport r, NumberFormat f) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8), child: Row(children: [Chip(label: Text('Mati: ${r.stockMati} SKU'), backgroundColor: Colors.red.shade100), const SizedBox(width: 6), Chip(label: Text('Fast: ${r.stockFast}'), backgroundColor: Colors.green.shade100), const SizedBox(width: 6), Chip(label: Text('Total: ${r.totalSKU}'))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.stockList.length, itemBuilder: (_, i){
        final s = r.stockList[i];
        final val = s.stock * s.hargaBeli;
        final isMati = s.lastSoldAt!=null && DateTime.now().difference(s.lastSoldAt!).inDays>60;
        return Card(color: isMati? Colors.red.shade50: null, child: ListTile(dense: true, leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isMati?Colors.red:Colors.blue, borderRadius: BorderRadius.circular(6)), child: Text('${s.stock}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))), title: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: Text('SKU: ${s.sku} | Beli: ${f.format(s.hargaBeli)} | Val: ${f.format(val)} | ${isMati?"MATI ${DateTime.now().difference(s.lastSoldAt!).inDays} hari":""}', style: const TextStyle(fontSize: 10)), trailing: Text(f.format(val), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))));
      })),
    ]);
  }
}