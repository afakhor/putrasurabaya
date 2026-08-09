import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';
import '../../../../core/utils/config.dart';

final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  return ref.watch(localDatabaseProvider).stockMutationDao.watchKartuStok(productId);
});

final productStreamProvider = StreamProvider.family<ProductData?, String>((ref, id) {
  return ref.watch(localDatabaseProvider).productDao.watchProductById(id);
});

class KartuStockPage extends ConsumerWidget {
  final String productId;
  const KartuStockPage({super.key, required this.productId});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final kartu = ref.watch(kartuStokStreamProvider(productId));
    final prodStream = ref.watch(productStreamProvider(productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Stok'), actions: [
        IconButton(icon: const Icon(Icons.build_circle), onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_)=> AlertDialog(title: const Text('Perbaikan Saldo'), content: const Text('Hitung ulang saldo dari awal?'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Perbaiki'))]));
          if(ok==true){ await ref.read(localDatabaseProvider).stockMutationDao.prosesPerbaikanSaldo(productId); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo diperbaiki'))); }
        })
      ]),
      body: Column(children: [
        prodStream.when(data: (p)=> p==null? const SizedBox(): Padding(padding: const EdgeInsets.all(12), child: GlassCard(child: ListTile(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Stok: ${p.stock} • Rak: ${p.rackLocation??'-'}')))), loading: ()=> const SizedBox(), error: (_,__)=> const SizedBox()),
        Expanded(child: kartu.when(
          data: (list)=> ListView.builder(itemCount: list.length, itemBuilder: (c,i){
            final m=list[i].mutation;
            return ListTile(dense:true, title: Text('${m.type} ${m.quantity>0?'+':''}${m.quantity} - Stok Akhir: ${m.stockAfter}', style: const TextStyle(fontSize:12, fontWeight: FontWeight.bold)), subtitle: Text('${m.date.toString().substring(0,16)} | Ref: ${m.referenceNo} | HPP: ${m.hppSnapshot}', style: const TextStyle(fontSize:10)));
          }),
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('$e'))
        )),
      ]),
    );
  }
}