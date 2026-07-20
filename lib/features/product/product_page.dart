import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import 'product_form_provider.dart';
import 'product_form_dialogs.dart';
import 'inventory_emergency_fab.dart';
import 'product_quick_actions.dart';

// State Provider internal untuk sistem filter
final searchQueryProvider = StateProvider<String>((ref) => '');
final filterCategoryProvider = StateProvider<String?>((ref) => null);
final filterStockStatusProvider = StateProvider<String?>((ref) => null); // 'menipis', 'habis', 'aman'
final sortByProvider = StateProvider<String>((ref) => 'name_asc'); // name_asc, price_desc, stock_asc

/// Data model pembawa metrik kalkulasi ringkasan inventaris
class CatalogSummary {
  final int totalSKU;
  final double totalAssetValue;
  final int lowStockCount;
  final int inactiveCount;
  CatalogSummary({this.totalSKU = 0, this.totalAssetValue = 0, this.lowStockCount = 0, this.inactiveCount = 0});
}

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isFabMenuOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    // Watch status filter & sorting
    final query = ref.watch(searchQueryProvider);
    final catFilter = ref.watch(filterCategoryProvider);
    final stockFilter = ref.watch(filterStockStatusProvider);
    final sortRule = ref.watch(sortByProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: StreamBuilder<List<ProductData>>(
        stream: db.select(db.products).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A)));
          }

          final rawProducts = snapshot.data!;

          // 1. HITUNG METRIKA RINGKASAN BARANG (SUMMARY CARDS)
          double totalHppAsset = 0;
          int lowStock = 0;
          int nonAktif = 0;
          Set<String> categories = {'Umum'};

          for (var p in rawProducts) {
            if (p.statusActive != 'aktif') nonAktif++;
            if (p.stock <= p.minStock && p.stock > 0) lowStock++;
            if (p.stock > 0) totalHppAsset += (p.stock * p.buyPrice);
            categories.add(p.categoryId);
          }

          // 2. TERAPKAN FILTER LOGIK KUSTOM
          List<ProductData> filteredList = rawProducts.where((p) {
            final matchesQuery = p.name.toLowerCase().contains(query) ||
                (p.shortName ?? '').toLowerCase().contains(query) ||
                p.id.toLowerCase().contains(query) ||
                (p.barcode ?? '').toLowerCase().contains(query);

            final matchesCategory = catFilter == null || p.categoryId == catFilter;

            bool matchesStock = true;
            if (stockFilter == 'menipis') matchesStock = p.stock <= p.minStock && p.stock > 0;
            if (stockFilter == 'habis') matchesStock = p.stock <= 0;
            if (stockFilter == 'aman') matchesStock = p.stock > p.minStock;

            return matchesQuery && matchesCategory && matchesStock;
          }).toList();

          // 3. PROSES SORT ENGINE
          filteredList.sort((a, b) {
            switch (sortRule) {
              case 'name_desc': return b.name.compareTo(a.name);
              case 'price_asc': return a.sellPriceGeneral.compareTo(b.sellPriceGeneral);
              case 'price_desc': return b.sellPriceGeneral.compareTo(a.sellPriceGeneral);
              case 'stock_asc': return a.stock.compareTo(b.stock);
              case 'stock_desc': return b.stock.compareTo(a.stock);
              case 'hpp_desc': return b.buyPrice.compareTo(a.buyPrice);
              default: return a.name.compareTo(b.name);
            }
          });

          return Column(
            children: [
              // PANEL SEARCH BAR & ENGINE FILTER QUICK CHIPS
              _buildTopActionBar(context, categories.toList()),

              // LIVE SUMMARY DISPLAY CARDS
              _buildSummaryRow(
                summary: CatalogSummary(
                  totalSKU: rawProducts.length,
                  totalAssetValue: totalHppAsset,
                  lowStockCount: lowStock,
                  inactiveCount: nonAktif,
                ),
              ),

              // DATA GRID LIST UTAMA CATALOG
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(child: Text('Data barang tidak ditemukan.'))
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          int crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                          if (crossCount == 1) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filteredList.length,
                              itemBuilder: (c, idx) => _buildProductRowCard(filteredList[idx]),
                            );
                          } else {
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                childAspectRatio: 2.4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                              itemCount: filteredList.length,
                              itemBuilder: (c, idx) => _buildProductRowCard(filteredList[idx]),
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
      
                  // CONFIGURATION MULTI-FAB BARU: DIAGRESIKAN VERTIKAL (ANTI TEKS KEPOTONG & AUTO-HIDE)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabMenuOpen) ...[
            // 1. PILIHAN: DARURAT LAPANGAN (KIRI SEBELUMNYA)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => setState(() => _isFabMenuOpen = false), // Otomatis sembunyikan menu pilihan lainnya
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // Merapikan posisi vertikal text & button
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(20), // Menggunakan style pill yang jauh lebih rapi
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text(
                      'Darurat Lapangan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const InventoryEmergencyFab(), 
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. PILIHAN: AKSI CEPAT (TENGAH SEBELUMNYA)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => setState(() => _isFabMenuOpen = false), // Otomatis sembunyikan menu pilihan lainnya
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007F00),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text(
                      'Aksi Cepat Produk',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const ProductQuickActionsFab(), 
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. PILIHAN: TAMBAH BARANG MASTER (KANAN SEBELUMNYA)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A65A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Text(
                    'Tambah Item Baru',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  heroTag: 'action_add_product_master',
                  backgroundColor: const Color(0xFF00A65A),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    setState(() => _isFabMenuOpen = false); // Menyembunyikan pilihan lainnya
                    _openFormMasterBarang(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // TOMBOL UTAMA (MASTER TRIGGER)
          FloatingActionButton(
            heroTag: 'main_master_fab_trigger',
            backgroundColor: _isFabMenuOpen ? Colors.black : const Color(0xFF00A65A),
            onPressed: () {
              setState(() {
                _isFabMenuOpen = !_isFabMenuOpen;
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isFabMenuOpen
                  ? const Icon(Icons.close, color: Colors.white, key: ValueKey('close_icon'))
                  : const Icon(Icons.menu, color: Colors.white, key: ValueKey('menu_icon')),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTopActionBar(BuildContext context, List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari Nama, SKU, Barcode...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Color(0xFF007F00)),
                onSelected: (val) => ref.read(sortByProvider.notifier).state = val,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'name_asc', child: Text('Nama A - Z')),
                  const PopupMenuItem(value: 'name_desc', child: Text('Nama Z - A')),
                  const PopupMenuItem(value: 'price_desc', child: Text('Harga Tertinggi')),
                  const PopupMenuItem(value: 'price_asc', child: Text('Harga Terendah')),
                  const PopupMenuItem(value: 'stock_asc', child: Text('Stok Terkecil')),
                  const PopupMenuItem(value: 'stock_desc', child: Text('Stok Terbesar')),
                  const PopupMenuItem(value: 'hpp_desc', child: Text('Nilai Modal Termahal')),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua Stok'),
                  selected: ref.watch(filterStockStatusProvider) == null,
                  onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = null,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Stok Menipis'),
                  selected: ref.watch(filterStockStatusProvider) == 'menipis',
                  selectedColor: Colors.amber.shade200,
                  onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = s ? 'menipis' : null,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Stok Habis / Minus'),
                  selected: ref.watch(filterStockStatusProvider) == 'habis',
                  selectedColor: Colors.red.shade200,
                  onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = s ? 'habis' : null,
                ),
                const SizedBox(
  height: 24,
  child: VerticalDivider(width: 16, thickness: 1, color: Colors.grey),
),
                for (var cat in categories) ...[
                  ChoiceChip(
                    label: Text(cat),
                    selected: ref.watch(filterCategoryProvider) == cat,
                    onSelected: (s) => ref.read(filterCategoryProvider.notifier).state = s ? cat : null,
                  ),
                  const SizedBox(width: 6),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required CatalogSummary summary}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _buildMiniStatCard('Total SKU', summary.totalSKU.toString(), Colors.blue),
          _buildMiniStatCard('Aset Modal', formatRupiah(summary.totalAssetValue), Colors.green),
          _buildMiniStatCard('Stok Tipis', summary.lowStockCount.toString(), Colors.orange),
          _buildMiniStatCard('Non-Aktif', summary.inactiveCount.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRowCard(ProductData prod) {
    Color stockColor = const Color(0xFF00A65A);
    if (prod.stock <= 0) {
      stockColor = Colors.red;
    } else if (prod.stock <= prod.minStock) {
      stockColor = Colors.orange;
    }

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: prod.statusActive == 'aktif' ? Colors.white : Colors.grey.shade200,
      child: ListTile(
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
        title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${prod.id} | ${prod.categoryId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(formatRupiah(prod.sellPriceGeneral), style: const TextStyle(color: Color(0xFF00A65A), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Text('HPP: ${formatRupiah(prod.buyPrice)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            )
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: stockColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('${prod.stock.toStringAsFixed(0)} Pcs', style: TextStyle(color: stockColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Text(prod.statusActive == 'aktif' ? 'Aktif' : 'Non-Aktif', style: TextStyle(fontSize: 9, color: prod.statusActive == 'aktif' ? Colors.blue : Colors.red)),
          ],
        ),
        onTap: () => _openFormMasterBarang(context, product: prod),
      ),
    );
  }

  void _openFormMasterBarang(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);

    if (product != null) {
      // Ambil detail relasi tabel sub dari SQLite sebelum form dibuka
      final units = await (db.select(db.productUnits)..where((t) => t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t) => t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t) => t.productId.equals(product.id))).get();

      notifier.setProduct(product, units, variants, assets.map((e) => e.imagePath).toList());
    } else {
      // Reset form ke mode ID baru auto-generated
      ref.invalidate(productFormProvider);
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => const FractionallySizedBox(
          heightFactor: 0.9,
          child: FormMasterBarangSheet(),
        ),
      );
    }
  }
}

/// KOMPONEN BOTTOM SHEET: Kompleks Form Form Input 8 Klaster Inti IPOS
class FormMasterBarangSheet extends ConsumerWidget {
  const FormMasterBarangSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.name.isEmpty ? 'Tambah Item Baru' : 'Edit Master Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          if (state.name.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () async {
                await notifier.deleteProduct(state.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KLASTER 1: IDENTITY
          _buildSectionHeader('1. Identitas Produk (Product Identity)'),
          TextFormField(
            initialValue: state.id,
            decoration: const InputDecoration(labelText: 'SKU / ID Produk (Auto)', border: OutlineInputBorder()),
            enabled: false,
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: state.name,
            decoration: const InputDecoration(labelText: 'Nama Produk Lengkap (Wajib)*', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateField(name: v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.shortName,
                  maxLength: 25,
                  decoration: const InputDecoration(labelText: 'Nama Singkat Struk Thermal 58mm', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(shortName: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: state.barcode,
                  decoration: const InputDecoration(labelText: 'Barcode EAN13 / QR', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(barcode: v),
                ),
              ),
            ],
          ),

          // KLASTER 2: KATEGORI & KLASIFIKASI
          const SizedBox(height: 10),
          _buildSectionHeader('2. Kategori & Klasifikasi Lokasi'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.categoryId,
                  items: [state.categoryId, 'Umum', 'Makanan', 'Minuman', 'Otomotif']
                      .toSet()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => notifier.updateField(categoryId: v),
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_box, color: Color(0xFF00A65A)),
                onPressed: () async {
                  String? newCat = await ProductFormDialogs.showQuickTextDialog(context: context, title: 'Tambah Kategori Baru', labelField: 'Nama Kategori');
                  if (newCat != null) notifier.updateField(categoryId: newCat);
                },
              )
            ],
          ),

          // KLASTER 3: PRICING ENGINE
          const SizedBox(height: 16),
          _buildSectionHeader('3. Pricing Engine & Margin Auto Calculate'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.buyPrice.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'HPP / Harga Modal Awal', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(buyPrice: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: state.sellPriceGeneral.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Jual Umum', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(sellPriceGeneral: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Gross Profit Margin Sistem: ${state.marginPercentage.toStringAsFixed(2)}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
            ),
          ),

          // KLASTER 4: MULTI UNIT KONVERSI GROSIR
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('4. Multi-Unit & Konversi Grosir'),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Satuan'),
                onPressed: () async {
                  final res = await ProductFormDialogs.showUnitConversionDialog(
                    context: context,
                    baseBuyPrice: state.buyPrice,
                    baseSellPrice: state.sellPriceGeneral,
                  );
                  if (res != null) {
                    notifier.addUnit(res['unitName'], res['conversion'], res['buyPriceUnit'], res['sellPriceUnit'], res['barcode']);
                  }
                },
              )
            ],
          ),
          if (state.units.isEmpty) const Text('Hanya menggunakan Satuan Dasar (Pcs).', style: TextStyle(fontSize: 11, color: Colors.grey)),
          for (var unt in state.units)
            Card(
              elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
              child: ListTile(
                dense: true,
                title: Text('1 ${unt.unitName} = ${unt.conversion} Pcs', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Jual: ${formatRupiah(unt.sellPriceUnit)} | Modal: ${formatRupiah(unt.buyPriceUnit)}'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => notifier.removeUnit(unt.id)),
              ),
            ),

                    // KLASTER 5: MATRIX VARIAN MANUAL (AUTO SKU SUFFIX +Vxxx)
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('5. Manajemen Varian Manual'),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                label: const Text('Tambah Varian', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Hitung index urutan untuk suffix +Vxxx secara real-time
                  final nextIndex = state.variants.length + 1;
                  final autoSuffix = '+V${nextIndex.toString().padLeft(3, '0')}';
                  
                  // Daftarkan opsi varian baru ke provider Anda
                  notifier.addManualVariant(
                    skuId: '${state.id}$autoSuffix', 
                    defaultName: 'Opsi Varian $nextIndex', 
                    defaultPrice: state.sellPriceGeneral,
                  );
                },
              ),
            ],
          ),
          
          if (state.variants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Produk ini tidak memiliki varian (Single SKU Item).',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          for (int i = 0; i < state.variants.length; i++) ...[
            Builder(
              builder: (context) {
                final vr = state.variants[i];
                // Ekstrak string suffix +Vxxx untuk penanda visual di form UI
                final displaySuffix = vr.id.contains('+V') 
                    ? '+V${vr.id.split('+V').last}' 
                    : '+V${(i + 1).toString().padLeft(3, '0')}';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                'SKU Varian: $displaySuffix', 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => notifier.removeVariant(vr.id), // Pemicu hapus opsi varian tertentu
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Field Edit Nama Varian
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: vr.variantName,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  labelText: 'Nama Varian (Contoh: Putih / XL)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) => notifier.updateVariantDetail(vr.id, variantName: v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Field Edit Harga Jual Varian
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: vr.sellPrice.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  labelText: 'Harga Jual (Rp)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) => notifier.updateVariantDetail(vr.id, price: double.tryParse(v)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          ],


          // KLASTER 6: METADATA & COMPLIANCE
          const SizedBox(height: 16),
          _buildSectionHeader('6. Kontrol Stok & Pengaman Alert'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.stock.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Awal Fisik', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(stock: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: state.minStock.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Batas Minimum Alert', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateField(minStock: double.tryParse(v) ?? 5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
              onPressed: () async {
                final success = await notifier.saveProduct();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Katalog Berhasil Diperbarui!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('EKSEKUSI SIMPAN DATA BARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007F00))),
    );
  }
}
