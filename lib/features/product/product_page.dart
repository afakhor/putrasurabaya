import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_form_provider.dart'; // <-- CUKUP INI SAJA, jangan import product_form_page.dart
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

  void _openFormTambah() {
    ref.read(productFormProvider.notifier).resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormProductPage()), // <-- TANPA const
    );
  }

  void _openFormEdit(ProductData item) {
    ref.read(productFormProvider.notifier).loadFromProductData(item);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormProductPage(isEdit: true)), // <-- TANPA const
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari SKU / Nama / Barcode...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)),
                  filled: true,
                  fillColor: const Color(0xfff1f3f5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ProductData>>(
                stream: db.select(db.products).watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.isEmpty) return const Center(child: Text('Belum ada barang'));
                  final filtered = snapshot.data!.where((e) => e.name.toLowerCase().contains(_searchQuery)).toList();
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (c, i) {
                      final item = filtered[i];
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(formatRupiah(item.sellPriceGeneral)),
                          onTap: () => _openFormEdit(item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isOwner
         ? FloatingActionButton.extended(
              isExtended: _isFabExtended,
              backgroundColor: const Color(0xFF00A65A),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _openFormTambah,
            )
          : null,
    );
  }
}