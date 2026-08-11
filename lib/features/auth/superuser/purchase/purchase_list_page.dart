import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'purchase_input_page.dart';

class PurchaseListPage extends ConsumerStatefulWidget {
  const PurchaseListPage({super.key});
  @override
  ConsumerState<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends ConsumerState<PurchaseListPage> {
  final searchCtrl = TextEditingController();
  String keyword = '';
  DateTime? filterDate;

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Kulak Supplier - List Faktur', style: TextStyle(fontSize: 14))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Auto Index: Ketik No Faktur / Supplier / Tgl (12 Agu 2025)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDate: DateTime.now());
                  if (d != null) setState(() => filterDate = d);
                }),
                if (filterDate != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => filterDate = null)),
              ]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() => keyword = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PurchaseData>>(
            stream: db.select(db.purchases).watch(),
            builder: (c, snap) {
              var list = snap.data ?? [];
              // AUTO INDEX FILTER
              if (keyword.isNotEmpty) {
                list = list.where((p) => p.invoiceNo.toLowerCase().contains(keyword) || p.id.toLowerCase().contains(keyword) || p.supplierId.toLowerCase().contains(keyword)).toList();
              }
              if (filterDate != null) {
                list = list.where((p) => p.createdAt.day == filterDate!.day && p.createdAt.month == filterDate!.month && p.createdAt.year == filterDate!.year).toList();
              }
              list.sort((a,b) => b.createdAt.compareTo(a.createdAt));

              if (list.isEmpty) return const Center(child: Text('Belum ada kulakan'));
              return ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
                final p = list[i];
                return Card(child: ListTile(title: Text(p.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), subtitle: Text('${p.supplierId} | ${DateFormat('dd MMM yyyy').format(p.createdAt)} | ${fmt.format(p.totalAmount)}', style: const TextStyle(fontSize: 10)), trailing: Text(p.status.name, style: const TextStyle(fontSize: 10))));
              });
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add), label: const Text('Kulak Baru'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseInputPage()))),
    );
  }
}