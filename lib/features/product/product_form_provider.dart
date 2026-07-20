import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/local_database.dart';

// =========================================================================
// 1. DATA MODELS
// =========================================================================

class VariantMatrixModel {
  final String id;
  final String sku;
  final String name;
  final String? barcode;
  final double stock;
  final double sellPrice;

  VariantMatrixModel({
    required this.id,
    required this.sku,
    required this.name,
    this.barcode,
    this.stock = 0,
    this.sellPrice = 0,
  });

  VariantMatrixModel copyWith({String? id, String? sku, String? name, String? barcode, double? stock, double? sellPrice}) {
    return VariantMatrixModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      stock: stock ?? this.stock,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }
}

class UnitConversionModel {
  final String id;
  final String unitName;
  final int conversion;
  final double buyPrice;
  final double sellPrice;
  final String? barcode;

  UnitConversionModel({
    required this.id,
    required this.unitName,
    required this.conversion,
    required this.buyPrice,
    required this.sellPrice,
    this.barcode,
  });
}

// =========================================================================
// 2. STATE
// =========================================================================

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

  final double baseStock;
  final double minStock;
  final double maxStock;
  final bool allowMinusStock;
  final double weight;
  final String dimensions;
  final double ppnPercent;
  final int rewardPoints;
  final DateTime? expiryDate;

  final List<String> galleryImages;
  final String? primaryImage;
  final List<UnitConversionModel> multiUnits;
  final List<VariantMatrixModel> variantMatrix;
  final bool isLoading;

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
    this.baseStock = 0,
    this.minStock = 5,
    this.maxStock = 100,
    this.allowMinusStock = false,
    this.weight = 0,
    this.dimensions = '',
    this.ppnPercent = 0,
    this.rewardPoints = 0,
    this.expiryDate,
    this.galleryImages = const [],
    this.primaryImage,
    this.multiUnits = const [],
    this.variantMatrix = const [],
    this.isLoading = false,
  });

  double get marginGeneralPercent => (sellPriceGeneral <= 0 || buyPrice <= 0) ? 0 : ((sellPriceGeneral - buyPrice) / sellPriceGeneral) * 100;

  ProductFormState copyWith({
    String? id, String? name, String? shortName, String? barcode, String? description,
    String? categoryId, String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? baseStock, double? minStock, double? maxStock, bool? allowMinusStock,
    double? weight, String? dimensions, double? ppnPercent, int? rewardPoints, DateTime? expiryDate,
    List<String>? galleryImages, String? primaryImage, List<UnitConversionModel>? multiUnits, List<VariantMatrixModel>? variantMatrix, bool? isLoading,
  }) {
    return ProductFormState(
      id: id ?? this.id, name: name ?? this.name, shortName: shortName ?? this.shortName, barcode: barcode ?? this.barcode,
      description: description ?? this.description, categoryId: categoryId ?? this.categoryId, subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand, warehouseLocation: warehouseLocation ?? this.warehouseLocation, tags: tags ?? this.tags,
      buyPrice: buyPrice ?? this.buyPrice, sellPriceGeneral: sellPriceGeneral ?? this.sellPriceGeneral,
      sellPriceTier1: sellPriceTier1 ?? this.sellPriceTier1, sellPriceTier2: sellPriceTier2 ?? this.sellPriceTier2, sellPriceTier3: sellPriceTier3 ?? this.sellPriceTier3,
      maxDiscountSales: maxDiscountSales ?? this.maxDiscountSales, isPriceLocked: isPriceLocked ?? this.isPriceLocked,
      baseStock: baseStock ?? this.baseStock, minStock: minStock ?? this.minStock, maxStock: maxStock ?? this.maxStock,
      allowMinusStock: allowMinusStock ?? this.allowMinusStock, weight: weight ?? this.weight, dimensions: dimensions ?? this.dimensions,
      ppnPercent: ppnPercent ?? this.ppnPercent, rewardPoints: rewardPoints ?? this.rewardPoints, expiryDate: expiryDate ?? this.expiryDate,
      galleryImages: galleryImages ?? this.galleryImages, primaryImage: primaryImage ?? this.primaryImage,
      multiUnits: multiUnits ?? this.multiUnits, variantMatrix: variantMatrix ?? this.variantMatrix, isLoading: isLoading ?? this.isLoading,
    );
  }
}

// =========================================================================
// 3. NOTIFIER - INI INTINYA
// =========================================================================

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}'));

  void resetForm() {
    state = ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}');
  }

  void updateFields({
    String? name, String? shortName, String? barcode, String? description, String? categoryId,
    String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? baseStock, double? minStock, double? maxStock, bool? allowMinusStock,
  }) {
    state = state.copyWith(
      name: name, shortName: shortName, barcode: barcode, description: description, categoryId: categoryId,
      subCategory: subCategory, brand: brand, warehouseLocation: warehouseLocation, tags: tags,
      buyPrice: buyPrice, sellPriceGeneral: sellPriceGeneral, sellPriceTier1: sellPriceTier1, sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3,
      maxDiscountSales: maxDiscountSales, isPriceLocked: isPriceLocked, baseStock: baseStock, minStock: minStock, maxStock: maxStock, allowMinusStock: allowMinusStock,
    );
  }

  // Dipanggil saat tap card product untuk EDIT
  void loadFromProductData(ProductData data) {
    state = ProductFormState(
      id: data.id,
      name: data.name,
      shortName: data.shortName ?? '',
      barcode: data.barcode ?? '',
      description: data.description ?? '',
      categoryId: data.categoryId ?? 'Umum',
      brand: data.brand ?? '',
      warehouseLocation: data.warehouseLocation ?? '',
      tags: data.tags ?? '',
      buyPrice: data.buyPrice,
      sellPriceGeneral: data.sellPriceGeneral,
      sellPriceTier1: data.sellPriceTier1 ?? 0,
      sellPriceTier2: data.sellPriceTier2 ?? 0,
      sellPriceTier3: data.sellPriceTier3 ?? 0,
      baseStock: data.stock,
      minStock: data.minStock,
      maxStock: data.maxStock ?? 100,
      isPriceLocked: data.isPriceLocked,
    );
  }

  // SAVE KE DRIFT - SINKRON DENGAN ProductPage StreamBuilder
  Future<void> saveToLocalDb(LocalDatabase db) async {
    state = state.copyWith(isLoading: true);
    try {
      final companion = ProductsCompanion(
        id: drift.Value(state.id),
        name: drift.Value(state.name),
        shortName: drift.Value(state.shortName),
        barcode: drift.Value(state.barcode.isEmpty ? null : state.barcode),
        description: drift.Value(state.description),
        categoryId: drift.Value(state.categoryId),
        brand: drift.Value(state.brand.isEmpty ? null : state.brand),
        warehouseLocation: drift.Value(state.warehouseLocation.isEmpty ? null : state.warehouseLocation),
        tags: drift.Value(state.tags.isEmpty ? null : state.tags),
        buyPrice: drift.Value(state.buyPrice),
        sellPriceGeneral: drift.Value(state.sellPriceGeneral),
        sellPriceTier1: drift.Value(state.sellPriceTier1),
        sellPriceTier2: drift.Value(state.sellPriceTier2),
        sellPriceTier3: drift.Value(state.sellPriceTier3),
        stock: drift.Value(state.baseStock),
        minStock: drift.Value(state.minStock),
        maxStock: drift.Value(state.maxStock),
        isPriceLocked: drift.Value(state.isPriceLocked),
        // Tambahkan field lain sesuai tabel kamu, contoh:
        // expiryDate: drift.Value(state.expiryDate),
      );

      await db.into(db.products).insertOnConflictUpdate(companion);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void addUnit(UnitConversionModel unit) => state = state.copyWith(multiUnits: [...state.multiUnits, unit]);
  void removeUnit(String id) => state = state.copyWith(multiUnits: state.multiUnits.where((u) => u.id != id).toList());

  void addVariantAutoSku({required String variantName, required double sellPrice, String? barcode}) {
    int maxIndex = 0;
    final RegExp regex = RegExp(r'-V(\d+)$');
    for (var v in state.variantMatrix) {
      final m = regex.firstMatch(v.sku);
      if (m != null) {
        final i = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (i > maxIndex) maxIndex = i;
      }
    }
    final newVariant = VariantMatrixModel(
      id: 'VAR-${DateTime.now().microsecondsSinceEpoch}',
      sku: '${state.id}-V${maxIndex + 1}',
      name: variantName,
      sellPrice: sellPrice,
      barcode: barcode,
    );
    state = state.copyWith(variantMatrix: [...state.variantMatrix, newVariant]);
  }

  void removeVariant(String id) => state = state.copyWith(variantMatrix: state.variantMatrix.where((v) => v.id != id).toList());

  void addImage(String path) {
    final images = [...state.galleryImages, path];
    state = state.copyWith(galleryImages: images, primaryImage: state.primaryImage ?? path);
  }
  void removeImage(String path) {
    final images = state.galleryImages.where((e) => e != path).toList();
    state = state.copyWith(galleryImages: images, primaryImage: state.primaryImage == path ? (images.isNotEmpty ? images.first : null) : state.primaryImage);
  }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) => ProductFormNotifier());