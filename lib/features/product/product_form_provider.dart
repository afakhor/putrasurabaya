import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =========================================================================
// 1. DATA MODELS (MODEL DATA BARANG & VARIAN)
// =========================================================================

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

// =========================================================================
// 2. STATE & NOTIFIER (LOGIKA MANAJEMEN STATE RIVERPOD)
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

  void addUnit(UnitConversionModel unit) => state = state.copyWith(multiUnits: [...state.multiUnits, unit]);
  void removeUnit(String id) => state = state.copyWith(multiUnits: state.multiUnits.where((u) => u.id != id).toList());

  void addVariantAutoSku({required String variantName, required double sellPrice, String? barcode}) {
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

  void loadContohPerkakasBangunan() {
    const String mockId = 'SKU-BRG-BAJA12';

    final List<UnitConversionModel> mockUnits = [
      UnitConversionModel(id: 'U1', unitName: 'Bandel / Ikat', conversion: 10, buyPrice: 880000, sellPrice: 1000000),
      UnitConversionModel(id: 'U2', unitName: 'Karton Besar', conversion: 50, buyPrice: 4300000, sellPrice: 4850000),
    ];

    final List<VariantMatrixModel> mockVariants = [
      VariantMatrixModel(id: 'VAR-1', sku: '$mockId-V1', name: 'Ukuran Diameter 10mm Full', sellPrice: 95000),
      VariantMatrixModel(id: 'VAR-2', sku: '$mockId-V2', name: 'Ukuran Diameter 12mm Full', sellPrice: 115000),
      VariantMatrixModel(id: 'VAR-3', sku: '$mockId-V3', name: 'Ukuran Diameter 14mm Full', sellPrice: 140000),
    ];

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

// =========================================================================
// 3. UI LAYER (HALAMAN INPUT FORM PRODUK)
// =========================================================================

class FormProductPage extends ConsumerStatefulWidget {
  const FormProductPage({super.key});

  @override
  ConsumerState<FormProductPage> createState() => _FormProductPageState();
}

class _FormProductPageState extends ConsumerState<FormProductPage> {
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _warehouseCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _tier1Ctrl = TextEditingController();
  final _tier2Ctrl = TextEditingController();
  final _tier3Ctrl = TextEditingController();
  final _baseStockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose(); _shortNameCtrl.dispose(); _barcodeCtrl.dispose();
    _descCtrl.dispose(); _brandCtrl.dispose(); _warehouseCtrl.dispose();
    _tagsCtrl.dispose(); _buyPriceCtrl.dispose(); _sellPriceCtrl.dispose();
    _tier1Ctrl.dispose(); _tier2Ctrl.dispose(); _tier3Ctrl.dispose();
    _baseStockCtrl.dispose(); _minStockCtrl.dispose();
    super.dispose();
  }

  void _showAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final convCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Satuan Bertingkat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Satuan (Dus/Karton)')),
              TextField(controller: convCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Isi Konversi (Pcs)')),
              TextField(controller: buyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli Satuan')),
              TextField(controller: sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual Satuan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && convCtrl.text.isNotEmpty) {
                ref.read(productFormProvider.notifier).addUnit(
                  UnitConversionModel(
                    id: 'UNIT-${DateTime.now().millisecondsSinceEpoch}',
                    unitName: nameCtrl.text,
                    conversion: int.tryParse(convCtrl.text) ?? 1,
                    buyPrice: double.tryParse(buyCtrl.text) ?? 0,
                    sellPrice: double.tryParse(sellCtrl.text) ?? 0,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _showAddVariantDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Varian Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Varian (Ukuran/Warna)')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual Varian')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(productFormProvider.notifier).addVariantAutoSku(
                  variantName: nameCtrl.text,
                  sellPrice: double.tryParse(priceCtrl.text) ?? 0,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProductFormState>(productFormProvider, (prev, next) {
      if (next.name != _nameCtrl.text) _nameCtrl.text = next.name;
      if (next.shortName != _shortNameCtrl.text) _shortNameCtrl.text = next.shortName;
      if (next.barcode != _barcodeCtrl.text) _barcodeCtrl.text = next.barcode;
      if (next.description != _descCtrl.text) _descCtrl.text = next.description;
      if (next.brand != _brandCtrl.text) _brandCtrl.text = next.brand;
      if (next.warehouseLocation != _warehouseCtrl.text) _warehouseCtrl.text = next.warehouseLocation;
      if (next.tags != _tagsCtrl.text) _tagsCtrl.text = next.tags;

      _buyPriceCtrl.text = next.buyPrice == 0 ? '' : next.buyPrice.toStringAsFixed(0);
      _sellPriceCtrl.text = next.sellPriceGeneral == 0 ? '' : next.sellPriceGeneral.toStringAsFixed(0);
      _tier1Ctrl.text = next.sellPriceTier1 == 0 ? '' : next.sellPriceTier1.toStringAsFixed(0);
      _tier2Ctrl.text = next.sellPriceTier2 == 0 ? '' : next.sellPriceTier2.toStringAsFixed(0);
      _tier3Ctrl.text = next.sellPriceTier3 == 0 ? '' : next.sellPriceTier3.toStringAsFixed(0);
      _baseStockCtrl.text = next.baseStock == 0 ? '' : next.baseStock.toStringAsFixed(0);
      _minStockCtrl.text = next.minStock == 0 ? '' : next.minStock.toStringAsFixed(0);
    });

    final formState = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Form SKU: ${formState.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber, size: 28),
            tooltip: 'Load Data Mock Toko Bangunan',
            onPressed: () => notifier.loadContohPerkakasBangunan(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('1. Identitas Master Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Lengkap Produk', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(name: v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Deskripsi Produk', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(description: v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shortNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Cetak Struk', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(shortName: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(barcode: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand / Merk', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(brand: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _warehouseCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasi Rak Gudang', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(warehouseLocation: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(labelText: 'Tags Proyek (Pisahkan dengan koma)', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(tags: v),
          ),
          
          const Divider(height: 32),

          const Text('2. Struktur HPP & Harga Grosir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buyPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Beli (HPP)', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(buyPrice: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sellPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Jual Umum', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceGeneral: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Margin Keuntungan Eceran: ${formState.marginGeneralPercent.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tier1Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 1', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier1: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tier2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 2', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier2: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tier3Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 3', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier3: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          const Text('3. Kontrol Batas Stok Pcs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _baseStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(baseStock: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Minimum Kritis', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(minStock: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4. Konversi Multi-Satuan (${formState.multiUnits.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(onPressed: _showAddUnitDialog, icon: const Icon(Icons.add), label: const Text('Tambah Satuan')),
            ],
          ),
          ...formState.multiUnits.map((unit) => Card(
                child: ListTile(
                  title: Text('${unit.unitName} (1 ${unit.unitName} = ${unit.conversion} Pcs)'),
                  subtitle: Text('Modal: Rp ${unit.buyPrice.toStringAsFixed(0)} | Jual: Rp ${unit.sellPrice.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => notifier.removeUnit(unit.id),
                  ),
                ),
              )),

          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5. Matriks Varian Barang (${formState.variantMatrix.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(onPressed: _showAddVariantDialog, icon: const Icon(Icons.add_box), label: const Text('Buat Varian')),
            ],
          ),
          ...formState.variantMatrix.map((varData) => Card(
                color: Colors.orange.withOpacity(0.04),
                child: ListTile(
                  leading: Text(varData.sku, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.orange)),
                  title: Text(varData.name),
                  subtitle: Text('Harga Jual Varian: Rp ${varData.sellPrice.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => notifier.removeVariant(varData.id),
                  ),
                ),
              )),

          const SizedBox(height: 40),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A65A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formState.name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Nama master barang tidak boleh kosong!')),
                );
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('SIMPAN MASTER UTAMA BARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
