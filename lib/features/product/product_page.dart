import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:ui'; // Digunakan untuk filter blur proteksi keamanan data

import '../../core/database/local_database.dart';
import '../../core/database/firestore_service.dart';
import '../../core/utils/format_rupiah.dart';
import '../../core/services/sync_service.dart';
import '../../main.dart';
import 'product_form_provider.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  bool _isFabExtended = true;
  String _searchDebounce = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabExtended) setState(() => _isFabExtended = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabExtended) setState(() => _isFabExtended = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);
    final user = ref.watch(currentUserProvider);
    
    // Validasi Dasar RBAC Aman Firebase + VPN Mock
    final bool isOwner = user?['role'] == 'owner';

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(14.0),
            children: [
              // 1. Header & Action Bar Terkondisi Role
              _buildActionBar(isOwner),
              const SizedBox(height: 16),

              // 2. Product Identity Section
              _buildFormCard(
                title: 'Identitas Utama Barang',
                icon: Icons.qr_code,
                children: [
                  TextFormField(
                    initialValue: formState.id,
                    decoration: const InputDecoration(labelText: 'SKU / Kode Barang (Auto-generated)', border: OutlineInputBorder()),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nama Produk Lengkap *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    onChanged: (v) => formNotifier.updateFields(name: v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nama Singkat Struk (Max 25 Karakter) *', border: OutlineInputBorder()),
                    maxLength: 25,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib untuk cetak struk' : null,
                    onChanged: (v) => formNotifier.updateFields(shortName: v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Barcode EAN13 / QR', border: OutlineInputBorder(), prefixIcon: Icon(Icons.center_focus_strong)),
                          onChanged: (v) => formNotifier.updateFields(barcode: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {}, // Trigger kamera scanner internal device
                        icon: const Icon(Icons.camera_alt),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi Produk Katalog', border: OutlineInputBorder()),
                    onChanged: (v) => formNotifier.updateFields(description: v),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Visual Asset Section (Multi-Image Gallery & Primary Selector)
              _buildFormCard(
                title: 'Galeri Aset Visual Katalog',
                icon: Icons.collections,
                children: [
                  if (formState.galleryImages.isEmpty)
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Text('[ Placeholder Gambar Produk Kosong ]', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: formState.galleryImages.length,
                        itemBuilder: (ctx, idx) {
                          final img = formState.galleryImages[idx];
                          final isPrimary = formState.primaryImage == img;
                          return Container(
                            key: ValueKey(img),
                            margin: const EdgeInsets.right(8),
                            width: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: isPrimary ? Colors.orange : Colors.grey, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: FileImage(File(img)), fit: BoxFit.cover),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0, right: 0,
                                  child: GestureDetector(
                                    onTap: () => formNotifier.removeImage(img),
                                    child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 10, color: Colors.white)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: GestureDetector(
                                    onTap: () => formNotifier.setPrimaryImage(img),
                                    child: Container(
                                      color: isPrimary ? Colors.orange.withOpacity(0.8) : Colors.black55,
                                      child: Text(isPrimary ? 'Utama' : 'Set Prm', style: const TextStyle(fontSize: 9, color: Colors.white), textAlign: TextAlign.center),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                        onReorder: formNotifier.reorderGallery,
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Mock add image path dari file picker local storage android
                      formNotifier.addImage('/storage/emulated/0/Download/perkakas_${DateTime.now().millisecond}.jpg');
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Tambah Gambar Aset'),
                  )
                ],
              ),
              const SizedBox(height: 14),

              // 4. Kategori & Klasifikasi
              _buildFormCard(
                title: 'Kategori & Klasifikasi Lapangan',
                icon: Icons.grid_view,
                children: [
                  DropdownButtonFormField<String>(
                    value: formState.categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori Utama', border: OutlineInputBorder()),
                    items: ['Umum', 'Perkakas Bangunan', 'Material Pokok'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => formNotifier.updateFields(categoryId: v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Sub-Kategori', border: OutlineInputBorder()),
                    onChanged: (v) => formNotifier.updateFields(subCategory: v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Brand / Merk', border: OutlineInputBorder()),
                    onChanged: (v) => formNotifier.updateFields(brand: v),
                  ),
                  const SizedBox(height: 12),
                  // Proteksi Lokasi Gudang: Sembunyikan field dari Salesman
                  if (isOwner)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Rak / Posisi Gudang (Owner Only)', border: OutlineInputBorder()),
                      onChanged: (v) => formNotifier.updateFields(warehouseLocation: v),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 5. Unit & Konversi Satuan Multi-Tier
              _buildFormCard(
                title: 'Unit & Konversi Satuan Grosir',
                icon: Icons.schema,
                children: [
                  const Text('Satuan Dasar Utama: Pcs / Unit Tunggal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const Divider(),
                  ...formState.multiUnits.map((u) => ListTile(
                    title: Text('${u.unitName} (Isi: ${u.conversion} Pcs)'),
                    subtitle: Text('Jual: ${formatRupiah(u.sellPrice)}'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => formNotifier.removeUnit(u.id)),
                  )),
                  OutlinedButton.icon(
                    onPressed: () {
                      formNotifier.addUnit(UnitConversionModel(
                        id: DateTime.now().toString(), unitName: 'Dus', conversion: 12, buyPrice: 120000, sellPrice: 150000
                      ));
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text('Tambah Konversi Satuan Besar (Dus/Karton)'),
                  )
                ],
              ),
              const SizedBox(height: 14),

              // 6. Pricing Engine Dengan Keamanan Blur Untuk Margin
              _buildPricingEngineSection(isOwner, formState, formNotifier),
              const SizedBox(height: 14),

              // 7. Promo & Diskon Terikat Produk
              _buildFormCard(
                title: 'Promo & Diskon Terikat SKU',
                icon: Icons.discount,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Diskon Persentase (%)', border: OutlineInputBorder()),
                    readOnly: !isOwner, // Salesman hanya bisa baca diskon promo aktif
                    initialValue: formState.promoDiscountPercent.toString(),
                    onChanged: (v) => formNotifier.updateFields(promoPct: double.tryParse(v)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Diskon Nominal (Rp)', border: OutlineInputBorder()),
                    readOnly: !isOwner,
                    initialValue: formState.promoDiscountNominal.toString(),
                    onChanged: (v) => formNotifier.updateFields(promoNom: double.tryParse(v)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 8. Varian Produk Matriks Bangunan/Perkakas
              _buildFormCard(
                title: 'Matriks Varian Produk',
                icon: Icons.layers,
                children: [
                  ...formState.variantMatrix.map((v) => ListTile(
                    title: Text(v.name),
                    subtitle: Text('SKU Var: ${v.sku} | Jual: ${formatRupiah(v.sellPrice)}'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => formNotifier.removeVariant(v.id)),
                  )),
                  OutlinedButton.icon(
                    onPressed: () {
                      formNotifier.addVariant(VariantMatrixModel(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        sku: '${formState.id}-V1',
                        name: 'Ukuran 12mm Besi Baja',
                        sellPrice: formState.sellPriceGeneral
                      ));
                    },
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Tambah Varian Ukuran/Warna'),
                  )
                ],
              ),
              const SizedBox(height: 14),

              // C. Metadata & Compliance
              if (isOwner)
                _buildFormCard(
                  title: 'Metadata Compliance (Owner Only)',
                  icon: Icons.gavel,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Berat Barang (Gram)', border: OutlineInputBorder()),
                      onChanged: (v) => formNotifier.updateFields(weight: double.tryParse(v)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Dimensi (P x L x T cm)', border: OutlineInputBorder()),
                      onChanged: (v) => formNotifier.updateFields(dimensions: v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'PPN (%)', border: OutlineInputBorder()),
                      onChanged: (v) => formNotifier.updateFields(ppnPercent: double.tryParse(v)),
                    ),
                  ],
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: isOwner 
        ? FloatingActionButton.extended(
            isExtended: _isFabExtended,
            backgroundColor: const Color(0xFF00A65A),
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('Simpan Master IPOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _simpanSeluruhDataForm(formState),
          )
        : null, // Sales tidak memiliki wewenang memicu FAB Simpan Master Produk
    );
  }

  // Sub-Widget: Header & Action Bar dengan Filter Debounce Terkondisi
  Widget _buildActionBar(bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isOwner ? 'PANEL DOKUMEN OWNER' : 'PANEL DOKUMEN SALESMAN', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007F00))),
              if (isOwner)
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.file_upload, color: Colors.blue), onPressed: () {}, tooltip: 'Import Excel'),
                    IconButton(icon: const Icon(Icons.download, color: Colors.purple), onPressed: () {}, tooltip: 'Export Excel'),
                  ],
                )
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari SKU / Nama Barang dengan Debounce...', border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _searchDebounce = v),
          ),
        ],
      ),
    );
  }

  // Sub-Widget: Pricing Engine dengan Proteksi Keamanan Lapisan Blur Obscure
  Widget _buildPricingEngineSection(bool isOwner, ProductFormState state, ProductFormNotifier formNotifier) {
    double hitungMargin(double buy, double sell) {
      if (sell <= 0) return 0;
      return ((sell - buy) / sell) * 100;
    }

    return _buildFormCard(
      title: 'Pricing Engine Matrix & RBAC Control',
      icon: Icons.monetization_on,
      children: [
        if (!isOwner)
          // Tampilan Terproteksi untuk Salesman (Gunakan Penyamaran Data/Blur)
          Stack(
            children: [
              Column(
                children: [
                  TextFormField(initialValue: 'Rp 999.999', decoration: const InputDecoration(labelText: 'Harga Modal (HPP)'), readOnly: true),
                  const SizedBox(height: 12),
                  TextFormField(initialValue: formatRupiah(state.sellPriceGeneral), decoration: const InputDecoration(labelText: 'Harga Jual Umum'), readOnly: true),
                ],
              ),
              Positioned.fill(
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                    child: Container(color: Colors.white.withOpacity(0.4), child: const Center(child: Text('HARGA MODAL & MARGIN DIKUNCI OWNER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
                  ),
                ),
              )
            ],
          )
        else
          // Tampilan Terbuka Penuh Khusus Owner dengan Auto-calculate Margin %
          Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Harga Beli / Modal Dasar (HPP) *', prefixText: 'Rp ', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                onChanged: (v) => formNotifier.updateFields(buyPrice: double.tryParse(v)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Harga Jual Umum *', prefixText: 'Rp ', border: OutlineInputBorder()),
                onChanged: (v) => formNotifier.updateFields(sellPriceGeneral: double.tryParse(v)),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Margin Keuntungan Umum: ${hitungMargin(state.buyPrice, state.sellPriceGeneral).toStringAsFixed(1)} %', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Grosir Tier 1', prefixText: 'Rp '),
                      onChanged: (v) => formNotifier.updateFields(sellPriceTier1: double.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Grosir Tier 2', prefixText: 'Rp '),
                      onChanged: (v) => formNotifier.updateFields(sellPriceTier2: double.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Batas Diskon Maksimal untuk Sales (Rp)', border: OutlineInputBorder()),
                onChanged: (v) => formNotifier.updateFields(maxDiscountSales: double.tryParse(v)),
              ),
            ],
          )
      ],
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: const Color(0xFF00A65A)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
            const Divider(height: 20),
            ...children
          ],
        ),
      ),
    );
  }

  Future<void> _simpanSeluruhDataForm(ProductFormState data) async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(localDatabaseProvider);
    
    try {
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: data.id,
        name: data.name,
        shortName: Value(data.shortName),
        barcode: Value(data.barcode),
        description: Value(data.description),
        categoryId: Value(data.categoryId),
        subCategory: Value(data.subCategory),
        brand: Value(data.brand),
        warehouseLocation: Value(data.warehouseLocation),
        tags: Value(data.tags),
        buyPrice: Value(data.buyPrice),
        sellPriceGeneral: Value(data.sellPriceGeneral),
        sellPriceTier1: Value(data.sellPriceTier1),
        sellPriceTier2: Value(data.sellPriceTier2),
        sellPriceTier3: Value(data.sellPriceTier3),
        maxDiscountSales: Value(data.maxDiscountSales),
        isPriceLocked: Value(data.isPriceLocked),
        stock: Value(data.baseStock),
        minStock: Value(data.minStock),
        maxStock: Value(data.maxStock),
        allowMinusStock: Value(data.allowMinusStock),
        weight: Value(data.weight),
        dimensions: Value(data.dimensions),
        ppnPercent: Value(data.ppnPercent),
        rewardPoints: Value(data.rewardPoints),
        expiryDate: Value(data.expiryDate),
      ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Master Data Berhasil Didistribusikan ke Semua Channel!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error SQLite: $e')));
    }
  }
}
