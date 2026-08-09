import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart';
import 'kartu_stock_page.dart';

class PersediaanStockBarangPage extends ConsumerStatefulWidget {
  final bool isPickMode;
  const PersediaanStockBarangPage({super.key, this.isPickMode=false});
  @override ConsumerState<PersediaanStockBarangPage> createState()=> _MasterState();
}

class _MasterState extends ConsumerState<PersediaanStockBarangPage> {
  String q='';
  @override Widget build(BuildContext context) {
    final products = ref.watch(StreamProvider((ref)=> ref.watch(localDatabaseProvider).select(ref.watch(localDatabaseProvider).products).watch()));
    return Scaffold(
      appBar: AppBar(title: Text(widget.isPickMode?'Pilih Barang':'Master Barang - Stok Real'), backgroundColor: const Color(0xFF00A65A)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Cari SKU/Nama/Rak', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(data: (list){
          final filtered = list.where((p)=> p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.rackLocation??'').toLowerCase().contains(q)).toList();
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: filtered.length, itemBuilder: (c,i){
            final p=filtered[i];
            Color sc = p.stock<=0? Colors.red : p.stock<=p.minStock? Colors.orange : const Color(0xFF00A65A);
            return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(onTap: () { if(widget.isPickMode){ Navigator.pop(context, p.id); } else { Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))); } }, child: ListTile(leading: CircleAvatar(backgroundColor: sc.withOpacity(0.15), child: Icon(Icons.handyman, color: sc)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)), subtitle: Text('SKU:${p.code??'-'} • ${p.stock} ${p.unit} • Rak:${p.rackLocation??'-'}'), trailing: Text('${p.stock}', style: TextStyle(color: sc, fontWeight: FontWeight.bold)))));
          });
        }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('$e')))),
      ]),
    );
  }
}