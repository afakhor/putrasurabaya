// lib/features/auth/superuser/product/product_form_provider.dart - FINAL FIX EDIT HARGA INDEX MASTER - TIDAK ADA YANG DIKURANGI
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';

class ProductFormState {
  final String id; final String code; final String name; final String shortName;
  final String barcode; final String description; final String categoryId;
  final String brand; final String unit; final double buyPrice;
  final double sellPriceGeneral; final double sellPriceTier1; final double sellPriceTier2; final double sellPriceTier3;
  final double stock; final double minStock; final double maxStock;
  final bool allowMinusStock; final String rackLocation; final String statusActive;
  final List<ProductUnitData> units;
  final List<ProductVariantData> variants;
  final List<String> imagePaths;
  final bool isEditMode;

  ProductFormState({
    required this.id, this.code='', this.name='', this.shortName='', this.barcode='', this.description='',
    this.categoryId='Perkakas Tangan', this.brand='', this.unit='Pcs',
    this.buyPrice=0, this.sellPriceGeneral=0, this.sellPriceTier1=0, this.sellPriceTier2=0, this.sellPriceTier3=0,
    this.stock=0, this.minStock=5, this.maxStock=100, this.allowMinusStock=false,
    this.rackLocation='', this.statusActive='aktif',
    this.units=const [], this.variants=const [], this.imagePaths=const [], this.isEditMode=false,
  });

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

  ProductFormState copyWith({
    String? id, code, name, shortName, barcode, description, categoryId, brand, unit, rackLocation, statusActive,
    double? buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3, stock, minStock, maxStock,
    bool? allowMinusStock, List<ProductUnitData>? units, List<ProductVariantData>? variants, List<String>? imagePaths, bool? isEditMode,
  })=> ProductFormState(
    id: id??this.id, code: code??this.code, name: name??this.name, shortName: shortName??this.shortName,
    barcode: barcode??this.barcode, description: description??this.description, categoryId: categoryId??this.categoryId,
    brand: brand??this.brand, unit: unit??this.unit, buyPrice: buyPrice??this.buyPrice,
    sellPriceGeneral: sellPriceGeneral??this.sellPriceGeneral, sellPriceTier1: sellPriceTier1??this.sellPriceTier1,
    sellPriceTier2: sellPriceTier2??this.sellPriceTier2, sellPriceTier3: sellPriceTier3??this.sellPriceTier3,
    stock: stock??this.stock, minStock: minStock??this.minStock, maxStock: maxStock??this.maxStock,
    allowMinusStock: allowMinusStock??this.allowMinusStock, rackLocation: rackLocation??this.rackLocation,
    statusActive: statusActive??this.statusActive, units: units??this.units, variants: variants??this.variants,
    imagePaths: imagePaths??this.imagePaths, isEditMode: isEditMode??this.isEditMode,
  );
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final LocalDatabase _db;
  ProductFormNotifier(this._db) : super(ProductFormState(id: ''));

  void setProduct(ProductData p, List<ProductUnitData> units, List<ProductVariantData> variants, List<String> images){
    state=ProductFormState(
      id: p.id, code: p.code??'', name: p.name, shortName: p.shortName??'', barcode: p.barcode??'', description: p.description??'',
      categoryId: p.categoryId, brand: p.brand??'', unit: p.unit, buyPrice: p.buyPrice,
      sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1, sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3,
      stock: p.stock, minStock: p.minStock, maxStock: p.maxStock,
      allowMinusStock: p.allowMinusStock, rackLocation: p.rackLocation??'', statusActive: p.statusActive,
      units: units, variants: variants, imagePaths: images, isEditMode: true,
    );
  }

  void resetForm()=> state=ProductFormState(id: '');

  void updateField({String? name, code, barcode, description, categoryId, brand, unit, rackLocation, double? buyPrice, sellPriceGeneral, sellPriceTier1, sellPriceTier2, sellPriceTier3, stock, minStock}){
    state=state.copyWith(name: name, code: code, barcode: barcode, description: description, categoryId: categoryId, brand: brand, unit: unit, rackLocation: rackLocation, buyPrice: buyPrice, sellPriceGeneral: sellPriceGeneral, sellPriceTier1: sellPriceTier1, sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3, stock: stock, minStock: minStock);
  }

  Future<bool> saveProduct() async {
    if(state.id.isEmpty) return false;
    if(state.name.trim().isEmpty) return false;
    try{
      final existing = await (_db.select(_db.products)..where((t)=> t.id.equals(state.id))).getSingleOrNull();
      if(existing==null) return false;
      await _db.into(_db.products).insertOnConflictUpdate(ProductsCompanion(
        id: Value(state.id),
        sellPriceGeneral: Value(state.sellPriceGeneral),
        sellPrice: Value(state.sellPriceGeneral),
        sellPriceTier1: Value(state.sellPriceTier1),
        sellPriceTier2: Value(state.sellPriceTier2),
        sellPriceTier3: Value(state.sellPriceTier3),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));
      return true;
    }catch(e){ return false; }
  }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref){
  final db=ref.watch(localDatabaseProvider);
  return ProductFormNotifier(db);
});