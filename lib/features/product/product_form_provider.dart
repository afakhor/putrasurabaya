import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model untuk penanganan matriks varian barang (Contoh: Ukuran Besi, Warna Cat)
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

  VariantMatrixModel copyWith({
    String? id, String? sku, String? name, String? barcode, double? stock, double? sellPrice
  }) {
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

/// Model untuk multi-satuan bertingkat (Contoh: Pcs -> Dus -> Karton)
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

  // Ditambahkan copyWith untuk antisipasi fitur edit sub-satuan di masa depan
  UnitConversionModel copyWith({
    String? id, String? unitName, int? conversion, double? buyPrice, double? sellPrice, String? barcode
  }) {
    return UnitConversionModel(
      id: id ?? this.id,
      unitName: unitName ?? this.unitName,
      conversion: conversion ?? this.conversion,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      barcode: barcode ?? this.barcode,
    );
  }
}

/// State penampung seluruh data form inputan produk
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

  double get marginGeneralPercent => (sellPriceGeneral <= 0 || buyPrice <= 0) ? 0 : ((sellPriceGeneral - buyPrice) / sellPriceGeneral) * 100;
  double get marginTier1Percent => (sellPriceTier1 <= 0 || buyPrice <= 0) ? 0 : ((sellPriceTier1 - buyPrice) / sellPriceTier1) * 100;
  double get marginTier2Percent => (sellPriceTier2 <= 0 || buyPrice <= 0) ? 0 : ((sellPriceTier2 - buyPrice) / sellPriceTier2) * 100;
  double get marginTier3Percent => (sellPriceTier3 <= 0 || buyPrice <= 0) ? 0 : ((sellPriceTier3 - buyPrice) / sellPriceTier3) * 100;

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

/// Kontroler Notifier Form Manajemen Penambahan & Pembaruan Master Data
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

  // ==========================================
  // LOGIKA MULTI-IMAGE KATALOG
  // ==========================================
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

  // ==========================================
  // LOGIKA MULTI-UNIT / KONVERSI SATUAN
  // ==========================================
  void addUnit(UnitConversionModel unit) => state = state.copyWith(multiUnits: [...state.multiUnits, unit]);
  void removeUnit(String id) => state = state.copyWith(multiUnits: state.multiUnits.where((u) => u.id != id).toList());

  // ==========================================
  // LOGIKA MATRIKS VARIAN (PERBAIKAN INDEKS SKU)
  // ==========================================
  void addVariantAutoSku({required String variantName, required double sellPrice, String? barcode}) {
    // Solusi Aman: Cari angka akhiran '-V' terbesar dari list yang ada menggunakan Regex
    int maxIndex = 0;
    final RegExp regex = RegExp(r'-V(\d+)$');

    for (var variant in state.variantMatrix) {
      final match = regex.firstMatch(variant.sku);
      if (match != null) {
        final int index = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (index > maxIndex) maxIndex = index;
      }
    }

    final String generatedSku = '${state.id}-V${maxIndex + 1}'; 

    final newVariant = VariantMatrixModel(
      id: 'VAR-${DateTime.now().microsecondsSinceEpoch}',
      sku: generatedSku,
      name: variantName,
      sellPrice: sellPrice,
      barcode: barcode,
      stock: 0,
    );

    state = state.copyWith(variantMatrix: [...state.variantMatrix, newVariant]);
  }

  void removeVariant(String id) => state = state.copyWith(variantMatrix: state.variantMatrix.where((v) => v.id != id).toList());

  // ==========================================
  // MOCK DATA GENERATOR (OPTIMAL: HANYA 1 KALI TRIGGER STATE)
  // ==========================================
  void loadContohPerkakasBangunan() {
    const String mockId = 'SKU-BRG-BAJA12';

    // 1. Buat data multi unit secara lokal
    final List<UnitConversionModel> mockUnits = [
      UnitConversionModel(id: 'U1', unitName: 'Bandel / Ikat', conversion: 10, buyPrice: 880000, sellPrice: 1000000),
      UnitConversionModel(id: 'U2', unitName: 'Karton Besar', conversion: 50, buyPrice: 4300000, sellPrice: 4850000),
    ];

    // 2. Buat data matriks varian secara lokal
    final List<VariantMatrixModel> mockVariants = [
      VariantMatrixModel(
        id: 'VAR-1',
        sku: '$mockId-V1',
        name: 'Ukuran Diameter 10mm Full',
        sellPrice: 95000,
      ),
      VariantMatrixModel(
        id: 'VAR-2',
        sku: '$mockId-V2',
        name: 'Ukuran Diameter 12mm Full',
        sellPrice: 115000,
      ),
      VariantMatrixModel(
        id: 'VAR-3',
        sku: '$mockId-V3',
        name: 'Ukuran Diameter 14mm Full',
        sellPrice: 140000,
      ),
    ];

    // 3. Masukkan semua langsung saat inisialisasi state baru (Cukup 1 kali render UI)
    state = ProductFormState(
      id: mockId,
      name: 'Besi Beton Ulir Krakatau Steel',
      shortName: 'Besi Beton Ulir 12mm',
      barcode: '8991234567890',
      description: 'Besi beton ulir standar SNI kekuatan penuh khusus struktur utama bangunan gedung.',
      categoryId: 'Perkakas Bangunan',
      subCategory: 'Besi & Baja',
      brand: 'Krakatau Steel',
      warehouseLocation: 'Rak Besi B-3 Barat',
      tags: 'Kategori-Profit-Tinggi, Fast-Moving-Proyek',
      buyPrice: 90000,
      sellPriceGeneral: 115000,
      sellPriceTier1: 108000,
      sellPriceTier2: 102000,
      sellPriceTier3: 97000,
      maxDiscountSales: 3000,
      isPriceLocked: true,
      baseStock: 150,
      minStock: 20,
      multiUnits: mockUnits,
      variantMatrix: mockVariants,
    );
  }
}

// Global Provider
final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) => ProductFormNotifier());
