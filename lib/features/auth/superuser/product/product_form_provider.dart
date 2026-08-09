// lib/features/auth/superuser/product/product_form_provider.dart - FINAL BUILD OK
import 'package:flutter/material.dart' as mat;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
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
  void setProduct(ProductData p, List<ProductUnitData> u, List<ProductVariantData> v, List<String> img){ state=ProductFormState(id: p.id, name: p.name, code: p.code??'', buyPrice: p.buyPrice, sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1, sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3, selectedProductId: p.id); }
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
  mat.Color _marginColor(double m){ if(m<0) return mat.Colors.red.shade700; if(m<10) return mat.Colors.red; if(m<20) return mat.Colors.orange; return const mat.Color(0xFF00A65A); }
  mat.Widget _buildHargaInput({required String label, required double harga, required double margin, required double laba, required Function(double) onChanged}){
    final col=_marginColor(margin);
    return mat.Column(crossAxisAlignment: mat.CrossAxisAlignment.start, children: [
      mat.TextFormField(initialValue: harga==0?'':harga.toStringAsFixed(0), keyboardType: mat.TextInputType.number,
        decoration: mat.InputDecoration(labelText: label, prefixText:'Rp ', border: const mat.OutlineInputBorder(),
          suffixIcon: mat.Container(margin: const mat.EdgeInsets.all(8), padding: const mat.EdgeInsets.symmetric(horizontal:8,vertical:4),
            decoration: mat.BoxDecoration(color: col.withOpacity(0.15), borderRadius: mat.BorderRadius.circular(8)), child: mat.Text('${margin.toStringAsFixed(1)}% HPP', style: mat.TextStyle(fontSize:11,fontWeight: mat.FontWeight.bold,color: col)))),
        onChanged: (v)=> onChanged(double.tryParse(v)??0)),
      const mat.SizedBox(height:4),
      mat.Text('Laba ${formatRupiah(laba)} • Margin ${margin.toStringAsFixed(1)}% dari HPP ${formatRupiah(ref.read(productFormProvider).buyPrice)}', style: mat.TextStyle(fontSize:10,color: col)),
      const mat.SizedBox(height:12),
    ]);
  }
  @override mat.Widget build(mat.BuildContext context){
    final state=ref.watch(productFormProvider);
    final notifier=ref.read(productFormProvider.notifier);
    final productsAsync = ref.watch(allProductsStreamProvider);
    return mat.Scaffold(backgroundColor: mat.Colors.white,
      appBar: mat.AppBar(backgroundColor: mat.Colors.white, title: const mat.Text('Edit Harga Jual & Tier', style: mat.TextStyle(fontSize:14,fontWeight: mat.FontWeight.bold)), actions: [mat.IconButton(icon: const mat.Icon(mat.Icons.close), onPressed: ()=> mat.Navigator.pop(context))]),
      body: mat.ListView(padding: const mat.EdgeInsets.all(16), children: [
        const mat.Text('Pilih Barang / SKU', style: mat.TextStyle(fontWeight: mat.FontWeight.bold, fontSize:12)),
        const mat.SizedBox(height:8),
        productsAsync.when(data: (list)=> mat.DropdownButtonFormField<String>(value: state.selectedProductId, decoration: const mat.InputDecoration(labelText:'Pilih SKU / Barang', border: mat.OutlineInputBorder()),
          items: list.map((p)=> mat.DropdownMenuItem(value: p.id, child: mat.Text('${p.code} - ${p.name}', style: const mat.TextStyle(fontSize:12), overflow: mat.TextOverflow.ellipsis))).toList(),
          onChanged: (id){ final prod = list.firstWhere((e)=> e.id==id); notifier.selectProduct(prod); }), loading: ()=> const mat.CircularProgressIndicator(), error: (e,s)=> mat.Text('Error $e')),
        const mat.SizedBox(height:16),
        if(state.id.isNotEmpty)...[
          mat.Container(padding: const mat.EdgeInsets.all(12), decoration: mat.BoxDecoration(color: mat.Colors.blue.withOpacity(0.08), borderRadius: mat.BorderRadius.circular(8)),
            child: mat.Column(crossAxisAlignment: mat.CrossAxisAlignment.start, children: [mat.Text('${state.code} - ${state.name}', style: const mat.TextStyle(fontWeight: mat.FontWeight.bold)), mat.Text('HPP Saat Ini: ${formatRupiah(state.buyPrice)} (Auto Weighted)', style: const mat.TextStyle(fontSize:11, color: mat.Colors.blue)) ])),
          const mat.SizedBox(height:16),
          _buildHargaInput(label:'Harga Jual Umum *', harga: state.sellPriceGeneral, margin: state.marginGeneral, laba: state.labaGeneral, onChanged: (v)=> notifier.updateField(sellPriceGeneral: v)),
          _buildHargaInput(label:'Tier 1 - Member', harga: state.sellPriceTier1, margin: state.marginTier1, laba: state.labaTier1, onChanged: (v)=> notifier.updateField(sellPriceTier1: v)),
          _buildHargaInput(label:'Tier 2 - Grosir (>10)', harga: state.sellPriceTier2, margin: state.marginTier2, laba: state.labaTier2, onChanged: (v)=> notifier.updateField(sellPriceTier2: v)),
          _buildHargaInput(label:'Tier 3 - Distributor (>50)', harga: state.sellPriceTier3, margin: state.marginTier3, laba: state.labaTier3, onChanged: (v)=> notifier.updateField(sellPriceTier3: v)),
          const mat.SizedBox(height:20),
          mat.SizedBox(width: double.infinity, height:48, child: mat.ElevatedButton(style: mat.ElevatedButton.styleFrom(backgroundColor: const mat.Color(0xFF00A65A)), onPressed: () async { final ok=await notifier.saveProduct(); if(ok && context.mounted) mat.Navigator.pop(context); }, child: const mat.Text('UPDATE HARGA', style: mat.TextStyle(color:mat.Colors.white,fontWeight: mat.FontWeight.bold)))),
        ] else const mat.Padding(padding: mat.EdgeInsets.all(20), child: mat.Center(child: mat.Text('Pilih barang dulu untuk edit harga', style: mat.TextStyle(color: mat.Colors.grey)))),
      ]),
    );
  }
}