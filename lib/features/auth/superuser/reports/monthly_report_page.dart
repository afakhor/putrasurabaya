import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

final monthlyFilterProvider = StateProvider<String>((ref) => '');

final monthlyReportProvider = FutureProvider((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final filter = ref.watch(monthlyFilterProvider);
  var hutang = await db.payablesDao.getAllPayables();
  var piutang = await db.receivablesDao.getAllReceivables();
  var stock = await db.productDao.getAllProducts();
  if (filter.isNotEmpty) {
    final q = filter.toLowerCase();
    hutang = hutang.where((e) => (e.supplierName ?? '').toLowerCase().contains(q)).toList();
    piutang = piutang.where((e) => (e.customerName ?? '').toLowerCase().contains(q)).toList();
    stock = stock.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
  return {'hutang': hutang, 'piutang': piutang, 'stock': stock};
});

class MonthlyReportPage extends ConsumerWidget {
  const MonthlyReportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final data = ref.watch(monthlyReportProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bulanan'), backgroundColor: Colors.indigo),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(hintText: 'Cari supplier / customer / SKU', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => ref.read(monthlyFilterProvider.notifier).state = v)),
        Expanded(child: data.when(
          data: (r) {
            final hutang = r['hutang'] as List<PayableData>;
            final piutang = r['piutang'] as List<ReceivableData>;
            final stock = r['stock'] as List<ProductData>;
            return ListView(children: [
              ListTile(title: Text('HUTANG: ${hutang.length} faktur'), tileColor: Colors.red.shade50),
              ...hutang.take(10).map((e) => ListTile(title: Text(e.supplierName ?? '-'), subtitle: Text(e.invoiceNo ?? ''), trailing: Text(fmt.format(e.remainingAmount)))),
              const Divider(),
              ListTile(title: Text('PIUTANG: ${piutang.length} INV'), tileColor: Colors.orange.shade50),
              ...piutang.take(10).map((e) => ListTile(title: Text(e.customerName ?? '-'), subtitle: Text(e.invoiceNo ?? ''), trailing: Text(fmt.format(e.remainingAmount)))),
              const Divider(),
              ListTile(title: Text('STOCK: ${stock.length} SKU'), tileColor: Colors.blue.shade50),
              ...stock.take(10).map((e) => ListTile(title: Text(e.name), subtitle: Text('Stok ${e.stock}'), trailing: Text(fmt.format(e.stock * (e.modal ?? 0))))),
            ]);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error $e')),
        )),
      ]),
    );
  }
}