import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

final reportDateProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59));
});

final dailyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  try {
    final piutang = await db.receivablesDao.getTotalActiveReceivableAmount();
    final hutang = await db.payablesDao.getTotalActivePayableAmount();
    final stock = await db.productDao.getAllProducts();
    final stockVal = stock.fold<double>(0, (p, e) => p + (e.stock * (e.modal?? e.hargaJual?? 0)));
    return {'omset': 0.0, 'hpp': 0.0, 'biaya': 0.0, 'piutang': piutang, 'hutang': hutang, 'stockVal': stockVal, 'stockCount': stock.length, 'stockList': stock};
  } catch (e) {
    return {'omset': 0.0, 'hpp': 0.0, 'biaya': 0.0, 'piutang': 0.0, 'hutang': 0.0, 'stockVal': 0.0, 'stockCount': 0, 'stockList': <ProductData>[]};
  }
});

class DailyReportPage extends ConsumerWidget {
  const DailyReportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateProvider);
    final report = ref.watch(dailyReportProvider);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Harian Bos'), backgroundColor: Colors.indigo, actions: [
        IconButton(icon: const Icon(Icons.date_range), onPressed: () async { final p = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDateRange: range); if (p!= null) ref.read(reportDateProvider.notifier).state = p; }),
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.refresh(dailyReportProvider)),
      ]),
      body: report.when(
        data: (d) => ListView(padding: const EdgeInsets.all(12), children: [
          Card(color: Colors.indigo.shade50, child: ListTile(leading: const Icon(Icons.calendar_today), title: Text('${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}'), subtitle: Text('${d['stockCount']} SKU aktif'))),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('1. OMSET & LABA RUGI - AUTO SYNC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Divider(),
            row('Omset (dari Sales)', f.format(d['omset']), Colors.green, true),
            row('Piutang Aktif (INV-XXX)', f.format(d['piutang']), Colors.orange, true),
            row('Hutang Aktif (HUT-XXX)', f.format(d['hutang']), Colors.red),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('2. NERACA - AUTO SYNC STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Divider(),
            row('Nilai Stock (Real)', f.format(d['stockVal']), Colors.blue, true),
            row('Total SKU', '${d['stockCount']} SKU', Colors.indigo),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('3. MUTASI STOCK - 5 TERAKHIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Divider(),
           ...(d['stockList'] as List<ProductData>).take(5).map((s) => ListTile(dense: true, title: Text(s.name, style: const TextStyle(fontSize: 12)), trailing: Text('Stok: ${s.stock}', style: const TextStyle(fontWeight: FontWeight.bold)))),
          ]))),
        ]),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error $e')),
      ),
    );
  }

  Widget row(String label, String value, Color color, [bool bold = false]) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold? FontWeight.bold : FontWeight.normal, fontSize: 13)), Text(value, style: TextStyle(fontWeight: bold? FontWeight.bold : FontWeight.w600, color: color, fontSize: 13))]));
}