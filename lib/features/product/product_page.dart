import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

// Impor file lokal Anda
import '../../core/database/app_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../core/services/sync_service.dart';
import 'product_form_provider.dart';
import 'config.dart'; // Menghubungkan ke file konfigurasi tema Anda

// Menghubungkan konsterna warna lokal langsung ke static variable GoldenGreenTheme di config.dart
const Color dominantGold = GoldenGreenTheme.dominantGold;
const Color greenGold = GoldenGreenTheme.greenGold;
const Color brightHighlight = GoldenGreenTheme.brightHighlight;
const Color textEspresso = GoldenGreenTheme.textEspresso;
const Color textSubdued = GoldenGreenTheme.textSubdued;

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  bool _isFabExtended = true;

  @override
  void initState() {
    super.initState();
    // Algoritma Otomatis Mengecilkan FAB Saat Di-scroll ke Bawah agar menghemat layar HP
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabExtended) setState(() => _isFabExtended = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabExtended) setState(() => _isFabExtended = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);

    return Scaffold(
      // PERUBAHAN UTAMA: Membungkus area form dengan background mesh cair organik dari config.dart
      // Karena buildFluidBackground sudah memiliki SafeArea di dalamnya, kita tidak perlu membungkusnya lagi di sini.
      body: GoldenGreenTheme.buildFluidBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildHeaderTitle(),
              const SizedBox(height: 20),

              // 1. KELOMPOK DATA UTAMA
              _buildFormSection(
                title: 'Informasi Dasar Produk',
                icon: Icons.inventory,
                children: [
                  TextFormField(
                    initialValue: formState.id,
                    decoration: const InputDecoration(labelText: 'ID Produk (Otomatis)', prefixIcon: Icon(Icons.vpn_key)),
                    readOnly: true,
                    style: const TextStyle(color: textSubdued),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nama Produk', prefixIcon: Icon(Icons.shopping_bag)),
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: textEspresso),
                    validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                    onChanged: formNotifier.updateName,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(formState, formNotifier),
                ],
              ),
              const SizedBox(height: 16),

              // 2. KELOMPOK GAMBAR UTAMA & FALLBACK LOGIC VISUAL
              _buildFormSection(
                title: 'Aset Gambar Utama',
                icon: Icons.image,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        formNotifier.updateMainImage('/storage/emulated/0/Download/produk_utama.jpg');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: greenGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: greenGold, width: 1.5),
                        ),
                        child: formState.mainImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(formState.mainImagePath!), fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 40, color: textEspresso),
                                  SizedBox(height: 8),
                                  Text('Ketuk untuk Unggah Gambar Utama', style: TextStyle(color: textEspresso, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. KELOMPOK HARGA & STOK
              _buildFormSection(
                title: 'Harga & Manajemen Stok',
                icon: Icons.monetization_on,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Beli (Modal)', prefixText: 'Rp '),
                          onChanged: (val) => formNotifier.updateBuyPrice(double.tryParse(val.replaceAll('.', '')) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Jual Dasar', prefixText: 'Rp '),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          onChanged: (val) => formNotifier.updateBaseSellPrice(double.tryParse(val.replaceAll('.', '')) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Stok Saat Ini', prefixIcon: Icon(Icons.warehouse)),
                    validator: (val) => val == null || val.isEmpty ? 'Stok awal wajib diisi' : null,
                    onChanged: (val) => formNotifier.updateBaseStock(double.tryParse(val) ?? 0),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. KELOMPOK DINAMIS VARIANT INPUT
              _buildVariantSection(formState, formNotifier),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),

      // INTERAKTIF EXTENDED FAB DENGAN AKSEN WARNA BRIGHT 10% KONTRAST TINGGI
      floatingActionButton: FloatingActionButton.extended(
        isExtended: _isFabExtended,
        backgroundColor: brightHighlight, 
        icon: const Icon(Icons.save_as, color: textEspresso, size: 26),
        label: const Text(
          'Simpan & Sinkron',
          style: TextStyle(color: textEspresso, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: formState.isLoading ? null : () => _prosesSimpanKeDuaDatabase(formState),
      ),
    );
  }

  // ===================== UI SUB-COMPONENTS WIDGETS =====================

  Widget _buildHeaderTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANAJEMEN PRODUK BARU',
          // FIX: Mengubah FontWeight.black yang salah ketik menjadi FontWeight.w900 bawaan SDK Flutter
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textEspresso, letterSpacing: 1.1),
        ),
        Text(
          'UD. Putra Surabaya POS Engine System',
          style: TextStyle(fontSize: 13, color: textSubdued, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFormSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // Semi transparan premium melapis background liquid agar teks tetap terbaca tajam
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: textEspresso.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: greenGold, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textEspresso)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(ProductFormState state, ProductFormNotifier notifier) {
    return DropdownButtonFormField<String>(
      value: state.categoryId,
      decoration: const InputDecoration(labelText: 'Kategori Produk', prefixIcon: Icon(Icons.category)),
      items: ['Umum', 'Makanan', 'Minuman', 'Grosir'].map((e) {
        return DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: textEspresso)));
      }).toList(),
      onChanged: (val) => notifier.updateCategory(val ?? 'Umum'),
    );
  }

  Widget _buildVariantSection(ProductFormState state, ProductFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // FIX: Mengubah MainAxisAlignment.between yang typo menjadi MainAxisAlignment.spaceBetween
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Varian & Konversi Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textEspresso)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: greenGold, foregroundColor: Colors.white),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Tambah Varian'),
              onPressed: notifier.addVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.variants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Tidak ada varian tambahan (Hanya Satuan Base / Tunggal)', style: TextStyle(color: textEspresso))),
          ),
        ...state.variants.map((variant) {
          final bool isUsingFallbackImage = variant.imagePath == null;
          final String? displayedImagePath = variant.imagePath ?? state.mainImagePath;

          return Card(
            color: Colors.white.withOpacity(0.95),
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          notifier.updateVariantItem(variant.id, (v) => v.copyWith(imagePath: '/storage/v_spesifik.jpg'));
                        },
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isUsingFallbackImage ? greenGold : Colors.blue, width: 2),
                          ),
                          child: displayedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(File(displayedImagePath), fit: BoxFit.cover),
                                )
                              : const Icon(Icons.add_a_photo, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Nama Varian (Contoh: Dus / Renceng)', isDense: true),
                              onChanged: (val) => notifier.updateVariantItem(variant.id, (v) => v.copyWith(name: val)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => notifier.removeVariant(variant.id),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Isi Konversi', isDense: true, suffixText: 'pcs'),
                          onChanged: (val) => notifier.updateVariantItem(variant.id, (v) => v.copyWith(conversion: int.tryParse(val) ?? 1)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Jual Varian', isDense: true, prefixText: 'Rp '),
                          onChanged: (val) => notifier.updateVariantItem(variant.id, (v) => v.copyWith(sellPrice: double.tryParse(val.replaceAll('.', '')) ?? 0)),
                        ),
                      ),
                    ],
                  ),
                  if (isUsingFallbackImage && state.mainImagePath != null)
                    const Padding(
                      // FIX: Mengubah objek fiktif EdgeInsets.top(6.0) menjadi EdgeInsets.only(top: 6.0) sesuai standar Flutter
                      padding: EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: greenGold),
                          SizedBox(width: 4),
                          Text('Gambar otomatis menduplikasi gambar utama produk.', style: TextStyle(fontSize: 10, color: textSubdued, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===================== ALGORITMA PERSISTENSI DATA FORM =====================

  Future<void> _prosesSimpanKeDuaDatabase(ProductFormState dataForm) async {
    if (!_formKey.currentState!.validate()) return;

    final dbLokal = ref.read(localDatabaseProvider);
    final dbCloud = ref.read(firestoreServiceProvider);

    try {
      await dbLokal.into(dbLokal.products).insert(
        ProductsCompanion.insert(
          id: dataForm.id,
          name: dataForm.name,
          buyPrice: Value(dataForm.buyPrice),
          sellPrice: Value(dataForm.baseSellPrice),
          stock: Value(dataForm.baseStock),
          unitBase: const Value('pcs'),
        ),
      );

      for (var variant in dataForm.variants) {
        await dbLokal.into(dbLokal.productUnits).insert(
          ProductUnitsCompanion.insert(
            id: variant.id,
            productId: dataForm.id,
            unitName: variant.name.isEmpty ? 'Varian' : variant.name,
            conversion: variant.conversion,
            sellingPrice: variant.sellPrice,
          ),
        );
      }

      await dbCloud.tambahProdukCloud(
        name: dataForm.name,
        buyPrice: dataForm.buyPrice,
        sellPrice: dataForm.baseSellPrice,
        stock: dataForm.baseStock.toInt(),
        category: dataForm.categoryId,
      );

      ref.read(syncServiceProvider).syncLocalToCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk & Varian Berhasil Disimpan di Lokal & Cloud!'), backgroundColor: greenGold),
        );
        ref.read(productFormProvider.notifier).resetForm();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kesalahan Simpan: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
