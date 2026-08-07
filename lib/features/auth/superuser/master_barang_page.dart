import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/providers.dart'; // <-- WAJIB
import '../../../core/utils/config.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';
import 'product/product_page.dart';

// ALIAS biar master_data_page.dart yang manggil const MasterBarangPage() gak error
class MasterBarangPage extends MasterBarangPageFinal {
  const MasterBarangPage({super.key});
}

class MasterBarangPageFinal extends ConsumerStatefulWidget {
  const MasterBarangPageFinal({super.key});
  @override ConsumerState<MasterBarangPageFinal> createState()=> _MasterFinalState();
}

class _MasterFinalState extends ConsumerState<MasterBarangPageFinal> {
  String q='';
  @override Widget build(BuildContext context) {
    final products = ref.watch(productsStreamProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Master Barang - Link Mutasi'), backgroundColor: const Color(0xFF00A65A), actions: [
        IconButton(icon: const Icon(Icons.receipt_long), tooltip: 'Buku Besar', onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
        IconButton(icon: const Icon(Icons.add_box), tooltip: 'Tambah Produk', onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Cari SKU/Nama/Rak', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(data: (list){
          final f = list.where((p)=> p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.rackLocation??'').toLowerCase().contains(q)).toList();
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
            final p=f[i];
            return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: p.stock<=0? Colors.red.withOpacity(0.15): const Color(0xFF00A65A).withOpacity(0.15), child: Icon(Icons.handyman, color: p.stock<=0? Colors.red : const Color(0xFF00A65A))),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily: 'Poppins')),
                subtitle: Text('SKU:${p.code} | Rak:${p.rackLocation??'-'} | Stok:${p.stock} ${p.unit} | HPP:${p.buyPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize:10, fontFamily: 'Poppins')),
                trailing: PopupMenuButton(itemBuilder: (_)=> const [
                  PopupMenuItem(value:'kartu', child: Text('Kartu Stok')),
                  PopupMenuItem(value:'mutasi', child: Text('Lihat di Mutasi')),
                  PopupMenuItem(value:'edit', child: Text('Edit Produk')),
                ], onSelected: (v){
                  if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                  if(v=='mutasi') Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()));
                  if(v=='edit') Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()));
                }),
              ),
            ));
          });
        }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('$e')))),
      ]),
    );
  }
}