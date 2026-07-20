import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'product_form_provider.dart';
import 'product_form_page.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabExtended = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedStatus = 'Semua';
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
    if (_debounceTimer?.isActive?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query.toLowerCase());
    });
  }

  String _hitungMargin(double buy, double sell) {
    if (sell <= 0 || buy <= 0) return '0%';
    return '${(((sell - buy) / sell) * 100).toStringAsFixed(1)}%';
  }

  void _openFormTambah() {
    // Reset form agar ID baru & kosong
    ref.read(productFormProvider.notifier).resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormProductPage()),
    );
  }

  void _openFormEdit(ProductData item) {
    ref.read(productFormProvider.notifier).loadFromProductData(item);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormProductPage(isEdit: true)),
    );
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
            _buildAdvancedHeaderFilter(isOwner),
            Expanded(
              child: StreamBuilder<List<ProductData>>(
                stream: db.select(db.products).watch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A)));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada master barang. Tap + Tambah Master'));

                  final filtered = snapshot.data!.where((item) {
                    final matchSearch = item.name.toLowerCase().contains(_searchQuery) || item.id.toLowerCase().contains(_searchQuery) || (item.barcode?.toLowerCase().contains(_searchQuery)?? false);
                    final matchCategory = _selectedCategory == 'Semua' || item.categoryId == _selectedCategory;
                    final matchBrand = _selectedBrand == 'Semua' || item.brand == _selectedBrand;
                    final matchStok =!_filterStokMenipis || (item.stock) <= (item.minStock);
                    final bool isAktif = item.isPriceLocked;
                    final matchStatus = _selectedStatus == 'Semua' || (_selectedStatus == 'Aktif' && isAktif) || (_selectedStatus == 'Non-Aktif' &&!isAktif);
                    return matchSearch && matchCategory && matchBrand && matchStok && matchStatus;
                  }).toList();

                  if (filtered.isEmpty) return const Center(child: Text('Item tidak ditemukan.'));
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) => _buildKatalogItemCard(filtered[idx], isOwner),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildContextualMultiFab(context, isOwner),
    );
  }

  Widget _buildAdvancedHeaderFilter(bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isOwner? '📊 PANEL MASTER UTAMA (OWNER)' : '📋 KATALOG BARANG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF007F00))), if (isOwner) const Badge(label: Text('Sinkron Aktif'), backgroundColor: Color(0xFF00A65A))]),
          const SizedBox(height: 10),
          TextField(onChanged: _onSearchChanged, decoration: InputDecoration(hintText: 'Cari SKU / Nama / Barcode...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)), filled: true, fillColor: const Color(0xfff1f3f5), contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ],
      ),
    );
  }

  Widget _buildKatalogItemCard(ProductData item, bool isOwner) {
    final bool isLowStock = item.stock <= item.minStock;
    return Card(
      color: Colors.white, elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openFormEdit(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SKU: ${item.id}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 11)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: item.isPriceLocked? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(item.isPriceLocked? 'AKTIF' : 'NON-AKTIF', style: TextStyle(color: item.isPriceLocked? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 6),
            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: Text('Jual: ${formatRupiah(item.sellPriceGeneral)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13))), Text('Stok: ${item.stock.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLowStock? Colors.red : Colors.black87))]),
          ]),
        ),
      ),
    );
  }

  Widget _buildContextualMultiFab(BuildContext context, bool isOwner) {
    if (!isOwner) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      isExtended: _isFabExtended,
      backgroundColor: const Color(0xFF00A65A),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Tambah Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: _openFormTambah,
    );
  }
}