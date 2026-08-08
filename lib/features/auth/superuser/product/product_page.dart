import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart';
import '../../../../core/utils/format_rupiah.dart';
import 'master_fab_perkakas.dart';
import 'product_form_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

// HAPUS allProductsStreamProvider DARI SINI - PAKAI YANG GLOBAL DARI local_database.dart
// final allProductsStreamProvider = ... <-- INI PENYEBAB LOADING MUTER TERUS KEMARIN

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override void dispose(){ _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }
  void _onSearchChanged(String q){ _debounce?.cancel(); _debounce=Timer(const Duration(milliseconds: 300), ()=> ref.read(searchQueryProvider.notifier).state=q.toLowerCase()); }

  Future<void> _openForm(BuildContext context, {ProductData? product}) async {
    final notifier=ref.read(productFormProvider.notifier);
    final db=ref.read(localDatabaseProvider);
    if(product!=null){
      final units=await (db.select(db.productUnits)..where((t)=> t.productId.equals(product.id))).get();
      final variants=await (db.select(db.productVariants)..where((t)=> t.productId.equals(product.id))).get();
      final assets=await (db.select(db.productAssets)..where((t)=> t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e)=> e.imagePath).toList());
    }else{ notifier.resetForm(); }
    if(context.mounted){
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx)=> FractionallySizedBox(heightFactor: 0.92, child: const FormMasterBarangSheet()));
    }
  }

  @override Widget build(BuildContext context){
    final query=ref.watch(searchQueryProvider);
    final productsAsync=ref.watch(allProductsStreamProvider); // DARI local_database.dart GLOBAL - CUMA 1
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: productsAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('Error: $e')),
        data: (raw){
          var filtered=raw.where((p)=> p.name.toLowerCase().contains(query) || (p.code??'').toLowerCase().contains(query)).toList();
          if(filtered.isEmpty) return const Center(child: Text('Belum ada produk'));
          return Column(children: [
            GlassCard(radius:0, padding: const EdgeInsets.all(12), child: TextField(controller: _searchCtrl, onChanged: _onSearchChanged, decoration: InputDecoration(hintText:'Cari Perkakas...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled:true, fillColor: Colors.white.withOpacity(0.9)))),
            Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: filtered.length, itemBuilder: (c,i){
              final p=filtered[i];
              return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(padding: const EdgeInsets.all(12), onTap: ()=> _openForm(context, product: p), child: Row(children: [
                Container(width:42,height:42,decoration: BoxDecoration(color: const Color(0xFF00A65A).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.handyman, color: Color(0xFF00A65A))),
                const SizedBox(width:10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily:'Poppins')),
                  Text('HPP:${formatRupiah(p.buyPrice)} | Umum:${formatRupiah(p.sellPriceGeneral)} | Stok:${p.stock} ${p.unit}', style: const TextStyle(fontSize:9, color: Colors.black54)),
                  Text('T1:${formatRupiah(p.sellPriceTier1)} T2:${formatRupiah(p.sellPriceTier2)} T3:${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize:9, color: Colors.black54)),
                ])),
              ])));
            })),
          ]);
        },
      ),
      floatingActionButton: MasterFabPerkakas(onOpenForm: (ctx,{product})=> _openForm(ctx, product: product)),
    );
  }
}

class FormMasterBarangSheet extends ConsumerStatefulWidget {
  const FormMasterBarangSheet({super.key});
  @override ConsumerState<FormMasterBarangSheet> createState()=> _FormMasterBarangSheetState();
}

class _FormMasterBarangSheetState extends ConsumerState<FormMasterBarangSheet> {
  Color _marginColor(double m){ if(m<0) return Colors.red.shade700; if(m<10) return Colors.red; if(m<20) return Colors.orange; return const Color(0xFF00A65A); }
  Widget _buildHargaInput({required String label, required double harga, required double margin, required double laba, required Function(double) onChanged, Color? labelColor}){
    final col=_marginColor(margin);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(initialValue: harga==0?'':harga.toStringAsFixed(0), keyboardType: TextInputType.number,
        style: TextStyle(fontFamily:'Poppins', fontWeight: FontWeight.bold, fontSize:13, color: labelColor??Colors.black87),
        decoration: InputDecoration(labelText: label, prefixText:'Rp ', border: const OutlineInputBorder(),
          suffixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
            decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: col.withOpacity(0.3))),
            child: Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize:11,fontWeight: FontWeight.bold,color: col)))),
        onChanged: (v)=> onChanged(double.tryParse(v)??0)),
      const SizedBox(height:4),
      Row(children: [Icon(margin<0?Icons.warning:Icons.trending_up,size:12,color: col), const SizedBox(width:4), Text('Laba ${formatRupiah(laba)} • Margin ${margin.toStringAsFixed(1)}% • HPP ${formatRupiah(ref.read(productFormProvider).buyPrice)}', style: TextStyle(fontSize:10,color: col)))]),
      const SizedBox(height:12),
    ]);
  }
  @override Widget build(BuildContext context){
    final state=ref.watch(productFormProvider); final notifier=ref.read(productFormProvider.notifier);
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text(state.isEditMode?'Edit ${state.name}':'Tambah Perkakas Baru', style: const TextStyle(fontSize:14,fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if(state.isEditMode) Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Text('HPP Auto: ${formatRupiah(state.buyPrice)} dari Pembelian (Weighted Average)', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold, color: Colors.blue))),
        const SizedBox(height:12),
        TextFormField(initialValue: state.name, decoration: const InputDecoration(labelText:'Nama Barang *', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(name: v)),
        const SizedBox(height:12),
        TextFormField(initialValue: state.buyPrice==0?'':state.buyPrice.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'HPP / Harga Beli (Auto dari Pembelian)', prefixText:'Rp ', border: OutlineInputBorder(), filled:true, fillColor: Color(0xFFF5F5F5)), onChanged: (v)=> notifier.updateField(buyPrice: double.tryParse(v)??0)),
        const SizedBox(height:16),
        const Divider(), const Text('HARGA JUAL - MUNCUL % DARI HPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12, color: Color(0xFF007F00))),
        const SizedBox(height:12),
        _buildHargaInput(label:'Harga Jual Umum *', harga: state.sellPriceGeneral, margin: state.marginGeneral, laba: state.labaGeneral, onChanged: (v)=> notifier.updateField(sellPriceGeneral: v), labelColor: const Color(0xFF00A65A)),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('HARGA TIER GROSIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11, color: Colors.orange)),
          const SizedBox(height:12),
          _buildHargaInput(label:'Tier 1 - Ecer Member', harga: state.sellPriceTier1, margin: state.marginTier1, laba: state.labaTier1, onChanged: (v)=> notifier.updateField(sellPriceTier1: v)),
          _buildHargaInput(label:'Tier 2 - Grosir (>10)', harga: state.sellPriceTier2, margin: state.marginTier2, laba: state.labaTier2, onChanged: (v)=> notifier.updateField(sellPriceTier2: v)),
          _buildHargaInput(label:'Tier 3 - Distributor (>50)', harga: state.sellPriceTier3, margin: state.marginTier3, laba: state.labaTier3, onChanged: (v)=> notifier.updateField(sellPriceTier3: v)),
        ])),
        const SizedBox(height:20),
        SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { final ok=await notifier.saveProduct(); if(ok && context.mounted) Navigator.pop(context); }, child: Text(state.isEditMode?'UPDATE HARGA':'SIMPAN', style: const TextStyle(color:Colors.white,fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}