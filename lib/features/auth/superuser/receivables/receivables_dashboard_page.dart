import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class ReceivablesDashboardPage extends ConsumerWidget {
  const ReceivablesDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(activeReceivablesStreamProvider);
    final db = ref.watch(localDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Piutang - Bos Anti Pusing'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> db.receivablesDao.refreshUmurNgendapAll())]),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> Navigator.pushNamed(context, '/receivables/input'), label: const Text('Input Piutang'), icon: const Icon(Icons.add)),
      body: FutureBuilder<Map<String,double>>(
        future: db.receivablesDao.getAgingBucket(),
        builder: (ctx, snap) {
          final aging = snap.data ?? {'0-7':0,'8-30':0,'31-60':0,'>60':0};
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // TOTAL UANG NYANGKUT
              FutureBuilder<double>(
                future: db.receivablesDao.getTotalActiveReceivableAmount(),
                builder: (_, s) => Card(color: Colors.red.shade50, child: ListTile(title: const Text('TOTAL UANG NYANGKUT', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Rp ${s.data??0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)), trailing: const Icon(Icons.money_off, color: Colors.red, size: 40))),
              ),
              const SizedBox(height: 12),
              // AGING
              Row(children: [
                _agingCard('0-7 Hari', aging['0-7']!, Colors.green),
                const SizedBox(width: 8),
                _agingCard('8-30 Hari', aging['8-30']!, Colors.orange),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _agingCard('31-60 Hari', aging['31-60']!, Colors.deepOrange),
                const SizedBox(width: 8),
                _agingCard('>60 MERAH', aging['>60']!, Colors.red),
              ]),
              const Divider(height: 24),
              const Text('Top 10 Overdue Paling Ngendown', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder(
                future: db.receivablesDao.getTop10Overdue(),
                builder: (_, AsyncSnapshot<List<ReceivableData>> s) {
                  if (!s.hasData) return const CircularProgressIndicator();
                  return Column(children: s.data!.map((r) => ListTile(
                    dense: true,
                    leading: CircleAvatar(backgroundColor: r.statusNgendapWarna=='MERAH'?Colors.red:r.statusNgendapWarna=='ORANGE'?Colors.orange:Colors.green, child: Text('${r.umurNgendap}h', style: const TextStyle(fontSize: 10, color: Colors.white))),
                    title: Text('${r.invoiceNo} - ${r.customerName}'),
                    subtitle: Text('${r.kenapaNgendap} | Sales: ${r.salesmanId}'),
                    trailing: Text('Rp ${r.remainingAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  )).toList());
                },
              ),
              const Divider(),
              const Text('Piutang Jatuh Tempo Hari Ini - TAGIH!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              FutureBuilder(
                future: db.receivablesDao.getJtHariIni(),
                builder: (_, AsyncSnapshot<List<ReceivableData>> s) {
                  if (!s.hasData || s.data!.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Aman, tidak ada JT hari ini'));
                  return Column(children: s.data!.map((r) => ListTile(tileColor: Colors.yellow.shade100, title: Text(r.customerName??''), subtitle: Text(r.invoiceNo??''), trailing: Text('Rp ${r.remainingAmount}'))).toList());
                },
              ),
              const Divider(),
              // List Active
              const Text('Semua Piutang Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
              receivablesAsync.when(
                data: (list) => Column(children: list.map((e) => Card(child: ListTile(
                  title: Text('${e.receivable.invoiceNo} - ${e.customer?.name?? e.receivable.customerName}'),
                  subtitle: Text('Umur: ${e.receivable.umurNgendap} hari | ${e.receivable.kenapaNgendap} | Warna: ${e.receivable.statusNgendapWarna}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Rp ${e.receivable.remainingAmount}', style: const TextStyle(fontWeight: FontWeight.bold)), Text(e.receivable.dueDate.toString().substring(0,10), style: const TextStyle(fontSize: 10))]),
                ))).toList()),
                loading: ()=> const CircularProgressIndicator(),
                error: (e,s)=> Text('Error $e'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _agingCard(String title, double amount, Color color) {
    return Expanded(child: Card(color: color.withOpacity(0.1), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('Rp ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))]))));
  }
}