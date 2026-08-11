import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'widgets/aging_chart.dart';
import 'widgets/payable_alert_banner.dart';

class PayablesDashboardPage extends ConsumerWidget {
  const PayablesDashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(localDatabaseProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Hutang - IPOS Anti Bocor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      body: FutureBuilder<Map<String,dynamic>>(
        future: db.payablesDao.payableSummary(),
        builder: (c, snap){
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = snap.data!;
          final double totalOut = (s['totalOutstanding'] as num?)?.toDouble() ?? 0;
          final double totalOver = (s['totalOverdue'] as num?)?.toDouble() ?? 0;
          final dueToday = s['dueToday'] as List? ?? [];
          final due3 = s['dueNext3Days'] as List? ?? [];
          final countOver7 = s['countOverdue7'] ?? 0;

          // 1B: Hitung Aging dari summary jika ada, kalau tidak fallback 0
          final aging = s['aging'] as Map<String,double>? ?? {'0-7':0,'8-30':0,'31-60':0,'>60':0};

          return ListView(
            children: [
              const PayableAlertBanner(),
              Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                _summaryCard('Outstanding', fmt.format(totalOut), Colors.orange, Icons.money_off),
                const SizedBox(width: 8),
                _summaryCard('Overdue', fmt.format(totalOver), Colors.red, Icons.warning),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
                _smallCard('Overdue >7h', '$countOver7 inv', Colors.red),
                const SizedBox(width: 8),
                _smallCard('Due Today', '${dueToday.length} inv', Colors.orange),
                const SizedBox(width: 8),
                _smallCard('Due 3 Hari', '${due3.length} inv', Colors.amber),
              ])),
              // 1B AGING MANUAL
              Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Aging Hutang (1B)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                _agingRow('0-7 Hari Aman', aging['0-7']??0, Colors.green),
                _agingRow('8-30 Hari Due Soon', aging['8-30']??0, Colors.orange),
                _agingRow('31-60 Hari Overdue', aging['31-60']??0, Colors.deepOrange),
                _agingRow('>60 Hari Merah', aging['>60']??0, Colors.red),
              ])),
              AgingChart(summary: s),
              const Padding(padding: EdgeInsets.all(12), child: Text('Top 5 Supplier Hutang Terbesar (1C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ...((s['top5Supplier'] as Map<String,double>? ?? {}).entries.map((e)=> ListTile(dense:true, title: Text(e.key, style: const TextStyle(fontSize: 12)), trailing: Text(fmt.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))),
            ],
          );
        },
      ),
    );
  }
  Widget _summaryCard(String t, String v, Color c, IconData ic){ return Expanded(child: Card(color: c.withOpacity(0.15), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Icon(ic,color: c), const SizedBox(height: 4), Text(t, style: const TextStyle(fontSize: 11)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12))])))); }
  Widget _smallCard(String t, String v, Color c){ return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [Text(t, style: const TextStyle(fontSize: 10)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12))])))); }
  Widget _agingRow(String title, double amt, Color col){ return Card(margin: const EdgeInsets.only(bottom: 4), child: ListTile(dense: true, leading: Container(width: 8, height: 40, color: col), title: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)), trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amt), style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 11)))); }
}