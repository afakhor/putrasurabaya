import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/local_database.dart';

// MODEL
class VariantMatrixModel { final String id, sku, name; final double sellPrice; VariantMatrixModel({required this.id, required this.sku, required this.name, this.sellPrice=0}); }
class UnitConversionModel { final String id, unitName; final int conversion; final double buyPrice, sellPrice; UnitConversionModel({required this.id, required this.unitName, required this.conversion, required this.buyPrice, required this.sellPrice}); }

class ProductFormState {
  final String id, name, shortName, barcode, description, categoryId, brand, warehouseLocation, tags;
  final double buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3;
  final double baseStock, minStock; final bool isPriceLocked, isLoading;
  ProductFormState({required this.id, this.name='', this.shortName='', this.barcode='', this.description='', this.categoryId='Umum', this.brand='', this.warehouseLocation='', this.tags='', this.buyPrice=0, this.sellPriceGeneral=0, this.sellPriceTier1=0, this.sellPriceTier2=0, this.sellPriceTier3=0, this.baseStock=0, this.minStock=5, this.isPriceLocked=true, this.isLoading=false});
  double get marginGeneralPercent => (sellPriceGeneral<=0||buyPrice<=0)?0:((sellPriceGeneral-buyPrice)/sellPriceGeneral)*100;
  ProductFormState copyWith({String? id, name, shortName, barcode, description, categoryId, brand, warehouseLocation, tags, double? buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3, baseStock, minStock, bool? isPriceLocked, isLoading})=>ProductFormState(id:id??this.id,name:name??this.name,shortName:shortName??this.shortName,barcode:barcode??this.barcode,description:description??this.description,categoryId:categoryId??this.categoryId,brand:brand??this.brand,warehouseLocation:warehouseLocation??this.warehouseLocation,tags:tags??this.tags,buyPrice:buyPrice??this.buyPrice,sellPriceGeneral:sellPriceGeneral??this.sellPriceGeneral,sellPriceTier1:sellPriceTier1??this.sellPriceTier1,sellPriceTier2:sellPriceTier2??this.sellPriceTier2,sellPriceTier3:sellPriceTier3??this.sellPriceTier3,baseStock:baseStock??this.baseStock,minStock:minStock??this.minStock,isPriceLocked:isPriceLocked??this.isPriceLocked,isLoading:isLoading??this.isLoading);
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier(): super(ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}'));
  void resetForm()=> state = ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}');
  void updateFields({String? name, shortName, barcode, description, categoryId, brand, warehouseLocation, tags, double? buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3, baseStock, minStock, bool? isPriceLocked}){ state = state.copyWith(name:name, shortName:shortName, barcode:barcode, description:description, categoryId:categoryId, brand:brand, warehouseLocation:warehouseLocation, tags:tags, buyPrice:buyPrice, sellPriceGeneral:sellPriceGeneral, sellPriceTier1:sellPriceTier1, sellPriceTier2:sellPriceTier2, sellPriceTier3:sellPriceTier3, baseStock:baseStock, minStock:minStock, isPriceLocked:isPriceLocked); }
  void loadFromProductData(ProductData d){ state = ProductFormState(id:d.id, name:d.name, shortName:d.shortName??'', barcode:d.barcode??'', description:d.description??'', categoryId:d.categoryId??'Umum', brand:d.brand??'', warehouseLocation:d.warehouseLocation??'', tags:d.tags??'', buyPrice:d.buyPrice, sellPriceGeneral:d.sellPriceGeneral, sellPriceTier1:d.sellPriceTier1??0, sellPriceTier2:d.sellPriceTier2??0, sellPriceTier3:d.sellPriceTier3??0, baseStock:d.stock, minStock:d.minStock, isPriceLocked:d.isPriceLocked); }
  Future<void> saveToLocalDb(LocalDatabase db) async { state=state.copyWith(isLoading:true); try{ await db.into(db.products).insertOnConflictUpdate(ProductsCompanion(id:drift.Value(state.id), name:drift.Value(state.name), shortName:drift.Value(state.shortName), barcode:drift.Value(state.barcode.isEmpty?null:state.barcode), categoryId:drift.Value(state.categoryId), brand:drift.Value(state.brand.isEmpty?null:state.brand), warehouseLocation:drift.Value(state.warehouseLocation.isEmpty?null:state.warehouseLocation), tags:drift.Value(state.tags.isEmpty?null:state.tags), buyPrice:drift.Value(state.buyPrice), sellPriceGeneral:drift.Value(state.sellPriceGeneral), sellPriceTier1:drift.Value(state.sellPriceTier1), sellPriceTier2:drift.Value(state.sellPriceTier2), sellPriceTier3:drift.Value(state.sellPriceTier3), stock:drift.Value(state.baseStock), minStock:drift.Value(state.minStock), isPriceLocked:drift.Value(state.isPriceLocked))); }finally{ state=state.copyWith(isLoading:false); } }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref)=>ProductFormNotifier());

// UI FORM - ADA DI FILE YANG SAMA BIAR TIDAK ERROR IMPORT
class FormProductPage extends ConsumerStatefulWidget {
  final bool isEdit; const FormProductPage({super.key, this.isEdit=false});
  @override ConsumerState<FormProductPage> createState()=> _FormProductPageState();
}
class _FormProductPageState extends ConsumerState<FormProductPage> {
  final _nameCtrl=TextEditingController(); final _barcodeCtrl=TextEditingController();
  final _buyCtrl=TextEditingController(); final _sellCtrl=TextEditingController();
  final _stockCtrl=TextEditingController(); final _minCtrl=TextEditingController();
  @override void initState(){ super.initState(); final s=ref.read(productFormProvider); _nameCtrl.text=s.name; _barcodeCtrl.text=s.barcode; _buyCtrl.text=s.buyPrice==0?'':s.buyPrice.toStringAsFixed(0); _sellCtrl.text=s.sellPriceGeneral==0?'':s.sellPriceGeneral.toStringAsFixed(0); _stockCtrl.text=s.baseStock==0?'':s.baseStock.toStringAsFixed(0); _minCtrl.text=s.minStock==0?'':s.minStock.toStringAsFixed(0); }
  @override void dispose(){ _nameCtrl.dispose(); _barcodeCtrl.dispose(); _buyCtrl.dispose(); _sellCtrl.dispose(); _stockCtrl.dispose(); _minCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    final formState=ref.watch(productFormProvider); final notifier=ref.read(productFormProvider.notifier); final db=ref.watch(localDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit?'Edit: ${formState.id}':'Tambah: ${formState.id}')),
      body: ListView(padding: const EdgeInsets.all(16), children:[
        TextField(controller:_nameCtrl, decoration: const InputDecoration(labelText:'Nama Produk *', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(name:v)),
        const SizedBox(height:12),
        TextField(controller:_barcodeCtrl, decoration: const InputDecoration(labelText:'Barcode', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(barcode:v)),
        const SizedBox(height:12),
        Row(children:[Expanded(child:TextField(controller:_buyCtrl, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'HPP', prefixText:'Rp ', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(buyPrice:double.tryParse(v)??0))), const SizedBox(width:12), Expanded(child:TextField(controller:_sellCtrl, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Jual Umum', prefixText:'Rp ', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(sellPriceGeneral:double.tryParse(v)??0)))]),
        const SizedBox(height:12),
        Row(children:[Expanded(child:TextField(controller:_stockCtrl, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Stok Awal', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(baseStock:double.tryParse(v)??0))), const SizedBox(width:12), Expanded(child:TextField(controller:_minCtrl, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Min Stok', border:OutlineInputBorder()), onChanged:(v)=>notifier.updateFields(minStock:double.tryParse(v)??0)))]),
        const SizedBox(height:20), Text('Margin: ${formState.marginGeneralPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight:FontWeight.bold, color:Colors.green)),
        const SizedBox(height:24),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A), padding: const EdgeInsets.symmetric(vertical:16)), onPressed:()async{ if(formState.name.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Nama wajib isi'))); return; } await notifier.saveToLocalDb(db); if(mounted) Navigator.pop(context); }, child: Text(widget.isEdit?'UPDATE MASTER':'SIMPAN MASTER', style: const TextStyle(color:Colors.white, fontWeight:FontWeight.bold))),
      ]),
    );
  }
}