// lib/features/product/product_form_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/local_database.dart';

/// State penampung data form produk yang kompleks
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

  // Relasi Sub-Tabel
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

  /// Otomatis hitung profit margin dalam persen
  double get marginPercentage {
    if (sellPriceGeneral <= 0) return 0;
    return ((sellPriceGeneral - buyPrice) / sellPriceGeneral) * 100;
  }

  ProductFormState copyWith({
    String? id,
    String? name,
    String? shortName,
    String? barcode,
    String? description,
    String? categoryId,
    String? subCategory,
    String? brand,
    String? warehouseLocation,
    String? tags,
    double? buyPrice,
    double? sellPriceGeneral,
    double? sellPriceTier1,
    double? sellPriceTier2,
    double? sellPriceTier3,
    double? maxDiscountSales,
    bool? isPriceLocked,
    double? stock,
    double? minStock,
    double? maxStock,
    bool? allowMinusStock,
    double? weight,
    String? dimensions,
    double? ppnPercent,
    int? rewardPoints,
    DateTime? expiryDate,
    String? statusActive,
    List<ProductUnitData>? units,
    List<ProductVariantData>? variants,
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

  ProductFormNotifier(this._db)
      : super(ProductFormState(id: 'PTRS${DateTime.now().millisecondsSinceEpoch}'));

  /// Memuat data produk yang sudah ada ke dalam form (mode Edit)
  void setProduct(
    ProductData p,
    List<ProductUnitData> units,
    List<ProductVariantData> variants,
    List<String> images,
  ) {
    state = ProductFormState(
      id: p.id,
      name: p.name,
      shortName: p.shortName ?? '',
      barcode: p.barcode ?? '',
      description: p.description ?? '',
      categoryId: p.categoryId,
      subCategory: p.subCategory ?? '',
      brand: p.brand ?? '',
      warehouseLocation: p.warehouseLocation ?? '',
      tags: p.tags ?? '',
      buyPrice: p.buyPrice,
      sellPriceGeneral: p.sellPriceGeneral,
      sellPriceTier1: p.sellPriceTier1,
      sellPriceTier2: p.sellPriceTier2,
      sellPriceTier3: p.sellPriceTier3,
      maxDiscountSales: p.maxDiscountSales,
      isPriceLocked: p.isPriceLocked,
      stock: p.stock,
      minStock: p.minStock,
      maxStock: p.maxStock,
      allowMinusStock: p.allowMinusStock,
      weight: p.weight,
      dimensions: p.dimensions ?? '',
      ppnPercent: p.ppnPercent,
      rewardPoints: p.rewardPoints,
      expiryDate: p.expiryDate,
      statusActive: p.statusActive,
      units: units,
      variants: variants,
      imagePaths: images,
    );
  }

  /// Update individual field form
  void updateField({
    String? name,
    String? shortName,
    String? barcode,
    String? description,
    String? categoryId,
    String? subCategory,
    String? brand,
    String? warehouseLocation,
    String? tags,
    double? buyPrice,
    double? sellPriceGeneral,
    double? sellPriceTier1,
    double? sellPriceTier2,
    double? sellPriceTier3,
    double? maxDiscountSales,
    bool? isPriceLocked,
    double? stock,
    double? minStock,
    double? maxStock,
    bool? allowMinusStock,
    double? weight,
    String? dimensions,
    double? ppnPercent,
    int? rewardPoints,
    DateTime? expiryDate,
    String? statusActive,
  }) {
    state = state.copyWith(
      name: name,
      shortName: shortName,
      barcode: barcode,
      description: description,
      categoryId: categoryId,
      subCategory: subCategory,
      brand: brand,
      warehouseLocation: warehouseLocation,
      tags: tags,
      buyPrice: buyPrice,
      sellPriceGeneral: sellPriceGeneral,
      sellPriceTier1: sellPriceTier1,
      sellPriceTier2: sellPriceTier2,
      sellPriceTier3: sellPriceTier3,
      maxDiscountSales: maxDiscountSales,
      isPriceLocked: isPriceLocked,
      stock: stock,
      minStock: minStock,
      maxStock: maxStock,
      allowMinusStock: allowMinusStock,
      weight: weight,
      dimensions: dimensions,
      ppnPercent: ppnPercent,
      rewardPoints: rewardPoints,
      expiryDate: expiryDate,
      statusActive: statusActive,
    );
  }

  /// Generator Varian Produk Otomatis berdasarkan Warna & Ukuran
  void generateVariants({
    List<String>? warnaList,
    List<String>? ukuranList,
    List<String>? variantNames,
    double? defaultPrice,
  }) {
    final currentVariants = List<ProductVariantData>.from(state.variants);
    final baseId = state.id.isEmpty ? 'PSB-${DateTime.now().millisecondsSinceEpoch}' : state.id;
    final price = defaultPrice ?? state.sellPriceGeneral;

    List<String> namesToCreate = [];

    if (warnaList != null && warnaList.isNotEmpty && ukuranList != null && ukuranList.isNotEmpty) {
      for (var w in warnaList) {
        for (var u in ukuranList) {
          if (w.trim().isNotEmpty && u.trim().isNotEmpty) {
            namesToCreate.add('${w.trim()} - ${u.trim()}');
          }
        }
      }
    } else if (warnaList != null && warnaList.isNotEmpty) {
      namesToCreate.addAll(warnaList.where((e) => e.trim().isNotEmpty));
    } else if (ukuranList != null && ukuranList.isNotEmpty) {
      namesToCreate.addAll(ukuranList.where((e) => e.trim().isNotEmpty));
    } else if (variantNames != null && variantNames.isNotEmpty) {
      namesToCreate.addAll(variantNames.where((e) => e.trim().isNotEmpty));
    } else {
      namesToCreate.add('Varian Baru');
    }

    for (var name in namesToCreate) {
      final nextIndex = currentVariants.length + 1;
      final autoSuffix = '+V${nextIndex.toString().padLeft(3, '0')}';
      final sku = '$baseId$autoSuffix';

      currentVariants.add(
        ProductVariantData(
          id: sku,
          productId: baseId,
          skuVariant: sku,
          variantName: name,
          sellPrice: price,
          stock: 0,
        ),
      );
    }

    state = state.copyWith(variants: currentVariants);
  }

  /// Tambah Varian Manual
  void addManualVariant({
    required String skuId,
    required String defaultName,
    required double defaultPrice,
  }) {
    state = state.copyWith(variants: [
      ...state.variants,
      ProductVariantData(
        id: skuId,
        productId: state.id.isEmpty ? 'TEMP' : state.id,
        skuVariant: skuId,
        variantName: defaultName,
        barcode: '',
        stock: 0,
        sellPrice: defaultPrice,
      )
    ]);
  }

  void removeVariant(String id) {
    state = state.copyWith(variants: state.variants.where((e) => e.id != id).toList());
  }

  void updateVariantDetail(
    String id, {
    String? variantName,
    double? sellPrice,
    double? stock,
    String? barcode,
  }) {
    state = state.copyWith(variants: [
      for (var v in state.variants)
        if (v.id == id)
          ProductVariantData(
            id: v.id,
            productId: v.productId,
            skuVariant: v.skuVariant,
            variantName: variantName ?? v.variantName,
            barcode: barcode ?? v.barcode,
            stock: stock ?? v.stock,
            sellPrice: sellPrice ?? v.sellPrice,
          )
        else
          v,
    ]);
  }

  /// Tambah Konversi Multi-Satuan Grosir
  void addUnit(String unitName, int conversion, double buy, double sell, String? bcode) {
    final newUnit = ProductUnitData(
      id: 'UNT-${DateTime.now().millisecondsSinceEpoch}-${state.units.length}',
      productId: state.id,
      unitName: unitName,
      conversion: conversion,
      buyPriceUnit: buy,
      sellPriceUnit: sell,
      barcode: bcode,
    );
    state = state.copyWith(units: [...state.units, newUnit]);
  }

  void removeUnit(String id) {
    state = state.copyWith(units: state.units.where((e) => e.id != id).toList());
  }

  /// Kelola Gambar Produk
  void addImage(String path) {
    state = state.copyWith(imagePaths: [...state.imagePaths, path]);
  }

  void removeImage(String path) {
    state = state.copyWith(imagePaths: state.imagePaths.where((e) => e != path).toList());
  }

  /// Eksekusi Simpan Produk ke Local Database (Drift) & Auto-Generate Metadata
  Future<bool> saveProduct() async {
    if (state.name.trim().isEmpty) return false;

    try {
      final isNew = state.id.isEmpty || state.id.startsWith('PTRS');
      final finalProductId = isNew 
          ? 'PRD-${DateTime.now().millisecondsSinceEpoch}' 
          : state.id;

      // Generasi Barcode Otomatis jika kosong (Sesuai Spec: P-YYYYMMDD-XXXX)
      final now = DateTime.now();
      final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final finalBarcode = state.barcode.trim().isEmpty 
          ? 'P-$dateStr-${now.millisecond.toString().padLeft(4, '0')}' 
          : state.barcode.trim();

      await _db.transaction(() async {
        // 1. Upsert Master Produk
        await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: Value(finalProductId),
            name: Value(state.name),
            shortName: Value(state.shortName.isEmpty ? state.name : state.shortName),
            barcode: Value(finalBarcode),
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

        // 2. Jika Produk Baru & Ada Stok Awal -> Catat Mutasi Stok Log (Inisialisasi)
        if (isNew && state.stock > 0) {
          await _db.into(_db.stockMutations).insert(
            StockMutationsCompanion.insert(
              id: 'MUT-INIT-${DateTime.now().millisecondsSinceEpoch}',
              productId: finalProductId,
              type: 'opname',
              quantity: state.stock,
              hppSnapshot: state.buyPrice,
              currentStockSnapshot: state.stock,
              referenceNo: 'STOK-AWAL',
              notes: const Value('Inisialisasi Stok Awal Produk Baru'),
              date: Value(DateTime.now()),
            ),
          );
        }

        // 3. Simpan Unit Conversion / Multi Satuan
        await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(finalProductId))).go();
        for (var u in state.units) {
          await _db.into(_db.productUnits).insert(
            ProductUnitsCompanion.insert(
              id: u.id.startsWith('UNT-') ? u.id : 'UNT-${DateTime.now().millisecondsSinceEpoch}-${u.unitName}',
              productId: finalProductId,
              unitName: u.unitName,
              conversion: u.conversion,
              buyPriceUnit: u.buyPriceUnit,
              sellPriceUnit: u.sellPriceUnit,
              barcode: Value(u.barcode),
            ),
          );
        }

        // 4. Simpan Varian Produk
        await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(finalProductId))).go();
        for (var v in state.variants) {
          await _db.into(_db.productVariants).insert(
            ProductVariantsCompanion.insert(
              id: v.id.startsWith('PTRS') || v.id.isEmpty 
                  ? 'VAR-${DateTime.now().millisecondsSinceEpoch}' 
                  : v.id,
              productId: finalProductId,
              skuVariant: v.skuVariant,
              variantName: v.variantName,
              barcode: Value(v.barcode),
              stock: Value(v.stock),
              sellPrice: Value(v.sellPrice),
            ),
          );
        }

        // 5. Hubungkan Aset Gambar Produk
        await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(finalProductId))).go();
        for (int i = 0; i < state.imagePaths.length; i++) {
          await _db.into(_db.productAssets).insert(
            ProductAssetData(
              id: 'AST-${DateTime.now().millisecondsSinceEpoch}-$i',
              productId: finalProductId,
              imagePath: state.imagePaths[i],
              isPrimary: i == 0,
              sortOrder: i,
            ),
          );
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hapus Produk beserta Seluruh Sub-Tabel Relasinya
  Future<void> deleteProduct(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.productAssets)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.productUnits)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.productVariants)..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
    });
  }
}

/// Riverpod Provider Auto-Dispose
final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ProductFormNotifier(db);
});
