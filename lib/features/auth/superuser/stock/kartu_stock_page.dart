import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart';

// PROVIDER YANG HILANG
final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  return ref.watch(localDatabaseProvider).stockMutationDao.watchKartuStok(productId);
});

class KartuStockPage extends ConsumerWidget {
  final String productId;
  const KartuStockPage({super.key, required this.productId});
  // Alias biar file lama yang manggil KartuStokPage tetap jalan
  @override Widget build(BuildContext context, WidgetRef ref) {
    final kartu = ref.watch(kartuStokStreamProvider(productId));
    final prodStream = ref.watch(productStreamProvider(productId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Stok'), actions: [
        IconButton(icon: const Icon(Icons.build_circle), tooltip: 'Perbaikan Saldo', onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_)=> AlertDialog(title: const Text('Perbaikan Saldo'), content: const Text('Hitung ulang dari awal by date?'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Perbaiki'))]));
          if(ok==true){ await ref.read(localDatabaseProvider).stockMutationDao.prosesPerbaikanSaldo(productId); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo diperbaiki'))); }
        })
      ]),
      body: Column(children: [
        prodStream.when(
          data: (p)=> p==null? const SizedBox(): Padding(
            padding: const EdgeInsets.all(12),
            child: GlassCard(child: ListTile(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Stok: ${p.stock} | HPP: ${p.buyPrice} | Rak: ${p.rackLocation}'))),
          ), 
          loading: ()=> const SizedBox(), 
          error: (_,__)=> const SizedBox()
        ),
        // ... sisa ListView kamu tetap, pakai kartu.when seperti sebelumnya
        Expanded(child: kartu.when(
          data: (list){
            return ListView.builder(itemCount: list.length, itemBuilder: (c,i){
              final m=list[i].mutation;
              Color bg=Colors.white; if(m.stockAfter<0) bg=Colors.red[100]!; else if(m.type=='OPNAME' && m.quantity.abs()>=3) bg=Colors.red[50]!;
              return Container(color: bg, padding: const EdgeInsets.symmetric(horizontal:12,vertical:6), child: Row(children: [
                Expanded(flex:3, child: Text(m.date.toString().substring(0,16), style: const TextStyle(fontSize:10))),
                Expanded(child: Text(m.stockBefore.toStringAsFixed(0), style: const TextStyle(fontSize:10))),
                Expanded(child: Text('${m.quantity>0?'+':''}${m.quantity.toStringAsFixed(0)}', style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: m.quantity>0? Colors.green : Colors.red))),
                Expanded(child: Text(m.stockAfter.toStringAsFixed(0), style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold))),
                Expanded(child: Text(m.hppSnapshot.toStringAsFixed(0), style: const TextStyle(fontSize:10))),
              ]));
            });
          },
          loading: ()=> const Center(child: CircularProgressIndicator()), 
          error: (e,s)=> Center(child: Text('$e'))
        )),
      ]),
    );
  }
}
// COMPATIBILITY ALIAS
class KartuStokPage extends KartuStockPage {
  const KartuStokPage({super.key, required super.productId});
}