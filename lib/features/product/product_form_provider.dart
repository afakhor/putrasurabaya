import 'package:flutter_riverpod/flutter_riverpod.dart';

class VariantMatrixModel {
  final String id;
  final String sku;
  final String name;
  final String? barcode;
  final double stock;
  final double sellPrice;

  VariantMatrixModel({
    required this.id, required this.sku, required this.name, this.barcode, this.stock = 0, this.sellPrice = 0
  });
}

class UnitConversionModel {
  final String id;
  final String unitName;
  final int conversion;
  final double buyPrice;
  final double sellPrice;
  final String? barcode;

  UnitConversionModel({
    required this.id, required this.unitName, required this.conversion, required this.buyPrice, required this.sellPrice, this.barcode
  });
}

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

  // Pricing Engine
  final double buyPrice;
  final double sellPriceGeneral;
  final double sellPriceTier1;
  final double sellPriceTier2;
  final double sellPriceTier3;
  final double maxDiscountSales;
  final bool isPriceLocked;

  // Stock Control
  final double baseStock;
  final double minStock;
  final double maxStock;
  final bool allowMinusStock;

  // Compliance
  final double weight;
  final String dimensions;
  final double ppnPercent;
  final int rewardPoints;
  final DateTime? expiryDate;

  // Lists Data
  final List<String> galleryImages;
  final String? primaryImage;
  final List<UnitConversionModel> multiUnits;
  final List<VariantMatrixModel> variantMatrix;
  
  // Promotion Snapshot (Read/Write Owner, Read Only Sales)
  final double promoDiscountPercent;
  final double promoDiscountNominal;
  final DateTime? promoStart;
  final DateTime? promoEnd;

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
    this.promoDiscountPercent = 0,
    this.promoDiscountNominal = 0,
    this.promoStart,
    this.promoEnd,
    this.isLoading = false,
  });

  ProductFormState copyWith({
    String? id, String? name, String? shortName, String? barcode, String? description,
    String? categoryId, String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? baseStock, double? minStock, double? maxStock, bool? allowMinusStock,
    double? weight, String? dimensions, double? ppnPercent, int? rewardPoints, DateTime? expiryDate,
    List<String>? galleryImages, String? primaryImage, List<UnitConversionModel>? multiUnits, List<VariantMatrixModel>? variantMatrix,
    double? promoDiscountPercent, double? promoDiscountNominal, DateTime? promoStart, DateTime? promoEnd, bool? isLoading,
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
      baseStock: baseStock ?? this.baseStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      allowMinusStock: allowMinusStock ?? this.allowMinusStock,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      expiryDate: expiryDate ?? this.expiryDate,
      galleryImages: galleryImages ?? this.galleryImages,
      primaryImage: primaryImage ?? this.primaryImage,
      multiUnits: multiUnits ?? this.multiUnits,
      variantMatrix: variantMatrix ?? this.variantMatrix,
      promoDiscountPercent: promoDiscountPercent ?? this.promoDiscountPercent,
      promoDiscountNominal: promoDiscountNominal ?? this.promoDiscountNominal,
      promoStart: promoStart ?? this.promoStart,
      promoEnd: promoEnd ?? this.promoEnd,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}'));

  void resetForm() => state = ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}');

  void updateFields({
    String? name, String? shortName, String? barcode, String? description, String? categoryId,
    String? subCategory, String? brand, String? warehouseLocation, String? tags,
    double? buyPrice, double? sellPriceGeneral, double? sellPriceTier1, double? sellPriceTier2, double? sellPriceTier3,
    double? maxDiscountSales, bool? isPriceLocked, double? baseStock, double? minStock, double? maxStock, bool? allowMinusStock,
    double? weight, String? dimensions, double? ppnPercent, int? rewardPoints, DateTime? expiryDate,
    double? promoPct, double? promoNom, DateTime? pStart, DateTime? pEnd,
  }) {
    state = state.copyWith(
      name: name, shortName: shortName, barcode: barcode, description: description, categoryId: categoryId,
      subCategory: subCategory, brand: brand, warehouseLocation: warehouseLocation, tags: tags,
      buyPrice: buyPrice, sellPriceGeneral: sellPriceGeneral, sellPriceTier1: sellPriceTier1, sellPriceTier2: sellPriceTier2, sellPriceTier3: sellPriceTier3,
      maxDiscountSales: maxDiscountSales, isPriceLocked: isPriceLocked, baseStock: baseStock, minStock: minStock, maxStock: maxStock, allowMinusStock: allowMinusStock,
      weight: weight, dimensions: dimensions, ppnPercent: ppnPercent, rewardPoints: rewardPoints, expiryDate: expiryDate,
      promoDiscountPercent: promoPct, promoDiscountNominal: promoNom, promoStart: pStart, promoEnd: pEnd,
    );
  }

  // Multi-Image Logic
  void addImage(String path) {
    final images = [...state.galleryImages, path];
    state = state.copyWith(galleryImages: images, primaryImage: state.primaryImage ?? path);
  }

  void reorderGallery(int oldIndex, int newIndex) {
    final List<String> images = List.from(state.galleryImages);
    if (newIndex > oldIndex) newIndex -= 1;
    final String item = images.removeAt(oldIndex);
    images.insert(newIndex, item);
    state = state.copyWith(galleryImages: images);
  }

  void setPrimaryImage(String path) => state = state.copyWith(primaryImage: path);
  void removeImage(String path) {
    final images = state.galleryImages.where((img) => img != path).toList();
    String? prim = state.primaryImage == path ? (images.isNotEmpty ? images.first : null) : state.primaryImage;
    state = state.copyWith(galleryImages: images, primaryImage: prim);
  }

  // Multi Unit Logic
  void addUnit(UnitConversionModel unit) => state = state.copyWith(multiUnits: [...state.multiUnits, unit]);
  void removeUnit(String id) => state = state.copyWith(multiUnits: state.multiUnits.where((u) => u.id != id).toList());

  // Variant Matrix Logic
  void addVariant(VariantMatrixModel variant) => state = state.copyWith(variantMatrix: [...state.variantMatrix, variant]);
  void removeVariant(String id) => state = state.copyWith(variantMatrix: state.variantMatrix.where((v) => v.id != id).toList());
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) => ProductFormNotifier());
