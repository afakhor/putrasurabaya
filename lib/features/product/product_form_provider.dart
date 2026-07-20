import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model untuk penanganan matriks varian barang (Contoh: Ukuran Besi, Warna Cat)
class VariantMatrixModel {
  final String id;
  final String sku; // Format otomatis: [ParentSKU]-V1, [ParentSKU]-V2
  final String name; // Nama varian, misal: "Ukuran 8mm Banci"
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
  final String unitName; // Misal: "Dus", "Karton", "Bandel"
  final int conversion; // Jumlah isi kuantitas konversi ke Pcs dasar (Misal: 12)
  final double buyPrice; // HPP khusus level satuan ini
  final double sellPrice; // Harga jual khusus level satuan ini
  final String? barcode; // Barcode unik level satuan grosir

  UnitConversionModel({
    required this.id,
    required this.unitName,
    required this.conversion,
    required this.buyPrice,
    required this.sellPrice,
    this.barcode,
  });
}

/// State penampung seluruh data form inputan produk
class ProductFormState {
  // ==========================================
  // 1. PRODUCT IDENTITY SECTION (OWNER ONLY EDIT)
  // ==========================================
  final String id; // SKU Induk Utama (Auto-generated & Wajib Unik)
  final String name; // Nama Item Barang Lengkap
  final String shortName; // Nama Singkat Khusus Cetak Struk (Max 25 Karakter)
  final String barcode; // Barcode EAN13 atau QR Code Utama
  final String description; // Deskripsi Detail Katalog Produk

  // ==========================================
  // 2. KLASIFIKASI & TAG GROUPING REPORT
  // ==========================================
  final String categoryId; // Kategori Utama (Umum, Perkakas, Material)
  final String subCategory; // Sub-Kategori Lapangan
  final String brand; // Merk / Pabrikan Barang (Untuk Filter Salesman)
  final String warehouseLocation; // Posisi Rak / Gudang (Owner Only View)
  final String tags; // Tag Khusus Profit Report Grouping (Owner Only)

  // ==========================================
  // 3. PRICING ENGINE ENGINE (AUTOMATED MARGIN)
  // ==========================================
  final double buyPrice; // Harga Modal Dasar / HPP Utama (Owner Only View)
  final double sellPriceGeneral; // Harga Jual Umum / Eceran
  final double sellPriceTier1; // Harga Grosir Tingkat 1
  final double sellPriceTier2; // Harga Grosir Tingkat 2
  final double sellPriceTier3; // Harga Grosir Tingkat 3
  final double maxDiscountSales; // Batas Toleransi Diskon Nominal Salesman
  final bool isPriceLocked; // Status Kunci Harga / Status Aktif Barang

  // ==========================================
  // 4. STOCK CONTROL & COMPLIANCE
  // ==========================================
  final double baseStock;
  final double minStock;
  final double maxStock;
  final bool allowMinusStock;
  final double weight;
  final String dimensions;
  final double ppnPercent;
  final int rewardPoints;
  final DateTime? expiryDate;

  // ==========================================
  // 5. DATA KOLEKSI (MULTI IMAGE & MULTI SATUAN)
  // ==========================================
  final List<String> galleryImages; // Multi Gambar untuk Visual Katalog Sales
  final String? primaryImage; // Cover Utama Gambar Produk
  final List<UnitConversionModel> multiUnits; // List Konversi Satuan Grosir
  final List<VariantMatrixModel> variantMatrix; // List Matriks Varian Barang

  // Promo Data Snapshot
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

  // Getter Bantuan untuk Hitung Margin Keuntungan Umum Instan vs HPP
  double get marginGeneralPercent {
    if (sellPriceGeneral <= 0 || buyPrice <= 0) return 0;
    return ((sellPriceGeneral - buyPrice) / sellPriceGeneral) * 100;
  }

  // Getter Hitung Margin Grosir Tier 1 vs HPP
  double get marginTier1Percent {
    if (sellPriceTier1 <= 0 || buyPrice <= 0) return 0;
    return ((sellPriceTier1 - buyPrice) / sellPriceTier1) * 100;
  }

  // Getter Hitung Margin Grosir Tier 2 vs HPP
  double get marginTier2Percent {
    if (sellPriceTier2 <= 0 || buyPrice <= 0) return 0;
    return ((sellPriceTier2 - buyPrice) / sellPriceTier2) * 100;
  }

  // Getter Hitung Margin Grosir Tier 3 vs HPP
  double get marginTier3Percent {
    if (sellPriceTier3 <= 0 || buyPrice <= 0) return 0;
    return ((sellPriceTier3 - buyPrice) / sellPriceTier3) * 100;
  }

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

  // Reset data inputan kembali ke kondisi kosong dengan SKU Induk Baru
  void resetForm() => state = ProductFormState(id: 'SKU-${DateTime.now().millisecondsSinceEpoch}');

  // Update Field Dinamis
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
  // LOGIKA MATRIKS VARIAN (OTOMATISASI SKU FORMAT -V1)
  // ==========================================
  void addVariantAutoSku({required String variantName, required double sellPrice, String? barcode}) {
    // Menentukan suffix counter indeks berdasarkan jumlah item yang ada saat ini
    final int nextIndex = state.variantMatrix.length + 1;
    final String generatedSku = '${state.id}-V$nextIndex'; // Format Otomatis: SKUINDK-V1

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
  // MOCK DATA GENERATOR: SIMULASI BARANG PERKAKAS BANGUNAN
  // ==========================================
  void loadContohPerkakasBangunan() {
    state = ProductFormState(
      id: 'SKU-BRG-BAJA12',
      name: 'Besi Beton Ulir Krakatau Steel',
      shortName: 'Besi Beton Ulir 12mm',
      barcode: '8991234567890',
      description: 'Besi beton ulir standar SNI kekuatan penuh khusus struktur utama bangunan gedung.',
      categoryId: 'Perkakas Bangunan',
      subCategory: 'Besi & Baja',
      brand: 'Krakatau Steel',
      warehouseLocation: 'Rak Besi B-3 Barat',
      tags: 'Kategori-Profit-Tinggi, Fast-Moving-Proyek',
      buyPrice: 90000, // HPP Dasar per Pcs Rp 90.000
      sellPriceGeneral: 115000, // Margin eceran otomatis dihitung di UI
      sellPriceTier1: 108000,
      sellPriceTier2: 102000,
      sellPriceTier3: 97000,
      maxDiscountSales: 3000,
      isPriceLocked: true,
      baseStock: 150,
      minStock: 20,
    );

    // Otomatis Tambah Multi Satuan
    addUnit(UnitConversionModel(id: 'U1', unitName: 'Bandel / Ikat', conversion: 10, buyPrice: 880000, sellPrice: 1000000));
    addUnit(UnitConversionModel(id: 'U2', unitName: 'Karton Besar', conversion: 50, buyPrice: 4300000, sellPrice: 4850000));

    // Otomatis Tambah Matriks Varian dengan SKU Berformat -V1, -V2
    addVariantAutoSku(variantName: 'Ukuran Diameter 10mm Full', sellPrice: 95000);
    addVariantAutoSku(variantName: 'Ukuran Diameter 12mm Full', sellPrice: 115000);
    addVariantAutoSku(variantName: 'Ukuran Diameter 14mm Full', sellPrice: 140000);
  }
}

// Global Provider
final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) => ProductFormNotifier());
