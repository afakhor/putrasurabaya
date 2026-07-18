import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model internal untuk menampung baris varian secara dinamis di Form
class VariantInputModel {
  final String id;
  final String name;
  final int conversion;
  final double sellPrice;
  final String? barcode;
  final String? imagePath; // Opsional

  VariantInputModel({
    required this.id,
    required this.name,
    this.conversion = 1,
    this.sellPrice = 0,
    this.barcode,
    this.imagePath,
  });

  VariantInputModel copyWith({
    String? name,
    int? conversion,
    double? sellPrice,
    String? barcode,
    String? imagePath,
  }) {
    return VariantInputModel(
      id: this.id,
      name: name ?? this.name,
      conversion: conversion ?? this.conversion,
      sellPrice: sellPrice ?? this.sellPrice,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

// State penampung seluruh data di Halaman Tambah Produk
class ProductFormState {
  final String id;
  final String name;
  final String categoryId;
  final double buyPrice;
  final double baseSellPrice;
  final double baseStock;
  final String? mainImagePath;
  final List<VariantInputModel> variants;
  final bool isLoading;

  ProductFormState({
    required this.id,
    this.name = '',
    this.categoryId = 'Umum',
    this.buyPrice = 0,
    this.baseSellPrice = 0,
    this.baseStock = 0,
    this.mainImagePath,
    this.variants = const [],
    this.isLoading = false,
  });

  ProductFormState copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? buyPrice,
    double? baseSellPrice,
    double? baseStock,
    String? mainImagePath,
    List<VariantInputModel>? variants,
    bool? isLoading,
  }) {
    return ProductFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      buyPrice: buyPrice ?? this.buyPrice,
      baseSellPrice: baseSellPrice ?? this.baseSellPrice,
      baseStock: baseStock ?? this.baseStock,
      mainImagePath: mainImagePath ?? this.mainImagePath,
      variants: variants ?? this.variants,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState(id: 'PRD-${DateTime.now().millisecondsSinceEpoch}'));

  void resetForm() {
    state = ProductFormState(id: 'PRD-${DateTime.now().millisecondsSinceEpoch}');
  }

  void updateName(String val) => state = state.copyWith(name: val);
  void updateCategory(String val) => state = state.copyWith(categoryId: val);
  void updateBuyPrice(double val) => state = state.copyWith(buyPrice: val);
  void updateBaseSellPrice(double val) => state = state.copyWith(baseSellPrice: val);
  void updateBaseStock(double val) => state = state.copyWith(baseStock: val);
  void updateMainImage(String? path) => state = state.copyWith(mainImagePath: path);

  // LOGIKA DINAMIS VARIANT LIST
  void addVariant() {
    final newVariant = VariantInputModel(
      id: 'VAR-${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      sellPrice: state.baseSellPrice, // default disamakan dulu dengan harga dasar
    );
    state = state.copyWith(variants: [...state.variants, newVariant]);
  }

  void removeVariant(String id) {
    state = state.copyWith(variants: state.variants.where((v) => v.id != id).toList());
  }

  void updateVariantItem(String id, VariantInputModel Function(VariantInputModel) updateBlock) {
    state = state.copyWith(
      variants: state.variants.map((v) => v.id == id ? updateBlock(v) : v).toList(),
    );
  }
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});
