import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart';
import '../../../../core/utils/format_rupiah.dart';
import 'master_fab_perkakas.dart';
import 'product_form_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override void dispose(){ _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }
  void _onSearchChanged(String q){ _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 300), (){ ref.read(searchQueryProvider.notifier).state = q.toLowerCase().trim(); }); }

  Future<void> _openForm(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);
    if (product!= null) {
      final units = await (db.select(db.productUnits)..where((t) => t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t) => t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t) => t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e) => e.imagePath).toList());
    } else {
      notifier.resetForm();
    }
    if (context.mounted) {
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const FractionallySizedBox(heightFactor: 0.92, child: FormMasterBarangSheet()));
    }
  }

  @override Widget build(BuildContext context){
    final query = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: productsAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))),
        error: (e,s)=> Center(child: Text('Error DB: $e')),
        data: (List<ProductData> raw){
          var filtered = raw.where((ProductData p){
            if(query.isEmpty) return true;
            final nameOk = p.name.toLowerCase().contains(query);
            final code = p.code.toLowerCase();
            return nameOk || code.contains(query);
          }).toList();
          return Column(children: [
            Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12,12,12,8),
              child: TextField(controller: _searchCtrl, onChanged: _onSearchChanged,
                decoration: InputDecoration(hintText: 'Cari Perkakas / SKU...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)),
                  suffixIcon: query.isNotEmpty? IconButton(icon: const Icon(Icons.clear), onPressed: (){ _searchCtrl.clear(); ref.read(searchQueryProvider.notifier).state=''; }) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled:true, fillColor: const Color(0xFFF5F5F5)))),
            if(filtered.isEmpty) const Expanded(child: Center(child: Text('Belum ada produk')))
            else Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12,8,12,90), itemCount: filtered.length, itemBuilder: (c,i){
              final ProductData p=filtered[i]; final lowStock = p.stock <= p.minStock;
              return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(padding: const EdgeInsets.all(12), onTap: ()=> _openForm(context, product: p),
                child: Row(children: [
                  Container(width:42,height:42, decoration: BoxDecoration(color: lowStock? Colors.red.withOpacity(0.12) : const Color(0xFF00A65A).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(lowStock? Icons.warning_amber : Icons.handyman, color: lowStock? Colors.red : const Color(0xFF00A65A))),
                  const SizedBox(width:10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${p.code} - ${p.name}', maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
                    Text('HPP:${formatRupiah(p.buyPrice)} | Umum:${formatRupiah(p.sellPriceGeneral??0)} | Stok:${p.stock}', style: TextStyle(fontSize:9, color: lowStock? Colors.red : Colors.black54)),
                    Text('T1:${formatRupiah(p.sellPriceTier1??0)} T2:${formatRupiah(p.sellPriceTier2??0)} T3:${formatRupiah(p.sellPriceTier3??0)}', style: const TextStyle(fontSize:9, color: Colors.black54)),
                  ])),
                  const Icon(Icons.chevron_right, size:16, color: Colors.grey),
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
  Widget _buildHargaInput({required String label, required double harga, required double margin, required double laba, required Function(double) onChanged}){
    final col=_marginColor(margin);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(initialValue: harga==0?'':harga.toStringAsFixed(0), keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, prefixText:'Rp ', border: const OutlineInputBorder(),
          suffixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
            decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize:11,fontWeight: FontWeight.bold,color: col)))),
        onChanged: (v)=> onChanged(double.tryParse(v)??0)),
      const SizedBox(height:4),
      Text('Laba ${formatRupiah(laba)} • Margin ${margin.toStringAsFixed(1)}% • HPP ${formatRupiah(ref.read(productFormProvider).buyPrice)}', style: TextStyle(fontSize:10,color: col)),
      const SizedBox(height:12),
    ]);
  }

  @override Widget build(BuildContext context){
    final state=ref.watch(productFormProvider);
    final notifier=ref.read(productFormProvider.notifier);
    final allProducts = ref.watch(allProductsStreamProvider);

    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text(state.isEditMode? 'Edit Harga Jual Barang' : 'Edit Harga Jual Barang', style: const TextStyle(fontSize:14,fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Pilih Barang Master (Index SKU)', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
        const SizedBox(height:8),
        allProducts.when(
          data: (List<ProductData> list)=> DropdownButtonFormField<String>(
            value: state.id.isEmpty? null : list.any((e)=> e.id==state.id)? state.id : null,
            decoration: const InputDecoration(labelText:'Pilih Nama Barang / SKU dari Master *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
            items: list.map((ProductData p)=> DropdownMenuItem<String>(value: p.id, child: Text('${p.code} - ${p.name} (HPP:${formatRupiah(p.buyPrice)})', style: const TextStyle(fontSize:11), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (id) async {
              if(id==null) return;
              final db = ref.read(localDatabaseProvider);
              final prod = await db.productDao.getProductById(id);
              if(prod!=null){
                final units = await (db.select(db.productUnits)..where((t)=> t.productId.equals(prod.id))).get();
                final variants = await (db.select(db.productVariants)..where((t)=> t.productId.equals(prod.id))).get();
                final assets = await (db.select(db.productAssets)..where((t)=> t.productId.equals(prod.id))).get();
                notifier.setProduct(prod, units, variants, assets.map((e)=> e.imagePath).toList());
              }
            },
          ),
          loading: ()=> const LinearProgressIndicator(),
          error: (e,s)=> Text('Error $e'),
        ),
        const SizedBox(height:12),
        if(state.id.isNotEmpty)
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${state.code} - ${state.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
              const SizedBox(height:4),
              Text('HPP Auto: ${formatRupiah(state.buyPrice)} (dari Pembelian Weighted Avg) • Stok: ${state.stock} • Rak: ${state.rackLocation}', style: const TextStyle(fontSize:11, color: Colors.blue)),
            ])),
        const SizedBox(height:16),
        const Divider(),
        const Text('HARGA JUAL - MARGIN % DARI HPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12, color: Color(0xFF007F00))),
        const SizedBox(height:12),
        if(state.id.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Pilih barang master dulu di atas', style: TextStyle(color: Colors.grey))))
        else...[
          _buildHargaInput(label:'Harga Jual Umum *', harga: state.sellPriceGeneral, margin: state.marginGeneral, laba: state.labaGeneral, onChanged: (v)=> notifier.updateField(sellPriceGeneral: v)),
          _buildHargaInput(label:'Tier 1 - Ecer Member', harga: state.sellPriceTier1, margin: state.marginTier1, laba: state.labaTier1, onChanged: (v)=> notifier.updateField(sellPriceTier1: v)),
          _buildHargaInput(label:'Tier 2 - Grosir (>10)', harga: state.sellPriceTier2, margin: state.marginTier2, laba: state.labaTier2, onChanged: (v)=> notifier.updateField(sellPriceTier2: v)),
          _buildHargaInput(label:'Tier 3 - Distributor (>50)', harga: state.sellPriceTier3, margin: state.marginTier3, laba: state.labaTier3, onChanged: (v)=> notifier.updateField(sellPriceTier3: v)),
          const SizedBox(height:20),
          SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { final ok=await notifier.saveProduct(); if(ok && context.mounted) Navigator.pop(context); }, child: const Text('UPDATE HARGA JUAL', style: TextStyle(color:Colors.white,fontWeight: FontWeight.bold)))),
        ]
      ]),
    );
  }
}