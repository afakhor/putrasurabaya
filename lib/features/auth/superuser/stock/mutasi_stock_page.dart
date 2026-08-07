import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';
import 'kartu_stock_page.dart';

final warningOnlyProvider = StateProvider<bool>((ref)=> false);

// Provider yang hilang - filter pakai Map biar simple
final allStockMutationsStreamProvider = StreamProvider.family<List<StockCardItemData>, Map<String, dynamic>>((ref, filter) {
  final db = ref.watch(localDatabaseProvider);
  return db.stockMutationDao.watchAllStockMutations(
    mutationTypeFilter: filter['type'] as String?,
    keyword: filter['keyword'] as String?,
  );
});

class MutasiStockPage extends ConsumerStatefulWidget { 
  const MutasiStockPage({super.key}); 
  @override ConsumerState<MutasiStockPage> createState()=> _MutasiState(); 
}

// Alias biar file lama yang manggil MutasiStokPage tetap jalan
class MutasiStokPage extends MutasiStockPage {
  const MutasiStokPage({super.key});
}

class _MutasiState extends ConsumerState<MutasiStockPage> {
  String? filterType; String keyword='';
  @override Widget build(BuildContext context) {
    final warningOnly = ref.watch(warningOnlyProvider);
    final filter = {'type': filterType, 'keyword': keyword.isEmpty?null:keyword};
    final mutasi = ref.watch(allStockMutationsStreamProvider(filter));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Besar Gudang')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(decoration: const InputDecoration(hintText:'Cari Nama/SKU/Ref', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v)=> setState(()=> keyword=v)),
          const SizedBox(height:8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            ChoiceChip(label: const Text('Semua'), selected: filterType==null, onSelected: (_)=> setState(()=> filterType=null)),
           ...StockMutationType.all.map((t)=> Padding(padding: const EdgeInsets.only(left:6), child: ChoiceChip(label: Text(t), selected: filterType==t, onSelected: (_)=> setState(()=> filterType=filterType==t?null:t)))),
          ])),
          CheckboxListTile(value: warningOnly, title: const Text('WARNING ONLY (selisih >=2)', style: TextStyle(fontSize:12, fontWeight: FontWeight.bold)), onChanged: (v)=> ref.read(warningOnlyProvider.notifier).state=v??false),
        ])),
        Expanded(child: mutasi.when(
          data: (list){
            var display = warningOnly? list.where((e)=> e.mutation.type==StockMutationType.opname && e.mutation.quantity.abs()>=2).toList() : list;
            return ListView.builder(itemCount: display.length, itemBuilder: (c,i){
              final d=display[i]; final m=d.mutation;
              Color bg=Colors.white; if(m.stockAfter<0) bg=Colors.red[100]!; else if(m.type==StockMutationType.opname && m.quantity.abs()>=3) bg=Colors.red[50]!; else if(m.type==StockMutationType.opname && m.quantity.abs()>=1) bg=Colors.amber[50]!;
              return Container(color: bg, child: ListTile(dense:true, onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: m.productId))), title: Text('${d.productName} • ${m.type}', style: const TextStyle(fontSize:12, fontWeight: FontWeight.bold)), subtitle: Text('${m.date.toString().substring(0,16)} | ${m.quantity>0?'+':''}${m.quantity} | Awal:${m.stockBefore} Akhir:${m.stockAfter} | ${m.referenceNo}', style: const TextStyle(fontSize:10)), trailing: m.type==StockMutationType.opname && m.quantity.abs()>=2? Icon(Icons.warning, color: m.quantity.abs()>=3? Colors.red : Colors.orange) : null));
            });
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('$e')),
        )),
      ]),
    );
  }
}