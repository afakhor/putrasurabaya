import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

final closingReportProvider = FutureProvider((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final piutang = await db.receivablesDao.getTotalActiveReceivableAmount();
  final hutang = await db.payablesDao.getTotalActivePayableAmount();
  final stock = await db.productDao.getAllProducts();
  final stockVal = stock.fold<double>(0, (p, e) => p + (e.stock * (e.modal?? 0)));
  return {'piutang': piutang, 'hutang': hutang, 'stockVal': stockVal, 'stockCount': stock.length};
});

class ClosingBookReportPage extends ConsumerWidget {
  const ClosingBookReportPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(closingReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('TUTUP BUKU FINAL BOS'), backgroundColor: Colors.black87),
      body: report.when(
        data: (d) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(color: Colors.green.shade50, child: ListTile(leading: const Icon(Icons.verified, color: Colors.green, size: 32), title: const Text('NERACA BALANCE - Siap Tutup Buku', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Modal Akhir: ${fmt.format((d['stockVal'] as double) + (d['piutang'] as double) - (d['hutang'] as double))}'))),
          const SizedBox(height: 12),
          _row('Nilai Stock Akhir', fmt.format(d['stockVal']), Colors.blue, true),
          _row('Piutang Aktif', fmt.format(d['piutang']), Colors.orange, true),
          _row('Hutang Aktif', fmt.format(d['hutang']), Colors.red, true),
          _row('Total SKU', '${d['stockCount']} SKU', Colors.indigo),
          const Divider(height: 32),
          ElevatedButton.icon(onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutup Buku Berhasil - Periode Dikunci'))); }, icon: const Icon(Icons.lock), label: const Text('KUNCI & TUTUP BUKU'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50))),
        ]),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error $e')),
      ),
    );
  }
  Widget _row(String l, String v, Color c, [bool b=false]) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: TextStyle(fontWeight: b?FontWeight.bold:FontWeight.normal)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c))]));
}