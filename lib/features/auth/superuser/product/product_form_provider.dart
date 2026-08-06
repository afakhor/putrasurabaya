// lib/features/auth/superuser/product/product_form_provider.dart - FINAL v16 1 PINTU
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';

class ProductFormState {
  final String id;
  final String code;
  final String name;
  final String shortName;
  final String barcode;
  final String description;
  final String categoryId;
  final String subCategory;
  final String brand;
  final String warehouseLocation;
  final String tags;
  final String unit;
  final double buyPrice;
  final double sellPriceGeneral;
  final double sellPriceTier1;
  final double sellPriceTier2;
  final double sellPriceTier3;
  final double maxDiscountSales;
  final bool isPriceLocked;
  final double stock;
  final double minStock;
  final double maxStock;
  final bool allowMinusStock;
  final double weight;
  final String dimensions;
  final double ppnPercent;
  final int rewardPoints;
  final DateTime? expiryDate;
  final String statusActive;
  final String rackLocation;
  final List<ProductUnitData> units;
  final List<ProductVariantData> variants;
  final List<String> imagePaths;
  final bool isEditMode;

  ProductFormState({
    required this.id,
    this.code = '',
    this.name = '',
    this.shortName = '',
    this.barcode = '',
    this.description = '',
    this.categoryId = 'Perkakas Tangan',
    this.subCategory = '',
    this.brand = '',
    this.warehouseLocation = '',
    this.tags = '',
    this.unit = 'Pcs',
    this.buyPrice = 0,
    this.sellPriceGeneral = 0,
    this.sellPriceTier1 = 0,
    this.sellPriceTier2 = 0,
    this.sellPriceTier3 = 0,
    this.maxDiscountSales = 0,
    this.isPriceLocked = true,
    this.stock = 0,
    this.minStock = 5,
    this.maxStock = 100,
    this.allowMinusStock = false,
    this.weight = 0,
    this.dimensions = '',
    this.ppnPercent = 0,
    this.rewardPoints = 0,
    this.expiryDate,
    this.statusActive = 'aktif',
    this.rackLocation = '',
    this.units = const [],
    this.variants = const [],
    this.imagePaths = const [],
    this.isEditMode = false,
  });

  // % margin dari HPP
  double marginPercent(double jual) {
    if (buyPrice <= 0 || jual <= 0) return 0;
    return ((jual - buyPrice) / jual) * 100;
  }

  double get marginGeneral => marginPercent(sellPriceGeneral);
  double get marginTier1 => marginPercent(sellPriceTier1);
  double get marginTier2 => marginPercent(sellPriceTier2);
  double get marginTier3 => marginPercent(sellPriceTier3);

  ProductFormState copyWith({
    String? id, String? code, String? name, String? shortName, String? barcode, String? description,
    String? categoryId, String? subCategory, String? brand, String? warehouseLocation, String? tags, String? unit,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? stock, double? minStock, double? maxStock, bool? allowMinusStock,
    double? weight, String? dimensions, double? ppnPercent, int? rewardPoints, DateTime? expiryDate, String? statusActive, String? rackLocation,
    List<ProductUnitData>? units, List<ProductVariantData>? variants, List<String>? imagePaths, bool? isEditMode,
  }) {
    return ProductFormState(
      id: id?? this.id, code: code?? this.code, name: name?? this.name, shortName: shortName?? this.shortName,
      barcode: barcode?? this.barcode, description: description?? this.description, categoryId: categoryId?? this.categoryId,
      subCategory: subCategory?? this.subCategory, brand: brand?? this.brand, warehouseLocation: warehouseLocation?? this.warehouseLocation,
      tags: tags?? this.tags, unit: unit?? this.unit, buyPrice: buyPrice?? this.buyPrice, sellPriceGeneral: sellPriceGeneral?? this.sellPriceGeneral,
      sellPriceTier1: sellPriceTier1?? this.sellPriceTier1, sellPriceTier2: sellPriceTier2?? this.sellPriceTier2, sellPriceTier3: sellPriceTier3?? this.sellPriceTier3,
      maxDiscountSales: maxDiscountSales?? this.maxDiscountSales, isPriceLocked: isPriceLocked?? this.isPriceLocked,
      stock: stock?? this.stock, minStock: minStock?? this.minStock, maxStock: maxStock?? this.maxStock, allowMinusStock: allowMinusStock?? this.allowMinusStock,
      weight: weight?? this.weight, dimensions: dimensions?? this.dimensions, ppnPercent: ppnPercent?? this.ppnPercent, rewardPoints: rewardPoints?? this.rewardPoints,
      expiryDate: expiryDate?? this.expiryDate, statusActive: statusActive?? this.statusActive, rackLocation: rackLocation?? this.rackLocation,
      units: units?? this.units, variants: variants?? this.variants, imagePaths: imagePaths?? this.imagePaths, isEditMode: isEditMode?? this.isEditMode,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final LocalDatabase _db;
  ProductFormNotifier(this._db) : super(ProductFormState(id: 'PRD-${DateTime.now().millisecondsSinceEpoch}'));

  // SET UNTUK EDIT
  void setProduct(ProductData p, List<ProductUnitData> units, List<ProductVariantData> variants, List<String> images) {
    state = ProductFormState(
      id: p.id, code: p.code?? '', name: p.name, shortName: p.shortName?? '', barcode: p.barcode?? '', description: p.description?? '',
      categoryId: p.categoryId, subCategory: p.subCategory?? '', brand: p.brand?? '', warehouseLocation: p.warehouseLocation?? '', tags: p.tags?? '',
      unit: p.unit, buyPrice: p.buyPrice, sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1, sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3,
      maxDiscountSales: p.maxDiscountSales, isPriceLocked: p.isPriceLocked, stock: p.stock, minStock: p.minStock, maxStock: p.maxStock, allowMinusStock: p.allowMinusStock,
      weight: p.weight, dimensions: p.dimensions?? '', ppnPercent: p.ppnPercent, rewardPoints: p.rewardPoints, expiryDate: p.expiryDate, statusActive: p.statusActive, rackLocation: p.rackLocation?? '',
      units: units, variants: variants, imagePaths: images, isEditMode: true,
    );
  }

  void resetForm() {
    state = ProductFormState(id: 'PRD-${DateTime.now().millisecondsSinceEpoch}');
  }

  // AUTO SKU + AUTO COMPLETE LOGIC
  void updateField({
    String? name, String? shortName, String? barcode, String? description, String? categoryId, String? subCategory, String? brand, String? warehouseLocation,
    String? tags, String? unit, String? code, double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? stock, double? minStock, double? maxStock, bool? allowMinusStock,
    double? weight, String? dimensions, double? ppnPercent, int? rewardPoints, DateTime? expiryDate, String? statusActive, String? rackLocation,
  }) {
    // AUTO SKU: CATEGORY-RAK-XXX-XXXXX -> PRK-RK-OBE-1234
    String newCode = state.code;
    if (!state.isEditMode) {
      if (categoryId != null || rackLocation != null || name != null) {
        final catRaw = (categoryId ?? state.categoryId).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
        final cat = catRaw.length >= 3 ? catRaw.substring(0, 3) : catRaw.padRight(3, 'X');
        final rakRaw = (rackLocation ?? state.rackLocation).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final rak = rakRaw.isEmpty ? 'A1' : rakRaw.substring(0, rakRaw.length > 2 ? 2 : rakRaw.length).padRight(2, '1');
        final namePart = (name ?? state.name).isEmpty ? 'XXX' : (name ?? state.name).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').substring(0, (name ?? state.name).length >= 3 ? 3 : (name ?? state.name).length).padRight(3, 'X');
        final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12);
        newCode = '$cat-$rak-$namePart-$rand';
      }
    }
    state = state.copyWith(
      name: name, shortName: shortName, barcode: barcode, description: description, categoryId: categoryId, subCategory: subCategory, brand: brand,
      warehouseLocation: warehouseLocation, tags: tags, unit: unit, code: code ?? newCode, buyPrice: buyPrice, sellPriceGeneral: sellPriceGeneral,
      sellPriceTier1: sellPriceTier1, sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3, maxDiscountSales: maxDiscountSales,
      isPriceLocked: isPriceLocked, stock: stock, minStock: minStock, maxStock: maxStock, allowMinusStock: allowMinusStock, weight: weight,
      dimensions: dimensions, ppnPercent: ppnPercent, rewardPoints: rewardPoints, expiryDate: expiryDate, statusActive: statusActive, rackLocation: rackLocation,
    );
  }

  // AUTO COMPLETE: cari barang mirip
  Future<List<ProductData>> autoComplete(String keyword) async {
    if (keyword.length < 2) return [];
    final q = '%${keyword.toLowerCase()}%';
    return (_db.select(_db.products)..where((t) => t.name.lower().like(q) | t.code.lower().like(q) | t.barcode.lower().like(q))..limit(5)).get();
  }

  // VARIANT & UNIT
  void generateVariants({List<String>? warnaList, List<String>? ukuranList, List<String>? variantNames, double? defaultPrice}) {
    final current = List<ProductVariantData>.from(state.variants);
    final baseId = state.id;
    final price = defaultPrice ?? state.sellPriceGeneral;
    List<String> names = [];
    if (warnaList != null && ukuranList != null && warnaList.isNotEmpty && ukuranList.isNotEmpty) {
      for (var w in warnaList) { for (var u in ukuranList) { if (w.trim().isNotEmpty && u.trim().isNotEmpty) names.add('$w - $u'); } }
    } else if (warnaList != null && warnaList.isNotEmpty) { names.addAll(warnaList.where((e) => e.trim().isNotEmpty)); }
    else if (ukuranList != null && ukuranList.isNotEmpty) { names.addAll(ukuranList.where((e) => e.trim().isNotEmpty)); }
    else if (variantNames != null && variantNames.isNotEmpty) { names.addAll(variantNames.where((e) => e.trim().isNotEmpty)); }
    else { names.add('Varian Baru'); }
    for (var n in names) {
      final idx = current.length + 1;
      final sku = '$baseId+V${idx.toString().padLeft(3, '0')}';
      current.add(ProductVariantData(id: sku, productId: baseId, skuVariant: sku, variantName: n, sellPrice: price, stock: 0));
    }
    state = state.copyWith(variants: current);
  }

  void addManualVariant({required String skuId, required String defaultName, required double defaultPrice}) {
    state = state.copyWith(variants: [...state.variants, ProductVariantData(id: skuId, productId: state.id, skuVariant: skuId, variantName: defaultName, sellPrice: defaultPrice, stock: 0)]);
  }
  void removeVariant(String id) { state = state.copyWith(variants: state.variants.where((e) => e.id != id).toList()); }
  void updateVariantDetail(String id, {String? variantName, double? sellPrice, double? stock, String? barcode}) {
    state = state.copyWith(variants: [for (var v in state.variants) if (v.id == id) ProductVariantData(id: v.id, productId: v.productId, skuVariant: v.skuVariant, variantName: variantName ?? v.variantName, barcode: barcode ?? v.barcode, stock: stock ?? v.stock, sellPrice: sellPrice ?? v.sellPrice) else v]);
  }
  void addUnit(String unitName, int conversion, double buy, double sell, String? bcode) {
    final u = ProductUnitData(id: 'UNT-${DateTime.now().millisecondsSinceEpoch}-${state.units.length}', productId: state.id, unitName: unitName, conversion: conversion, buyPriceUnit: buy, sellPriceUnit: sell, barcode: bcode);
    state = state.copyWith(units: [...state.units, u]);
  }
  void removeUnit(String id) { state = state.copyWith(units: state.units.where((e) => e.id != id).toList()); }
  void addImage(String path) { state = state.copyWith(imagePaths: [...state.imagePaths, path]); }
  void removeImage(String path) { state = state.copyWith(imagePaths: state.imagePaths.where((e) => e != path).toList()); }

  // SAVE 1 PINTU - FIX UTAMA
  Future<bool> saveProduct() async {
    if (state.name.trim().isEmpty) return false;
    try {
      final finalId = state.id.isEmpty ? 'PRD-${DateTime.now().millisecondsSinceEpoch}' : state.id;
      final now = DateTime.now();
      final finalCode = state.code.isEmpty ? 'PRK-${now.millisecondsSinceEpoch.toString().substring(7)}' : state.code;
      final finalBarcode = state.barcode.isEmpty ? 'P-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(4, '0')}' : state.barcode;
      final existing = await (_db.select(_db.products)..where((t) => t.id.equals(finalId))).getSingleOrNull();
      final isNew = existing == null;
      final oldStock = existing?.stock ?? 0;

      await _db.transaction(() async {
        // 1. INSERT/UPDATE MASTER - STOK 0 DULU JIKA BARU
        await _db.into(_db.products).insertOnConflictUpdate(ProductsCompanion(
          id: Value(finalId), code: Value(finalCode), name: Value(state.name),
          shortName: Value(state.shortName.isEmpty ? state.name : state.shortName),
          barcode: Value(finalBarcode), description: Value(state.description), categoryId: Value(state.categoryId),
          subCategory: Value(state.subCategory), brand: Value(state.brand), warehouseLocation: Value(state.warehouseLocation),
          tags: Value(state.tags), unit: Value(state.unit), buyPrice: Value(state.buyPrice), sellPriceGeneral: Value(state.sellPriceGeneral),
          sellPrice: Value(state.sellPriceGeneral), sellPriceTier1: Value(state.sellPriceTier1), sellPriceTier2: Value(state.sellPriceTier2),
          sellPriceTier3: Value(state.sellPriceTier3), maxDiscountSales: Value(state.maxDiscountSales), isPriceLocked: Value(state.isPriceLocked),
          stock: Value(isNew ? 0 : oldStock), // JANGAN LANGSUNG state.stock!
          minStock: Value(state.minStock), maxStock: Value(state.maxStock), allowMinusStock: Value(state.allowMinusStock),
          weight: Value(state.weight), dimensions: Value(state.dimensions), ppnPercent: Value(state.ppnPercent), rewardPoints: Value(state.rewardPoints),
          expiryDate: Value(state.expiryDate), statusActive: Value(state.statusActive), rackLocation: Value(state.rackLocation),
          isSynced: const Value(false), updatedAt: Value(DateTime.now()),
        ));

        await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(finalId))).go();
        for (var u in state.units) {
          await _db.into(_db.productUnits).insert(ProductUnitsCompanion.insert(
            id: u.id, productId: finalId, unitName: u.unitName, conversion: Value(u.conversion), buyPriceUnit: Value(u.buyPriceUnit), sellPriceUnit: Value(u.sellPriceUnit), barcode: Value(u.barcode),
          ));
        }
        await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(finalId))).go();
        for (var v in state.variants) {
          await _db.into(_db.productVariants).insert(ProductVariantsCompanion.insert(
            id: v.id, productId: finalId, skuVariant: v.skuVariant, variantName: v.variantName, barcode: Value(v.barcode), stock: Value(v.stock), sellPrice: Value(v.sellPrice),
          ));
        }
        await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(finalId))).go();
        for (int i = 0; i < state.imagePaths.length; i++) {
          await _db.into(_db.productAssets).insert(ProductAssetsCompanion.insert(
            id: 'AST-${DateTime.now().millisecondsSinceEpoch}-$i', productId: finalId, imagePath: state.imagePaths[i], isPrimary: Value(i == 0), sortOrder: Value(i),
          ));
        }
        final cat = await (_db.select(_db.categories)..where((t) => t.name.equals(state.categoryId) | t.id.equals(state.categoryId))).getSingleOrNull();
        if (cat != null) { await _db.categoryDao.incrementUsage(cat.id); }
      });

      // 2. STOK AWAL LEWAT 1 PINTU DAO (DI LUAR TRANSACTION)
      if (isNew && state.stock > 0) {
        await _db.stockMutationDao.catatOpname(
          productId: finalId,
          stokFisik: state.stock,
          refNo: 'INIT-${finalId.substring(0, 8)}',
          userId: 'owner-01',
          notes: 'Stok awal produk baru - ${state.name}',
          newRack: state.rackLocation,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETE + EDIT - TIDAK HAPUS MUTASI
  Future<bool> deleteProduct(String id) async {
    try {
      await _db.transaction(() async {
        await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(id))).go();
        await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(id))).go();
        await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(id))).go();
        // JANGAN HAPUS stockMutations - itu audit!
        await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
      });
      return true;
    } catch (e) { return false; }
  }

  Future<void> softDeleteProduct(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(ProductsCompanion(statusActive: Value('nonaktif'), isSynced: Value(false), updatedAt: Value(DateTime.now())));
  }
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ProductFormNotifier(db);
});

// PROVIDER AUTO COMPLETE
final productAutoCompleteProvider = FutureProvider.family<List<ProductData>, String>((ref, keyword) async {
  final db = ref.watch(localDatabaseProvider);
  if (keyword.length < 2) return [];
  final q = '%${keyword.toLowerCase()}%';
  return (db.select(db.products)..where((t) => t.name.lower().like(q) | t.code.lower().like(q))..limit(5)).get();
});