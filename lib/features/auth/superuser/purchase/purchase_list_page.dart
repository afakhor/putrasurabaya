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
  String keyword = '';
  DateTime? filterDate;
  String statusFilter = 'Semua';
  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('List Faktur - Auto Index', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Column(children: [
          TextField(decoration: InputDecoration(hintText: 'Ketik: INV001 / Supplier / 11 Agu / 10jt / >5jt / lunas / belum', prefixIcon: const Icon(Icons.search), suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.calendar_today, size: 18), onPressed: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDate: DateTime.now()); if (d!=null) setState(() => filterDate=d); }), if (filterDate!=null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => filterDate=null))]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (v) => setState(() => keyword = v.toLowerCase())),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Semua','Lunas','Belum Lunas','>5jt','>10jt'].map((s) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(s, style: const TextStyle(fontSize: 10)), selected: statusFilter==s, onSelected: (_) => setState(() => statusFilter=s)))).toList())),
        ])),
        Expanded(child: StreamBuilder<List<PurchaseData>>(stream: db.select(db.purchases).watch(), builder: (c, snap) {
          var list = snap.data ?? [];
          if (keyword.isNotEmpty) {
            list = list.where((p) {
              final k = keyword;
              if (p.invoiceNo.toLowerCase().contains(k)) return true;
              if (p.supplierId.toLowerCase().contains(k)) return true;
              if (DateFormat('dd MMM yyyy', 'id_ID').format(p.createdAt).toLowerCase().contains(k)) return true;
              if (k.contains('lunas') && p.debtAmount ==0) return true;
              if (k.contains('belum') && p.debtAmount >0) return true;
              return false;
            }).toList();
          }
          if (filterDate != null) list = list.where((p) => p.createdAt.day==filterDate!.day && p.createdAt.month==filterDate!.month && p.createdAt.year==filterDate!.year).toList();
          if (statusFilter=='Lunas') list = list.where((p) => p.debtAmount==0).toList();
          if (statusFilter=='Belum Lunas') list = list.where((p) => p.debtAmount>0).toList();
          if (statusFilter=='>5jt') list = list.where((p) => p.totalAmount>5000000).toList();
          if (statusFilter=='>10jt') list = list.where((p) => p.totalAmount>10000000).toList();
          list.sort((a,b) => b.createdAt.compareTo(a.createdAt));
          if (list.isEmpty) return const Center(child: Text('Tidak ada faktur'));
          return ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
            final p = list[i];
            // FIX: p.status adalah String, bukan enum .name
            return Card(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: ListTile(dense: true, title: Text(p.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), subtitle: Text('${p.supplierId} | ${DateFormat('dd MMM yyyy').format(p.createdAt)} | ${fmt.format(p.totalAmount)} - ${p.debtAmount>0?'Sisa ${fmt.format(p.debtAmount)}':'LUNAS'}', style: TextStyle(fontSize: 10, color: p.debtAmount>0?Colors.red:Colors.green)), trailing: Text(p.status.toString(), style: const TextStyle(fontSize: 9))));
          });
        })),
      ]),
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add), label: const Text('Kulak Baru'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseInputPage()))),
    );
  }
}