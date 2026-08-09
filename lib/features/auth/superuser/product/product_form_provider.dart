// lib/features/auth/superuser/product/product_form_provider.dart - JADI EDIT HARGA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/format_rupiah.dart';

class ProductFormState {
  final String id; final String name; final String code; final double buyPrice;
  final double sellPriceGeneral; final double sellPriceTier1; final double sellPriceTier2; final double sellPriceTier3;
  final String? selectedProductId;
  ProductFormState({required this.id, this.name='', this.code='', this.buyPrice=0, this.sellPriceGeneral=0, this.sellPriceTier1=0, this.sellPriceTier2=0, this.sellPriceTier3=0, this.selectedProductId});
  double marginPercent(double jual) => (buyPrice<=0||jual<=0)?0:((jual-buyPrice)/jual)*100;
  double laba(double jual) => jual-buyPrice;
  double get marginGeneral => marginPercent(sellPriceGeneral);
  double get marginTier1 => marginPercent(sellPriceTier1);
  double get marginTier2 => marginPercent(sellPriceTier2);
  double get marginTier3 => marginPercent(sellPriceTier3);
  double get labaGeneral => laba(sellPriceGeneral);
  double get labaTier1 => laba(sellPriceTier1);
  double get labaTier2 => laba(sellPriceTier2);
  double get labaTier3 => laba(sellPriceTier3);
  ProductFormState copyWith({String? id, name, code, double? buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3, String? selectedProductId})=> ProductFormState(id: id??this.id, name: name??this.name, code: code??this.code, buyPrice: buyPrice??this.buyPrice, sellPriceGeneral: sellPriceGeneral??this.sellPriceGeneral, sellPriceTier1: sellPriceTier1??this.sellPriceTier1, sellPriceTier2: sellPriceTier2??this.sellPriceTier2, sellPriceTier3: sellPriceTier3??this.sellPriceTier3, selectedProductId: selectedProductId??this.selectedProductId);
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final LocalDatabase _db;
  ProductFormNotifier(this._db) : super(ProductFormState(id: ''));
  void setProduct(ProductData p, List<ProductUnitData> u, List<ProductVariantData> v, List<String> img){
    state=ProductFormState(id: p.id, name: p.name, code: p.code??'', buyPrice: p.buyPrice, sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1, sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3, selectedProductId: p.id);
  }
  void resetForm(){ state=ProductFormState(id: ''); }
  void selectProduct(ProductData p){ state=ProductFormState(id: p.id, name: p.name, code: p.code??'', buyPrice: p.buyPrice, sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1, sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3, selectedProductId: p.id); }
  void updateField({double? sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3}){ state=state.copyWith(sellPriceGeneral: sellPriceGeneral, sellPriceTier1: sellPriceTier1, sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3); }
  Future<bool> saveProduct() async {
    if(state.id.isEmpty) return false;
    await (_db.update(_db.products)..where((t)=> t.id.equals(state.id))).write(ProductsCompanion(
      sellPriceGeneral: Value(state.sellPriceGeneral), sellPrice: Value(state.sellPriceGeneral),
      sellPriceTier1: Value(state.sellPriceTier1), sellPriceTier2: Value(state.sellPriceTier2), sellPriceTier3: Value(state.sellPriceTier3),
      updatedAt: Value(DateTime.now()), isSynced: const Value(false),
    ));
    return true;
  }
}
final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref){ final db=ref.watch(localDatabaseProvider); return ProductFormNotifier(db); });

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
            decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${margin.toStringAsFixed(1)}% HPP', style: TextStyle(fontSize:11,fontWeight: FontWeight.bold,color: col)))),
        onChanged: (v)=> onChanged(double.tryParse(v)??0)),
      const SizedBox(height:4),
      Text('Laba ${formatRupiah(laba)} • Margin ${margin.toStringAsFixed(1)}% dari HPP ${formatRupiah(ref.read(productFormProvider).buyPrice)}', style: TextStyle(fontSize:10,color: col)),
      const SizedBox(height:12),
    ]);
  }
  @override Widget build(BuildContext context){
    final state=ref.watch(productFormProvider);
    final notifier=ref.read(productFormProvider.notifier);
    final productsAsync = ref.watch(allProductsStreamProvider);
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('Edit Harga Jual & Tier', style: TextStyle(fontSize:14,fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Pilih Barang / SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
        const SizedBox(height:8),
        productsAsync.when(data: (list)=> DropdownButtonFormField<String>(value: state.selectedProductId, decoration: const InputDecoration(labelText:'Pilih SKU / Barang', border: OutlineInputBorder()),
          items: list.map((p)=> DropdownMenuItem(value: p.id, child: Text('${p.code} - ${p.name}', style: const TextStyle(fontSize:12), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (id){ final prod = list.firstWhere((e)=> e.id==id); notifier.selectProduct(prod); }), loading: ()=> const CircularProgressIndicator(), error: (e,s)=> Text('Error $e')),
        const SizedBox(height:16),
        if(state.id.isNotEmpty)...[
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${state.code} - ${state.name}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('HPP Saat Ini: ${formatRupiah(state.buyPrice)} (Auto Weighted)', style: const TextStyle(fontSize:11, color: Colors.blue)) ])),
          const SizedBox(height:16),
          _buildHargaInput(label:'Harga Jual Umum *', harga: state.sellPriceGeneral, margin: state.marginGeneral, laba: state.labaGeneral, onChanged: (v)=> notifier.updateField(sellPriceGeneral: v)),
          _buildHargaInput(label:'Tier 1 - Member', harga: state.sellPriceTier1, margin: state.marginTier1, laba: state.labaTier1, onChanged: (v)=> notifier.updateField(sellPriceTier1: v)),
          _buildHargaInput(label:'Tier 2 - Grosir (>10)', harga: state.sellPriceTier2, margin: state.marginTier2, laba: state.labaTier2, onChanged: (v)=> notifier.updateField(sellPriceTier2: v)),
          _buildHargaInput(label:'Tier 3 - Distributor (>50)', harga: state.sellPriceTier3, margin: state.marginTier3, laba: state.labaTier3, onChanged: (v)=> notifier.updateField(sellPriceTier3: v)),
          const SizedBox(height:20),
          SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { final ok=await notifier.saveProduct(); if(ok && context.mounted) Navigator.pop(context); }, child: const Text('UPDATE HARGA', style: TextStyle(color:Colors.white,fontWeight: FontWeight.bold)))),
        ] else const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Pilih barang dulu untuk edit harga', style: TextStyle(color: Colors.grey)))),
      ]),
    );
  }
}