import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';
// Asumsi navigasi diarahkan ke halaman form input terpisah Anda:
// import 'product_form_page.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabExtended = true;

  // State Kontrol Engine Filter & Debounce Search
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedStatus = 'Semua'; // Semua, Aktif, Non-Aktif
  String _selectedBrand = 'Semua';
  bool _filterStokMenipis = false;
  
  Timer? _debounceTimer;

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
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  // Helper fungsi untuk hitung margin keuntungan secara real-time vs HPP
  String _hitungMargin(double buy, double sell) {
    if (sell <= 0 || buy <= 0) return '0%';
    final double margin = ((sell - buy) / sell) * 100;
    return '${margin.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final user = ref.watch(currentUserProvider);
    final bool isOwner = user?['role'] == 'owner';

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // 1. HEADER & ACTION BAR DENGAN MULTI-FILTER & DEBOUNCE SEARCH
            // =========================================================
            _buildAdvancedHeaderFilter(isOwner),

            // =========================================================
            // 2. DAFTAR BARANG / KATALOG PRODUK UTAMA
            // =========================================================
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: db.select(db.products).watch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Belum ada master barang terdata di sistem lokal.'));
                  }

                  // Engine Pipeline Filtering Data Multi-Parameter
                  final filteredProducts = snapshot.data!.where((item) {
                    final matchSearch = item.name.toLowerCase().contains(_searchQuery) ||
                        item.id.toLowerCase().contains(_searchQuery) ||
                        (item.barcode?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (item.tags?.toLowerCase().contains(_searchQuery) ?? false);

                    final matchCategory = _selectedCategory == 'Semua' || item.categoryId == _selectedCategory;
                    final matchBrand = _selectedBrand == 'Semua' || item.brand == _selectedBrand;
                    final matchStok = !_filterStokMenipis || (item.stock ?? 0) <= (item.minStock ?? 5);
                    
                    final bool isAktif = item.isPriceLocked ?? true;
                    final matchStatus = _selectedStatus == 'Semua' ||
                        (_selectedStatus == 'Aktif' && isAktif) ||
                        (_selectedStatus == 'Non-Aktif' && !isAktif);

                    return matchSearch && matchCategory && matchBrand && matchStok && matchStatus;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('Item barang tidak ditemukan. Silakan ubah filter.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filteredProducts.length,
                    itemBuilder: (ctx, idx) {
                      final item = filteredProducts[idx];
                      return _buildKatalogItemCard(item, isOwner);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // =========================================================
      // 3. MULTI-FAB UTAMA (OWNER BISA TAMBAH DATA, SALESMAN AKSES KHUSUS)
      // =========================================================
      floatingActionButton: _buildContextualMultiFab(context, isOwner),
    );
  }

  // WIDGET GENERATOR: Kontrol Filter Atas Kompatibel Owner & Salesman
  Widget _buildAdvancedHeaderFilter(bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwner ? '📊 PANEL MASTER UTAMA (OWNER)' : '📋 KATALOG BARANG LAPANGAN (SALES)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF007F00)),
              ),
              if (isOwner)
                const Badge(
                  label: Text('Sinkronisasi POS Aktif'),
                  backgroundColor: Color(0xFF00A65A),
                )
            ],
          ),
          const SizedBox(height: 10),
          // Kolom Search Debounce
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari SKU / Nama Barang / Scan Barcode / Tag Proyek...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)),
              filled: true,
              fillColor: const Color(0xfff1f3f5),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          // Baris Dropdown Grid Filter Multi-Opsi
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8), labelText: 'Kategori', border: OutlineInputBorder()),
                  items: ['Semua', 'Umum', 'Perkakas Bangunan', 'Material Pokok'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'Semua'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8), labelText: 'Status', border: OutlineInputBorder()),
                  items: ['Semua', 'Aktif', 'Non-Aktif'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v ?? 'Semua'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8), labelText: 'Brand / Merk', border: OutlineInputBorder()),
                  items: ['Semua', 'Krakatau Steel', 'Tiga Roda', 'Avian'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _selectedBrand = v ?? 'Semua'),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Switch filter stok menipis lapangan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Text('Tampilkan Stok Kritis (Menipis) Di Bawah Minimum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _filterStokMenipis,
                  activeColor: const Color(0xFF00A65A),
                  onChanged: (v) => setState(() => _filterStokMenipis = v),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // WIDGET GENERATOR: Baris Item Card Dengan Kepatuhan Aturan Tampilan Informasi Per-Role
  Widget _buildKatalogItemCard(Product item, bool isOwner) {
    final bool isLowStock = (item.stock ?? 0) <= (item.minStock ?? 5);
    final double buyPrice = item.buyPrice ?? 0;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS 1: Metadata Utama & Label Status Aktif
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SKU INDUK: ${item.id}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 11)),
                    if (item.barcode != null && item.barcode!.isNotEmpty)
                      Text('Barcode: ${item.barcode}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, py: 3),
                  decoration: BoxDecoration(
                    color: (item.isPriceLocked ?? true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (item.isPriceLocked ?? true) ? 'AKTIF' : 'NON-AKTIF',
                    style: TextStyle(color: (item.isPriceLocked ?? true) ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),

            // BARIS 2: Nama Produk, Merk, & Tags Pengelompokan Laporan
            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, py: 2),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Brand: ${item.brand ?? "Tanpa Merk"}', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
                if (item.tags != null && item.tags!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tags: ${item.tags}', 
                      style: TextStyle(fontSize: 11, color: isOwner ? Colors.purple : Colors.grey, fontWeight: isOwner ? FontWeight.bold : FontWeight.normal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ]
              ],
            ),
            const Divider(height: 18),

            // BARIS 3: KATALOG MULTI-IMAGE (Memudahkan Sales Tunjuk Varian ke Customer)
            _buildVisualKatalogStrip(item.id), 
            const SizedBox(height: 8),

            // BARIS 4: CORE ENGINE - HARGA UTAMA & INVENTORI STOCK DATA
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kompartemen Finansial (Kiri)
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harga Jual Umum: ${formatRupiah(item.sellPriceGeneral ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                      if (isOwner) ...[
                        const SizedBox(height: 2),
                        Text('HPP (Modal): ${formatRupiah(buyPrice)}', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Margin Eceran: ${_hitungMargin(buyPrice, item.sellPriceGeneral ?? 0)}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                // Kompartemen Stok Kuantitas (Kanan)
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Stok: ${item.stock ?? 0} Pcs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLowStock ? Colors.red : Colors.black87)),
                          if (isLowStock) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.warning, color: Colors.red, size: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (isOwner)
                        Text(
                          'Diubah: ${item.expiryDate != null ? DateFormat('dd/MM/yyyy').format(item.expiryDate!) : '-'}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        )
                      else
                        Text('Min Stok: ${item.minStock ?? 5} Pcs', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                )
              ],
            ),

            // BARIS 5: LOKASI RAK GUDANG (OWNER ONLY)
            if (isOwner && item.warehouseLocation != null && item.warehouseLocation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                child: Text('📍 Lokasi Gudang: ${item.warehouseLocation} (Owner Only)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
              )
            ],

            // BARIS 6: EXPANSION TIER PRICING ENGINE (GROSIR BERTINGKAT)
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Lihat Tabel Harga Grosir Bertingkat & Varian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A65A))),
              dense: true,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              children: [
                _buildTierPricingTable(item, isOwner),
                const SizedBox(height: 6),
                _buildVariantMatrixMockList(item),
              ],
            )
          ],
        ),
      ),
    );
  }

  // WIDGET GENERATOR: Tampilan Strip Gambar Multi-Image Pendukung Katalog Visual Penjualan
  Widget _buildVisualKatalogStrip(String productId) {
    // Simulasi path file multi gambar lokal berdasar ID produk
    final List<String> mockGalleryImages = [
      '/storage/emulated/0/Download/perkakas_1.jpg',
      '/storage/emulated/0/Download/perkakas_2.jpg',
      '/storage/emulated/0/Download/perkakas_3.jpg',
    ];

    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mockGalleryImages.length,
        itemBuilder: (ctx, idx) {
          return Container(
            width: 65,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Icon(Icons.image, size: 24, color: Colors.grey), // Ganti dengan FileImage(File(mockGalleryImages[idx])) jika path valid
          );
        },
      ),
    );
  }

  // WIDGET GENERATOR: Tabel Dinamis Untuk Memetakan Harga Grosir Bertingkat Serta Perhitungan Margin Kontrol
  Widget _buildTierPricingTable(Product item, bool isOwner) {
    final double buy = item.buyPrice ?? 0;

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 1, borderRadius: BorderRadius.circular(6)),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          backgroundColor: Colors.grey[100],
          children: [
            const Padding(padding: EdgeInsets.all(6), child: Text('Tier Grosir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            const Padding(padding: EdgeInsets.all(6), child: Text('Harga Jual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: const EdgeInsets.all(6), child: Text(isOwner ? 'Margin vs HPP' : 'Akses', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        _buildTierRow('Tier 1 (Grosir Kecil)', item.sellPriceTier1 ?? 0, buy, isOwner),
        _buildTierRow('Tier 2 (Grosir Menengah)', item.sellPriceTier2 ?? 0, buy, isOwner),
        _buildTierRow('Tier 3 (Grosir Besar)', item.sellPriceTier3 ?? 0, buy, isOwner),
      ],
    );
  }

  TableRow _buildTierRow(String label, double sellPrice, double buyPrice, bool isOwner) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(label, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text(formatRupiah(sellPrice), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue))),
        Padding(
          padding: const EdgeInsets.all(6), 
          child: Text(
            isOwner ? _hitungMargin(buyPrice, sellPrice) : 'Terbuka ✔', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOwner ? Colors.red[700] : Colors.green),
          ),
        ),
      ],
    );
  }

  // WIDGET GENERATOR: Preview Pembentukan Matriks Varian Berformat SKU Induk Suffix "--v1++"
  Widget _buildVariantMatrixMockList(Product item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Matriks Varian Suffix --v1++ :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xfff8f9fa), borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              _buildVariantRowItem('${item.id}-V1', 'Ukuran Besi Baja 10mm Full', item.sellPriceGeneral ?? 0),
              const Divider(height: 10),
              _buildVariantRowItem('${item.id}-V2', 'Ukuran Besi Baja 12mm Full', (item.sellPriceGeneral ?? 0) * 1.2),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildVariantRowItem(String skuVar, String nameVar, double priceVar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(skuVar, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
        Text(nameVar, style: const TextStyle(fontSize: 11)),
        Text(formatRupiah(priceVar), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // WIDGET GENERATOR: Fab-fab Multi Aksi Kontekstual Sesuai Peran User Keamanan POS
  Widget _buildContextualMultiFab(BuildContext context, bool isOwner) {
    // Apabila user adalah Salesman, sembunyikan FAB Tambah Master Dokumen
    if (!isOwner) return const SizedBox.shrink(); 

    return FloatingActionButton.extended(
      isExtended: _isFabExtended,
      backgroundColor: const Color(0xFF00A65A),
      icon: const Icon(Icons.add_box, color: Colors.white),
      label: const Text('Tambah Dokumen Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: () {
        /*
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductFormPage()),
        );
        */
      },
    );
  }
}
