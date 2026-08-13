import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

class MonthlyFilter {
  DateTime startDate; DateTime endDate; String search; String status; String periode; String? categoryId;
  MonthlyFilter({DateTime? startDate, DateTime? endDate, this.search='', this.status='SEMUA', this.periode='AWAL_AKHIR', this.categoryId})
      : startDate = startDate ?? DateTime(2022,1,1), endDate = endDate ?? DateTime.now();
  MonthlyFilter copyWith({DateTime? startDate, DateTime? endDate, String? search, String? status, String? periode, String? categoryId}) =>
      MonthlyFilter(startDate: startDate??this.startDate, endDate: endDate??this.endDate, search: search??this.search, status: status??this.status, periode: periode??this.periode, categoryId: categoryId??this.categoryId);
}

final monthlyFilterProvider = StateProvider<MonthlyFilter>((ref) => MonthlyFilter());

final monthlyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final f = ref.watch(monthlyFilterProvider);
  
  final payables = await (db.select(db.payables)..where((t)=> t.createdAt.isBetweenValues(f.startDate, f.endDate.add(const Duration(days:1))))).get();
  final receivables = await (db.select(db.receivables)..where((t)=> t.createdAt.isBetweenValues(f.startDate, f.endDate.add(const Duration(days:1))))).get();
  final products = await db.select(db.products).get();
  final categories = await db.select(db.categories).get();
  final laporan = await db.reportDao.getLaporanLabaRugi(f.startDate, f.endDate);
  final topProducts = await db.reportDao.getTopSellingProducts(startDate: f.startDate, endDate: f.endDate, limit: 10);

  var hutang = payables;
  var piutang = receivables;
  var stock = products;

  if(f.categoryId != null && f.categoryId!.isNotEmpty){
    stock = stock.where((e)=> e.categoryId==f.categoryId).toList();
  }
  if(f.search.isNotEmpty){
    final q = f.search.toLowerCase();
    hutang = hutang.where((e) => (e.supplierName??'').toLowerCase().contains(q)).toList();
    piutang = piutang.where((e) => (e.customerName??'').toLowerCase().contains(q) || (e.invoiceNo??'').toLowerCase().contains(q)).toList();
    stock = stock.where((e) => e.name.toLowerCase().contains(q) || (e.code??'').toLowerCase().contains(q)).toList();
  }
  if(f.status=='BELUM'){
    hutang = hutang.where((e) => e.remainingAmount>0).toList();
    piutang = piutang.where((e) => e.remainingAmount>0).toList();
  }

  // HITUNG PER CATEGORY REAL TIME
  final Map<String, Map<String, dynamic>> catMap = {};
  for(final cat in categories){
    final catProds = products.where((p)=> p.categoryId==cat.id).toList();
    final catProdIds = catProds.map((e)=> e.id).toSet();
    // hitung omset kategori dari topProducts tidak ada kategori, jadi hitung dari stock value saja real time
    final catStockVal = catProds.fold<double>(0, (p,e)=> p + (e.stock * e.buyPrice));
    final catStockQty = catProds.fold<double>(0, (p,e)=> p + e.stock);
    catMap[cat.id] = {'name': cat.name, 'color': cat.colorHex, 'stockVal': catStockVal, 'qty': catStockQty, 'sku': catProds.length};
  }

  return {
    'hutang': hutang, 'piutang': piutang, 'stock': stock,
    'laporan': laporan, 'topProducts': topProducts,
    'catMap': catMap, 'categories': categories,
    'totalH': hutang.fold<double>(0, (p,e)=> p+e.remainingAmount),
    'totalP': piutang.fold<double>(0, (p,e)=> p+e.remainingAmount),
    'totalStockVal': stock.fold<double>(0, (p,e)=> p + (e.stock * e.buyPrice)),
  };
});

class MonthlyReportPage extends ConsumerWidget {
  const MonthlyReportPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(monthlyFilterProvider);
    final data = ref.watch(monthlyReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Real-Time Dari Awal'), backgroundColor: Colors.indigo.shade700),
      body: Column(children:[
        Container(color: Colors.indigo.shade50, padding: const EdgeInsets.all(10), child: Column(children:[
          Row(children:[
            Expanded(child: InkWell(onTap: () async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime(2022,1,1), lastDate: DateTime.now(), initialDateRange: DateTimeRange(start: filter.startDate, end: filter.endDate));
              if(picked!=null) ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(startDate: picked.start, endDate: picked.end, periode: '${df.format(picked.start)} - ${df.format(picked.end)}');
            }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo)), child: Row(children:[const Icon(Icons.date_range, size:14), const SizedBox(width:4), Expanded(child: Text(filter.periode=='AWAL_AKHIR' ? 'Dari Awal (1 Jan 2022) - Hari Ini (Default)' : filter.periode, style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))])))),
            const SizedBox(width:6),
            PopupMenuButton<String>(onSelected: (v){
              if(v=='AWAL_AKHIR') ref.read(monthlyFilterProvider.notifier).state = MonthlyFilter();
              if(v=='BULAN_INI') ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(startDate: DateTime(DateTime.now().year, DateTime.now().month, 1), endDate: DateTime.now(), periode: 'BULAN INI');
              if(v=='TAHUN_INI') ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(startDate: DateTime(DateTime.now().year,1,1), endDate: DateTime.now(), periode: 'TAHUN INI');
            }, itemBuilder: (_)=> const [PopupMenuItem(value:'AWAL_AKHIR', child: Text('Dari Awal - Akhir')), PopupMenuItem(value:'BULAN_INI', child: Text('Bulan Ini')), PopupMenuItem(value:'TAHUN_INI', child: Text('Tahun Ini'))]),
          ]),
          const SizedBox(height:6),
          Row(children:[
            Expanded(child: TextField(decoration: const InputDecoration(hintText:'Cari supplier/customer/SKU - Auto', prefixIcon: Icon(Icons.search, size:16), border: OutlineInputBorder(), isDense:true, filled:true, fillColor: Colors.white, contentPadding: EdgeInsets.all(8)), onChanged: (v)=> ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(search: v))),
            const SizedBox(width:6),
            FutureBuilder<List<CategoryData>>(future: ref.watch(localDatabaseProvider).select(ref.watch(localDatabaseProvider).categories).get(), builder: (c,s){
              if(!s.hasData) return const SizedBox();
              return DropdownButton<String>(hint: const Text('Kategori', style: TextStyle(fontSize:11)), value: filter.categoryId, items: [const DropdownMenuItem(value: '', child: Text('Semua Kategori', style: TextStyle(fontSize:11))), ...s.data!.map((e)=> DropdownMenuItem(value: e.id, child: Text(e.name, style: const TextStyle(fontSize:11))))], onChanged: (v)=> ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(categoryId: v==''?null:v));
            }),
          ]),
        ])),
        Expanded(child: data.when(
          data: (r){
            final laporan = r['laporan'] as LaporanLabaRugiData;
            final hutang = r['hutang'] as List<PayableData>;
            final piutang = r['piutang'] as List<ReceivableData>;
            final stock = r['stock'] as List<ProductData>;
            final catMap = r['catMap'] as Map<String, Map<String, dynamic>>;
            return ListView(padding: const EdgeInsets.all(8), children:[
              Card(color: Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(10), child: Column(children:[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('Omset: ${fmt.format(laporan.totalOmset)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)), Text('Laba: ${fmt.format(laporan.labaBersih)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12, color: laporan.labaBersih>=0?Colors.green:Colors.red))]),
                const SizedBox(height:4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('HPP: ${fmt.format(laporan.totalHpp)}', style: const TextStyle(fontSize:10)), Text('Biaya: ${fmt.format(laporan.totalPengeluaran)}', style: const TextStyle(fontSize:10))]),
              ]))),
              Row(children:[
                _sum('Hutang', fmt.format(r['totalH']), '${hutang.length} faktur', Colors.red),
                const SizedBox(width:6),
                _sum('Piutang', fmt.format(r['totalP']), '${piutang.length} INV', Colors.orange),
                const SizedBox(width:6),
                _sum('Stock', fmt.format(r['totalStockVal']), '${stock.length} SKU', Colors.blue),
              ]),
              const SizedBox(height:8),
              const Text('BREAKDOWN PER CATEGORY (Auto Sync)', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11)),
              const SizedBox(height:4),
              Wrap(spacing:6, runSpacing:6, children: catMap.entries.map((e)=> Chip(label: Text('${e.value['name']} | ${e.value['sku']} SKU | ${fmt.format(e.value['stockVal'])}', style: const TextStyle(fontSize:9)), backgroundColor: Colors.indigo.shade50)).toList()),
              const Divider(),
              ListTile(tileColor: Colors.red.shade50, dense:true, title: Text('HUTANG (${hutang.length}) - Dari Awal Sampai ${df.format(filter.endDate)}', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))),
              ...hutang.take(10).map((e)=> Card(child: ListTile(dense:true, title: Text(e.supplierName??'-', style: const TextStyle(fontSize:11)), subtitle: Text('${DateFormat('dd/MM/yy').format(e.createdAt)} | ${e.status}', style: const TextStyle(fontSize:9)), trailing: Text(fmt.format(e.remainingAmount), style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))))),
              ListTile(tileColor: Colors.orange.shade50, dense:true, title: Text('PIUTANG (${piutang.length})', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))),
              ...piutang.take(10).map((e)=> Card(child: ListTile(dense:true, leading: CircleAvatar(radius:12, backgroundColor: e.statusNgendapWarna=='MERAH'?Colors.red:Colors.orange, child: Text('${e.umurNgendap}d', style: const TextStyle(fontSize:7, color:Colors.white))), title: Text('${e.invoiceNo??"-"} - ${e.customerName??"-"}', style: const TextStyle(fontSize:10, fontFamily:'monospace')), trailing: Text(fmt.format(e.remainingAmount), style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))))),
              ListTile(tileColor: Colors.blue.shade50, dense:true, title: Text('STOCK REAL TIME (${stock.length} SKU)', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))),
              ...stock.take(15).map((e)=> Card(child: ListTile(dense:true, leading: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: e.stock<=e.minStock?Colors.red:Colors.blue, borderRadius: BorderRadius.circular(4)), child: Text('${e.stock.toInt()}', style: const TextStyle(color:Colors.white, fontSize:9))), title: Text(e.name, style: const TextStyle(fontSize:11)), subtitle: Text('Cat: ${e.categoryId} | ${e.code??"-"} | ${fmt.format(e.buyPrice)}', style: const TextStyle(fontSize:9)), trailing: Text(fmt.format(e.stock * e.buyPrice), style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold))))),
            ]);
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error $e')),
        )),
      ]),
    );
  }
  Widget _sum(String t, String v, String sub, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(t, style: TextStyle(fontSize:9, color:c, fontWeight: FontWeight.bold)), Text(v, style: TextStyle(fontSize:10, color:c, fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(fontSize:8, color:Colors.grey))]))); 
}