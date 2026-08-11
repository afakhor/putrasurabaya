import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'receivables_input_page.dart';

// Provider tanpa type spesifik biar gak error ReceivableWithCustomer
final activeReceivablesStreamProvider = StreamProvider((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.receivablesDao.watchActiveReceivables();
});

class ReceivablesDashboardPage extends ConsumerWidget {
  const ReceivablesDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(activeReceivablesStreamProvider);
    final db = ref.watch(localDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Piutang - Bos Anti Pusing'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> db.receivablesDao.refreshUmurNgendapAll())],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ReceivablesInputPage())), 
        label: const Text('Input Piutang'), 
        icon: const Icon(Icons.add)
      ),
      body: FutureBuilder<Map<String,double>>(
        future: db.receivablesDao.getAgingBucket(),
        builder: (ctx, snap) {
          final aging = snap.data ?? {'0-7':0,'8-30':0,'31-60':0,'>60':0};
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              FutureBuilder<double>(
                future: db.receivablesDao.getTotalActiveReceivableAmount(),
                builder: (_, s) => Card(color: Colors.red.shade50, child: ListTile(title: const Text('TOTAL UANG NYANGKUT', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Rp ${s.data??0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)))),
              ),
              const SizedBox(height: 12),
              Row(children: [_agingCard('0-7 Hari', aging['0-7']!, Colors.green), const SizedBox(width: 8), _agingCard('8-30 Hari', aging['8-30']!, Colors.orange)]),
              const SizedBox(height: 8),
              Row(children: [_agingCard('31-60 Hari', aging['31-60']!, Colors.deepOrange), const SizedBox(width: 8), _agingCard('>60 MERAH', aging['>60']!, Colors.red)]),
              const Divider(height: 24),
              const Text('Semua Piutang Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
              receivablesAsync.when(
                data: (list) {
                  final dataList = list as List<dynamic>;
                  return Column(
                    children: dataList.map<Widget>((e) {
                      final r = e.receivable as ReceivableData;
                      final cust = e.customer as CustomerData?;
                      return Card(child: ListTile(
                        title: Text('${r.invoiceNo} - ${cust?.name?? r.customerName}'),
                        subtitle: Text('Umur: ${r.umurNgendap} hari | ${r.kenapaNgendap}'),
                        trailing: Text('Rp ${r.remainingAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ));
                    }).toList(),
                  );
                },
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