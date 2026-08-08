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
      appBar: AppBar(title: const Text('Master Barang - Tier'), backgroundColor: const Color(0xFF00A65A), actions: [
        IconButton(icon: const Icon(Icons.receipt_long), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
        IconButton(icon: const Icon(Icons.add_box), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Cari SKU/Nama/Rak', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(
          data: (list){
            final f = list.where((p)=> p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q)).toList();
            return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
              final p=f[i];
              return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))), child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.handyman)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily:'Poppins')),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SKU:${p.code} | Stok:${p.stock} | HPP:${formatRupiah(p.buyPrice)}', style: const TextStyle(fontSize:10)),
                  const SizedBox(height:2),
                  Text('Umum:${formatRupiah(p.sellPriceGeneral)} | T1:${formatRupiah(p.sellPriceTier1)} T2:${formatRupiah(p.sellPriceTier2)} T3:${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize:9, color: Colors.orange, fontWeight: FontWeight.bold)),
                ]),
              )));
            });
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error: $e')),
        )),
      ]),
    );
  }
}