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
      appBar: AppBar(title: const Text('Dashboard Hutang - IPOS')),
      body: FutureBuilder<Map<String,dynamic>>(
        future: db.payablesDao.payableSummary(),
        builder: (c, snap){
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = snap.data!;
          return ListView(
            children: [
              const PayableAlertBanner(),
              Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                _summaryCard('Outstanding', fmt.format(s['totalOutstanding']), Colors.orange, Icons.money_off),
                const SizedBox(width: 8),
                _summaryCard('Overdue', fmt.format(s['totalOverdue']), Colors.red, Icons.warning),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
                _smallCard('Overdue >7h', '${s['countOverdue7']} inv', Colors.red),
                const SizedBox(width: 8),
                _smallCard('Due Today', '${(s['dueToday'] as List).length} inv', Colors.orange),
                const SizedBox(width: 8),
                _smallCard('Due 3 Hari', '${(s['dueNext3Days'] as List).length} inv', Colors.amber),
              ])),
              AgingChart(summary: s),
              const Padding(padding: EdgeInsets.all(12), child: Text('Top 5 Supplier Hutang Terbesar', style: TextStyle(fontWeight: FontWeight.bold))),
             ...((s['top5Supplier'] as Map<String,double>).entries.map((e)=> ListTile(dense:true, title: Text(e.key), trailing: Text(fmt.format(e.value))))),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String val, Color c, IconData ic){
    return Expanded(child: Card(color: c.withOpacity(0.15), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Icon(ic,color: c), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 11)), Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: c))]))));
  }
  Widget _smallCard(String t, String v, Color c){
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [Text(t, style: const TextStyle(fontSize: 10)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12))]))));
  }
}