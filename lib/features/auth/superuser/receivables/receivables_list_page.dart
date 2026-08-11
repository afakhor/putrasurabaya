import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class ReceivablesListPage extends ConsumerWidget {
  const ReceivablesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(activeReceivablesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Piutang - INV-XXX-CSTMR'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: listAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_score, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada piutang', style: TextStyle(color: Colors.grey)),
                  Text('Klik Input Piutang untuk buat INV-XXX', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              final r = e.receivable;
              Color warna = Colors.green;
              if (r.statusNgendapWarna == 'MERAH') warna = Colors.red;
              if (r.statusNgendapWarna == 'ORANGE') warna = Colors.orange;
              if (r.statusNgendapWarna == 'KUNING') warna = Colors.amber.shade700;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: warna,
                    child: Text('${r.umurNgendap}d', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(r.invoiceNo?? r.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.customer?.name?? r.customerName?? 'Umum', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${r.kenapaNgendap} | Sales: ${r.salesmanId?? "-"} | ${r.statusNgendapWarna}', style: TextStyle(fontSize: 10, color: warna)),
                      Text('JT: ${r.dueDate?.toString().substring(0,10)?? "-"}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rp ${r.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      Text('Total: ${r.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error $err')),
      ),
    );
  }
}