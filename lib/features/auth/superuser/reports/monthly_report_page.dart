import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

final monthlyFilterProvider = StateProvider<MonthlyFilter>((ref) => MonthlyFilter());

class MonthlyFilter {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String search = '';
  String status = 'SEMUA';
  String sortBy = 'TANGGAL_DESC';
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
  final int totalSKU, stockMati, stockFast;

  MonthlyReport({required this.hutangList, required this.piutangList, required this.stockList, required this.totalHutang, required this.totalPiutang, required this.totalStockValue, required this.totalSKU, required this.stockMati, required this.stockFast});

  static Future<MonthlyReport> generate(LocalDatabase db, MonthlyFilter f) async {
    final start = DateTime(f.month.year, f.month.month, 1);
    final end = DateTime(f.month.year, f.month.month + 1, 0, 23, 59, 59);
    var hutangAll = await db.payablesDao.getByDateRange(start, end);
    var piutangAll = await db.receivablesDao.getByDateRange(start, end);
    var stockAll = await db.productDao.getAllProducts();

    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      hutangAll = hutangAll.where((e) => (e.supplierName?? '').toLowerCase().contains(q)).toList();
      piutangAll = piutangAll.where((e) => (e.customerName?? '').toLowerCase().contains(q)).toList();
      stockAll = stockAll.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    if (f.status == 'BELUM') {
      hutangAll = hutangAll.where((e) => e.remainingAmount > 0).toList();
      piutangAll = piutangAll.where((e) => e.remainingAmount > 0).toList();
    }
    if (f.sortBy == 'NOMINAL_DESC') {
      hutangAll.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
      piutangAll.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    }

    final totalHutang = hutangAll.fold<double>(0, (p, e) => p + e.remainingAmount);
    final totalPiutang = piutangAll.fold<double>(0, (p, e) => p + e.remainingAmount);
    final totalStock = stockAll.fold<double>(0, (p, e) => p + (e.stock * e.hargaBeli));

    return MonthlyReport(
      hutangList: hutangAll, piutangList: piutangAll, stockList: stockAll,
      totalHutang: totalHutang, totalPiutang: totalPiutang, totalStockValue: totalStock,
      totalSKU: stockAll.length,
      stockMati: stockAll.where((e) => e.stock > 0 && e.lastSoldAt!= null && DateTime.now().difference(e.lastSoldAt!).inDays > 60).length,
      stockFast: stockAll.where((e) => e.lastSoldAt!= null && DateTime.now().difference(e.lastSoldAt!).inDays <= 7).length,
    );
  }
}

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});
  @override ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }

  @override Widget build(BuildContext context) {
    final filter = ref.watch(monthlyFilterProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bulanan - Rekap'), backgroundColor: Colors.indigo.shade700, bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'HUTANG'), Tab(text: 'PIUTANG'), Tab(text: 'STOCK')])),
      body: Column(children: [
        Container(color: Colors.indigo.shade50, padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: InkWell(onTap: () async { final p = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now(), initialDate: filter.month); if (p!= null) { ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = DateTime(p.year, p.month, 1)..search = filter.search..status = filter.status..sortBy = filter.sortBy; } }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo)), child: Row(children: [const Icon(Icons.calendar_month, size: 16), const SizedBox(width: 8), Text(DateFormat('MMMM yyyy', 'id_ID').format(filter.month), style: const TextStyle(fontWeight: FontWeight.bold))])))),
            const SizedBox(width: 8),
            DropdownButton<String>(value: filter.status, items: const [DropdownMenuItem(value: 'SEMUA', child: Text('Semua')), DropdownMenuItem(value: 'BELUM', child: Text('Belum')), DropdownMenuItem(value: 'LUNAS', child: Text('Lunas'))], onChanged: (v) { ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month..search = filter.search..status = v!..sortBy = filter.sortBy; }),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Cari supplier / customer / SKU...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white), onChanged: (v) { ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter()..month = filter.month..search = v..status = filter.status..sortBy = filter.sortBy; }),
        ])),
        reportAsync.when(data: (r) => Container(padding: const EdgeInsets.all(8), child: Row(children: [
          _sumCard('Hutang', fmt.format(r.totalHutang), '${r.hutangList.length} faktur', Colors.red),
          const SizedBox(width: 6),
          _sumCard('Piutang', fmt.format(r.totalPiutang), '${r.piutangList.length} INV', Colors.orange),
          const SizedBox(width: 6),
          _sumCard('Stock', fmt.format(r.totalStockValue), '${r.totalSKU} SKU', Colors.blue),
        ])), loading: () => const LinearProgressIndicator(), error: (_, __) => const SizedBox()),
        Expanded(child: reportAsync.when(
          data: (r) => TabBarView(controller: _tab, children: [
            ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.hutangList.length, itemBuilder: (_, i) { final h = r.hutangList[i]; return Card(child: ListTile(dense: true, title: Text('${h.invoiceNo} - ${h.supplierName}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')), subtitle: Text('Sisa: ${fmt.format(h.remainingAmount)}'), trailing: Icon(h.remainingAmount > 0? Icons.warning : Icons.check, color: h.remainingAmount > 0? Colors.red : Colors.green))); }),
            ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.piutangList.length, itemBuilder: (_, i) { final p = r.piutangList[i]; return Card(child: ListTile(dense: true, title: Text('${p.invoiceNo} - ${p.customerName}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')), subtitle: Text('${p.kenapaNgendap} - ${p.umurNgendap} hari'), trailing: Text(fmt.format(p.remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold)))); }),
            ListView.builder(padding: const EdgeInsets.all(8), itemCount: r.stockList.length, itemBuilder: (_, i) { final s = r.stockList[i]; final val = s.stock * s.hargaBeli; return Card(child: ListTile(dense: true, leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6)), child: Text('${s.stock}', style: const TextStyle(color: Colors.white, fontSize: 11))), title: Text(s.name, style: const TextStyle(fontSize: 12)), subtitle: Text('SKU: ${s.sku} | Val: ${fmt.format(val)}', style: const TextStyle(fontSize: 10)), trailing: Text(fmt.format(val), style: const TextStyle(fontWeight: FontWeight.bold)))); }),
          ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error $e')),
        )),
      ]),
    );
  }

  Widget _sumCard(String title, String nominal, String sub, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)), Text(nominal, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)), Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey))]))));
  }
}