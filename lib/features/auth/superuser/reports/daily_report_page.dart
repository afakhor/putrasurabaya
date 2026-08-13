import 'package:drift/drift.dart'hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/report_dao.dart';
import 'package:intl/intl.dart';

final reportDateProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(2022,1,1), end: DateTime(now.year, now.month, now.day, 23,59,59));
});

final dailyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final range = ref.watch(reportDateProvider);
  final laporan = await db.reportDao.getLaporanLabaRugi(range.start, range.end);
  final daily = await db.reportDao.getDailyOmsetSummary(startDate: range.start, endDate: range.end);
  final payables = await (db.select(db.payables)..where((t)=> t.createdAt.isBiggerOrEqualValue(range.start) & t.createdAt.isSmallerOrEqualValue(range.end))).get();
  final receivables = await (db.select(db.receivables)..where((t)=> t.createdAt.isBiggerOrEqualValue(range.start) & t.createdAt.isSmallerOrEqualValue(range.end))).get();
  final mutasi = await (db.select(db.stockMutations)..where((t)=> t.date.isBiggerOrEqualValue(range.start) & t.date.isSmallerOrEqualValue(range.end))..orderBy([(t)=> OrderingTerm(expression: t.date, mode: OrderingMode.desc)])..limit(20)).get();
  return {'laporan': laporan, 'daily': daily, 'payables': payables, 'receivables': receivables, 'mutasi': mutasi};
});

class DailyReportPage extends ConsumerWidget {
  const DailyReportPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateProvider);
    final report = ref.watch(dailyReportProvider);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Harian Real-Time'), backgroundColor: Colors.indigo, actions:[
        IconButton(icon: const Icon(Icons.date_range), onPressed: () async {
          final p = await showDateRangePicker(context: context, firstDate: DateTime(2022,1,1), lastDate: DateTime.now(), initialDateRange: range);
          if(p!=null) ref.read(reportDateProvider.notifier).state = p;
        }),
      ]),
      body: report.when(
        data: (d){
          final laporan = d['laporan'] as LaporanLabaRugiData;
          return ListView(padding: const EdgeInsets.all(12), children:[
            Card(color: Colors.indigo.shade50, child: ListTile(leading: const Icon(Icons.calendar_today), title: Text('${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}'), subtitle: Text('${laporan.totalTransaksiCount} transaksi | Auto Sync'))),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
              _row('Omset', f.format(laporan.totalOmset), Colors.green, true),
              _row('HPP', f.format(laporan.totalHpp), Colors.orange),
              _row('Laba Kotor', f.format(laporan.labaKotor), Colors.blue, true),
              _row('Pengeluaran', f.format(laporan.totalPengeluaran), Colors.red),
              const Divider(),
              _row('LABA BERSIH', f.format(laporan.labaBersih), laporan.labaBersih>=0?Colors.green:Colors.red, true),
            ]))),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              const Text('Mutasi Stock Real-Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11)),
              const Divider(),
              ...(d['mutasi'] as List<StockMutationData>).map((m)=> ListTile(dense:true, leading: Icon(m.type=='masuk'||m.type=='pembelian'?Icons.arrow_downward:Icons.arrow_upward, color: m.quantity>0?Colors.green:Colors.red, size:16), title: Text('${m.productId} | ${m.type}', style: const TextStyle(fontSize:10)), subtitle: Text('${DateFormat('dd/MM HH:mm').format(m.date)} | ${m.referenceNo??""}', style: const TextStyle(fontSize:9)), trailing: Text('${m.quantity>0?"+":""}${m.quantity}', style: TextStyle(fontSize:11, fontWeight: FontWeight.bold, color: m.quantity>0?Colors.green:Colors.red)))),
            ]))),
          ]);
        },
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('Error $e')),
      ),
    );
  }
  Widget _row(String l, String v, Color c, [bool b=false]) => Padding(padding: const EdgeInsets.symmetric(vertical:3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(l, style: TextStyle(fontSize:12, fontWeight: b?FontWeight.bold:FontWeight.normal)), Text(v, style: TextStyle(fontSize:12, color:c, fontWeight: FontWeight.bold))]));
}