import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';
import 'kartu_stock_page.dart';

// FIX: jangan pakai Map, pakai class biar == stabil
class MutasiFilter {
  final String? type;
  final String? keyword;
  const MutasiFilter({this.type, this.keyword});
  @override bool operator ==(Object o) => o is MutasiFilter && o.type==type && o.keyword==keyword;
  @override int get hashCode => Object.hash(type, keyword);
}

final warningOnlyProvider = StateProvider<bool>((ref)=> false);
final mutasiFilterProvider = StateProvider<MutasiFilter>((ref) => const MutasiFilter());

final allStockMutationsStreamProvider = StreamProvider<List<StockCardItemData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  final f = ref.watch(mutasiFilterProvider);
  return db.stockMutationDao.watchAllStockMutations(mutationTypeFilter: f.type, keyword: f.keyword);
});

class MutasiStockPage extends ConsumerStatefulWidget { const MutasiStockPage({super.key}); @override ConsumerState<MutasiStockPage> createState()=> _MutasiState(); }
class MutasiStokPage extends MutasiStockPage { const MutasiStokPage({super.key}); }

class _MutasiState extends ConsumerState<MutasiStockPage> {
  final allTypes = ['masuk','keluar','opname','penjualan','pembelian','perakitan'];
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override void dispose(){ _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final warningOnly = ref.watch(warningOnlyProvider);
    final filter = ref.watch(mutasiFilterProvider);
    final mutasi = ref.watch(allStockMutationsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6D58F),
      appBar: AppBar(title: const Text('Buku Besar Gudang', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFF6D58F), elevation: 0),
      body: Column(children: [
        Container(color: const Color(0xFFF6D58F), padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(hintText:'Cari Nama/SKU/Ref', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (v){ _debounce?.cancel(); _debounce=Timer(const Duration(milliseconds: 400), ()=> ref.read(mutasiFilterProvider.notifier).state=MutasiFilter(type: filter.type, keyword: v.isEmpty?null:v)); }
          ),
          const SizedBox(height:8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            ChoiceChip(label: const Text('Semua'), selected: filter.type==null, onSelected: (_)=> ref.read(mutasiFilterProvider.notifier).state=MutasiFilter(type: null, keyword: filter.keyword)),
           ...allTypes.map((t)=> Padding(padding: const EdgeInsets.only(left:6), child: ChoiceChip(label: Text(t), selected: filter.type==t, onSelected: (_)=> ref.read(mutasiFilterProvider.notifier).state=MutasiFilter(type: filter.type==t?null:t, keyword: filter.keyword)))),
          ])),
          CheckboxListTile(value: warningOnly, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.trailing, title: const Text('WARNING ONLY (selisih >=2)', style: TextStyle(fontSize:12, fontWeight: FontWeight.bold)), onChanged: (v)=> ref.read(warningOnlyProvider.notifier).state=v??false),
        ])),
        Expanded(child: Container(color: Colors.white, child: mutasi.when(
          data: (list){
            var display = warningOnly? list.where((e)=> e.mutation.type=='opname' && e.mutation.quantity.abs()>=2).toList() : list;
            if(display.isEmpty) return const Center(child: Text('Belum ada mutasi'));
            return ListView.separated(
              separatorBuilder: (_,__)=> const Divider(height:1),
              itemCount: display.length,
              itemBuilder: (c,i){
                final d=display[i]; final m=d.mutation;
                Color bg=Colors.white; if(m.stockAfter<0) bg=Colors.red[100]!; else if(m.type=='opname' && m.quantity.abs()>=3) bg=Colors.red[50]!; else if(m.type=='opname' && m.quantity.abs()>=1) bg=Colors.amber[50]!;
                return Container(color: bg, child: ListTile(dense:true, onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: m.productId))), title: Text('${d.productName} • ${m.type}', style: const TextStyle(fontSize:12, fontWeight: FontWeight.bold)), subtitle: Text('${m.date.toString().substring(0,16)} | ${m.quantity>0?'+':''}${m.quantity} | Awal:${m.stockBefore} Akhir:${m.stockAfter} | ${m.referenceNo}', style: const TextStyle(fontSize:10)), trailing: m.type=='opname' && m.quantity.abs()>=2? Icon(Icons.warning, color: m.quantity.abs()>=3? Colors.red : Colors.orange) : null));
              }
            );
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error: $e')),
        ))),
      ]),
    );
  }
}