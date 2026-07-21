import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/local_database.dart';

class ProductFormState {
  final String id;
  final String name;
  final String shortName;
  final String barcode;
  final String description;
  final String categoryId;
  final String subCategory;
  final String brand;
  final String warehouseLocation;
  final String tags;
  
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

  final List<ProductUnitData> units;
  final List<ProductVariantData> variants;
  final List<String> imagePaths;

  ProductFormState({
    required this.id,
    this.name = '',
    this.shortName = '',
    this.barcode = '',
    this.description = '',
    this.categoryId = 'Umum',
    this.subCategory = '',
    this.brand = '',
    this.warehouseLocation = '',
    this.tags = '',
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
    this.units = const [],
    this.variants = const [],
    this.imagePaths = const [],
  });

  double get marginPercentage {
    if (sellPriceGeneral <= 0) return 0;
    return ((sellPriceGeneral - buyPrice) / sellPriceGeneral) * 100;
  }

  ProductFormState copyWith({
    String? id, String? name, String? shortName, String? barcode, String? description,
    String? categoryId, String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? stock, double? minStock, double? maxStock,
    bool? allowMinusStock, double? weight, String? dimensions, double? ppnPercent, int? rewardPoints,
    DateTime? expiryDate, String? statusActive, List<ProductUnitData>? units, List<ProductVariantData>? variants,
    List<String>? imagePaths,
  }) {
    return ProductFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      tags: tags ?? this.tags,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPriceGeneral: sellPriceGeneral ?? this.sellPriceGeneral,
      sellPriceTier1: sellPriceTier1 ?? this.sellPriceTier1,
      sellPriceTier2: sellPriceTier2 ?? this.sellPriceTier2,
      sellPriceTier3: sellPriceTier3 ?? this.sellPriceTier3,
      maxDiscountSales: maxDiscountSales ?? this.maxDiscountSales,
      isPriceLocked: isPriceLocked ?? this.isPriceLocked,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      allowMinusStock: allowMinusStock ?? this.allowMinusStock,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      expiryDate: expiryDate ?? this.expiryDate,
      statusActive: statusActive ?? this.statusActive,
      units: units ?? this.units,
      variants: variants ?? this.variants,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final LocalDatabase _db;

  ProductFormNotifier(this._db) : super(ProductFormState(id: 'PTRS${DateTime.now().millisecondsSinceEpoch}'));

  void setProduct(ProductData p, List<ProductUnitData> units, List<ProductVariantData> variants, List<String> images) {
    state = ProductFormState(
      id: p.id, name: p.name, shortName: p.shortName ?? '', barcode: p.barcode ?? '',
      description: p.description ?? '', categoryId: p.categoryId, subCategory: p.subCategory ?? '',
      brand: p.brand ?? '', warehouseLocation: p.warehouseLocation ?? '', tags: p.tags ?? '',
      buyPrice: p.buyPrice, sellPriceGeneral: p.sellPriceGeneral, sellPriceTier1: p.sellPriceTier1,
      sellPriceTier2: p.sellPriceTier2, sellPriceTier3: p.sellPriceTier3, maxDiscountSales: p.maxDiscountSales,
      isPriceLocked: p.isPriceLocked, stock: p.stock, minStock: p.minStock, maxStock: p.maxStock,
      allowMinusStock: p.allowMinusStock, weight: p.weight, dimensions: p.dimensions ?? '',
      ppnPercent: p.ppnPercent, rewardPoints: p.rewardPoints, expiryDate: p.expiryDate,
      statusActive: p.statusActive, units: units, variants: variants, imagePaths: images,
    );
  }

  void updateField({
    String? name, String? shortName, String? barcode, String? description,
    String? categoryId, String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? stock, double? minStock, double? maxStock,
    bool? allowMinusStock, double? weight, String? dimensions, double? ppnPercent, int? rewardPoints,
    DateTime? expiryDate, String? statusActive,
  }) {
    state = state.copyWith(
      name: name, shortName: shortName, barcode: barcode, description: description,
      categoryId: categoryId, subCategory: subCategory, brand: brand, warehouseLocation: warehouseLocation, tags: tags,
      buyPrice: buyPrice, sellPriceGeneral: sellPriceGeneral, sellPriceTier1: sellPriceTier1,
      sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3, maxDiscountSales: maxDiscountSales,
      isPriceLocked: isPriceLocked, stock: stock, minStock: minStock, maxStock: maxStock,
      allowMinusStock: allowMinusStock, weight: weight, dimensions: dimensions, ppnPercent: ppnPercent,
      rewardPoints: rewardPoints, expiryDate: expiryDate, statusActive: statusActive,
    );
  }

  void addUnit(String unitName, int conversion, double buy, double sell, String? bcode) {
    final newUnit = ProductUnitData(
      id: 'UNT-${DateTime.now().millisecondsSinceEpoch}-${state.units.length}',
      productId: state.id, unitName: unitName, conversion: conversion,
      buyPriceUnit: buy, sellPriceUnit: sell, barcode: bcode,
    );
    state = state.copyWith(units: [...state.units, newUnit]);
  }

  void removeUnit(String id) {
    state = state.copyWith(units: state.units.where((e) => e.id != id).toList());
  }

  /// PERBAIKAN: Penambahan method addManualVariant untuk Form Master
  void addManualVariant({required String skuId, required String defaultName, required double defaultPrice}) {
    final newVariant = ProductVariantData(
      id: skuId,
      productId: state.id,
      skuVariant: skuId,
      variantName: defaultName,
      barcode: '',
      stock: 0,
      sellPrice: defaultPrice,
    );
    state = state.copyWith(variants: [...state.variants, newVariant]);
  }

  /// PERBAIKAN: Penambahan method removeVariant untuk Form Master
  void removeVariant(String id) {
    state = state.copyWith(variants: state.variants.where((v) => v.id != id).toList());
  }

  void updateVariantDetail(String id, {String? name, double? stock, double? price, String? barcode}) {
    state = state.copyWith(
      variants: [
        for (var v in state.variants)
          if (v.id == id)
            ProductVariantData(
              id: v.id,
              productId: v.productId,
              skuVariant: v.skuVariant,
              variantName: name ?? v.variantName,
              barcode: barcode ?? v.barcode,
              stock: stock ?? v.stock,
              sellPrice: price ?? v.sellPrice,
            )
          else v
      ],
    );
  }

  Future<bool> saveProduct() async {
    if (state.name.isEmpty) return false;

    try {
      await _db.transaction(() async {
        await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: state.id,
            name: state.name,
            shortName: Value(state.shortName.isEmpty ? state.name : state.shortName),
            barcode: Value(state.barcode),
            description: Value(state.description),
            categoryId: Value(state.categoryId),
            subCategory: Value(state.subCategory),
            brand: Value(state.brand),
            warehouseLocation: Value(state.warehouseLocation),
            tags: Value(state.tags),
            buyPrice: Value(state.buyPrice),
            sellPriceGeneral: Value(state.sellPriceGeneral),
            sellPriceTier1: Value(state.sellPriceTier1),
            sellPriceTier2: Value(state.sellPriceTier2),
            sellPriceTier3: Value(state.sellPriceTier3),
            maxDiscountSales: Value(state.maxDiscountSales),
            isPriceLocked: Value(state.isPriceLocked),
            stock: Value(state.stock),
            minStock: Value(state.minStock),
            maxStock: Value(state.maxStock),
            allowMinusStock: Value(state.allowMinusStock),
            weight: Value(state.weight),
            dimensions: Value(state.dimensions),
            ppnPercent: Value(state.ppnPercent),
            rewardPoints: Value(state.rewardPoints),
            expiryDate: Value(state.expiryDate),
            statusActive: Value(state.statusActive),
          ),
        );

        await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(state.id))).go();
        for (var item in state.units) {
          await _db.into(_db.productUnits).insert(item);
        }

        await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(state.id))).go();
        for (var item in state.variants) {
          await _db.into(_db.productVariants).insert(item);
        }

        await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(state.id))).go();
        for (int i = 0; i < state.imagePaths.length; i++) {
          await _db.into(_db.productAssets).insert(ProductAssetData(
            id: 'AST-${DateTime.now().millisecondsSinceEpoch}-$i',
            productId: state.id,
            imagePath: state.imagePaths[i],
            isPrimary: i == 0,
            sortOrder: i,
          ));
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteProduct(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
    });
  }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ProductFormNotifier(db);
});
