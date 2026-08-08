import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';
import '../../../core/utils/format_rupiah.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';
import 'product/product_page.dart';

class MasterBarangPage extends StatelessWidget {
  const MasterBarangPage({super.key});
  @override Widget build(BuildContext context) => const MasterBarangPageFinal();
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
      appBar: AppBar(
        title: const Text('Master Barang - Link Mutasi'),
        backgroundColor: const Color(0xFF00A65A),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
          IconButton(icon: const Icon(Icons.add_box), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()))),
        ]
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Cari SKU/Nama/Rak', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(data: (list){
          final f = list.where((p)=> p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q)).toList();
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
            final p=f[i];
            return Padding(
              padding: const EdgeInsets.only(bottom:8),
              child: GlassCard(
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.handyman)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily:'Poppins')),
                  // BEDANYA DISINI
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKU:${p.code} | Rak:${p.rackLocation??'-'} | Stok:${p.stock}', style: const TextStyle(fontSize:10)),
                      const SizedBox(height:4),
                      // HARGA JUAL LAMA
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal:6, vertical:2),
                        decoration: BoxDecoration(color: const Color(0xFF00A65A).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('Jual Umum: ${formatRupiah(p.sellPriceGeneral)}', style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: Color(0xFF00A65A), fontFamily:'Poppins')),
                      ),
                      const SizedBox(height:3),
                      // HARGA TIER 1,2,3
                      Text('Tier 1:${formatRupiah(p.sellPriceTier1)} | T2:${formatRupiah(p.sellPriceTier2)} | T3:${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize:9, color: Colors.orange, fontWeight: FontWeight.bold, fontFamily:'Poppins')),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (_)=> const [
                      PopupMenuItem(value:'kartu', child: Text('Kartu Stok')),
                      PopupMenuItem(value:'edit', child: Text('Edit Harga Tier')),
                      PopupMenuItem(value:'mutasi', child: Text('Buku Besar'))
                    ],
                    onSelected: (v){
                      if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                      if(v=='edit') Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()));
                      if(v=='mutasi') Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()));
                    }
                  )
                )
              )
            );
          });
        }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('$e')))),
      ]),
    );
  }
}