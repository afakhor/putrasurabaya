import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'kartu_stock_page.dart';

class PersediaanStockBarangPage extends ConsumerStatefulWidget {
  final bool isPickMode;
  const PersediaanStockBarangPage({super.key, this.isPickMode=false});
  @override ConsumerState<PersediaanStockBarangPage> createState()=> _MasterState();
}

class _MasterState extends ConsumerState<PersediaanStockBarangPage> {
  String q='';
  @override Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isPickMode?'Pilih Barang':'Master Barang'), backgroundColor: const Color(0xFF00A65A)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Smart Search: SKU/Nama/Rak/Brand/Barcode', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: productsAsync.when(
          data: (list){
            final filtered = list.where((p){
              if(q.isEmpty) return true;
              return p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.barcode??'').toLowerCase().contains(q) || (p.rackLocation??'').toLowerCase().contains(q) || (p.brand??'').toLowerCase().contains(q) || (p.tags??'').toLowerCase().contains(q);
            }).toList();
            if(filtered.isEmpty) return const Center(child: Text('Barang tidak ada, tambah dulu'));
            return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: filtered.length, itemBuilder: (c,i){
              final p=filtered[i];
              Color sc = p.stock<=0? Colors.red : p.stock<=p.minStock? Colors.orange : const Color(0xFF00A65A);
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: sc.withOpacity(0.15), child: Icon(Icons.handyman, color: sc)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
                subtitle: Text('SKU:${p.code??'-'} • ${p.stock} ${p.unit} • Rak:${p.rackLocation??'-'} • HPP:${p.buyPrice.toStringAsFixed(0)}'),
                trailing: widget.isPickMode? const Icon(Icons.chevron_right) : PopupMenuButton(onSelected: (v) async {
                  if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                  if(v=='hapus') ref.read(localDatabaseProvider).productDao.softDeleteProduct(p.id);
                  if(v=='edit') Navigator.pop(context, p.id);
                }, itemBuilder: (_)=> [const PopupMenuItem(value:'edit', child: Text('Edit')), const PopupMenuItem(value:'kartu', child: Text('Kartu Stok')), const PopupMenuItem(value:'hapus', child: Text('Hapus'))]),
                onTap: () { if(widget.isPickMode) Navigator.pop(context, p.id); else Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))); },
              ));
            });
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error: $e')),
        )),
      ]),
    );
  }
}