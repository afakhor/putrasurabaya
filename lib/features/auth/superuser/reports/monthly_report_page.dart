import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

class MonthlyFilter {
  DateTime month; String search; String status;
  MonthlyFilter({DateTime? month, this.search = '', this.status = 'SEMUA'}) : month = month?? DateTime(DateTime.now().year, DateTime.now().month, 1);
  MonthlyFilter copyWith({DateTime? month, String? search, String? status}) => MonthlyFilter(month: month?? this.month, search: search?? this.search, status: status?? this.status);
}
final monthlyFilterProvider = StateProvider<MonthlyFilter>((ref) => MonthlyFilter());
final monthlyReportProvider = FutureProvider((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final f = ref.watch(monthlyFilterProvider);
  final start = DateTime(f.month.year, f.month.month, 1);
  final end = DateTime(f.month.year, f.month.month + 1, 0, 23, 59, 59);
  var hutang = await db.payablesDao.getPayablesByDateRange(start, end);
  var piutang = await db.receivablesDao.getReceivablesByDateRange(start, end);
  var stock = await db.productDao.getAllProducts();
  if(f.search.isNotEmpty){
    final q = f.search.toLowerCase();
    hutang = hutang.where((e)=> (e.supplierName??'').toLowerCase().contains(q)).toList();
    piutang = piutang.where((e)=> (e.customerName??'').toLowerCase().contains(q)).toList();
    stock = stock.where((e)=> e.name.toLowerCase().contains(q)).toList();
  }
  return {'hutang': hutang, 'piutang': piutang, 'stock': stock};
});

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});
  @override ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}
class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> with SingleTickerProviderStateMixin {
  late TabController tab; final search = TextEditingController();
  @override void initState(){ super.initState(); tab = TabController(length: 3, vsync: this); }
  @override Widget build(BuildContext context){
    final filter = ref.watch(monthlyFilterProvider);
    final data = ref.watch(monthlyReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(appBar: AppBar(title: const Text('Laporan Bulanan Rekap'), backgroundColor: Colors.indigo.shade700, bottom: TabBar(controller: tab, tabs: const [Tab(text:'HUTANG'), Tab(text:'PIUTANG'), Tab(text:'STOCK')])), body: Column(children:[
      Container(color: Colors.indigo.shade50, padding: const EdgeInsets.all(12), child: TextField(controller: search, decoration: const InputDecoration(hintText:'Cari supplier / customer / SKU - Auto Index', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged:(v)=> ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(search: v))),
      Expanded(child: data.when(data:(r){ final hutang = r['hutang'] as List<PayableData>; final piutang = r['piutang'] as List<ReceivableData>; final stock = r['stock'] as List<ProductData>; return TabBarView(controller: tab, children:[
        ListView.builder(itemCount: hutang.length, itemBuilder:(_,i){ final h=hutang[i]; return Card(child:ListTile(title:Text(h.supplierName??'-'), subtitle:Text(h.invoiceNo??''), trailing:Text(fmt.format(h.remainingAmount)))); }),
        ListView.builder(itemCount: piutang.length, itemBuilder:(_,i){ final p=piutang[i]; return Card(child:ListTile(title:Text(p.customerName??'-'), subtitle:Text(p.invoiceNo??''), trailing:Text(fmt.format(p.remainingAmount)))); }),
        ListView.builder(itemCount: stock.length, itemBuilder:(_,i){ final s=stock[i]; return Card(child:ListTile(title:Text(s.name), subtitle:Text('Stok ${s.stock}'), trailing:Text(fmt.format(s.stock * (s.modal?? 0)))); }),
      ]); }, loading:()=> const Center(child:CircularProgressIndicator()), error:(e,s)=> Center(child:Text('Error $e')))),
    ]));
  }
}