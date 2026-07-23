import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';
import 'product_form_provider.dart';
import 'product_form_dialogs.dart';
import '../../core/utils/radial_half_circle_fab.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterCategoryProvider = StateProvider<String?>((ref) => null);
final filterStockStatusProvider = StateProvider<String?>((ref) => null);
final sortByProvider = StateProvider<String>((ref) => 'name_asc');

class CatalogSummary {
  final int totalSKU; final double totalAssetValue; final int lowStockCount; final int inactiveCount;
  CatalogSummary({this.totalSKU = 0, this.totalAssetValue = 0, this.lowStockCount = 0, this.inactiveCount = 0});
}

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }
  void _onSearchChanged(String query) { if (_debounce?.isActive?? false) _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 300), () { ref.read(searchQueryProvider.notifier).state = query.toLowerCase(); }); }
  Future<void> _openFormMasterBarang(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);
    if (product!= null) {
      final units = await (db.select(db.productUnits)..where((t) => t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t) => t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t) => t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e) => e.imagePath).toList());
    } else { ref.invalidate(productFormProvider); }
    if (context.mounted) { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) => const FractionallySizedBox(heightFactor: 0.9, child: FormMasterBarangSheet())); }
  }
  Widget _buildTopActionBar(BuildContext context, List<String> categories) {
    return Container(color: Colors.white, padding: const EdgeInsets.all(12), child: Column(children: [Row(children: [Expanded(child: TextField(controller: _searchCtrl, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: 'Cari Nama, SKU, Barcode...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 0)))), const SizedBox(width: 8), PopupMenuButton<String>(icon: const Icon(Icons.sort, color: Color(0xFF007F00)), onSelected: (val) => ref.read(sortByProvider.notifier).state = val, itemBuilder: (ctx) => [const PopupMenuItem(value: 'name_asc', child: Text('Nama A - Z')), const PopupMenuItem(value: 'name_desc', child: Text('Nama Z - A')), const PopupMenuItem(value: 'price_desc', child: Text('Harga Tertinggi')), const PopupMenuItem(value: 'price_asc', child: Text('Harga Terendah')), const PopupMenuItem(value: 'stock_asc', child: Text('Stok Terkecil')), const PopupMenuItem(value: 'stock_desc', child: Text('Stok Terbesar'))])]), const SizedBox(height: 8), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [ChoiceChip(label: const Text('Semua Stok'), selected: ref.watch(filterStockStatusProvider) == null, onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = null), const SizedBox(width: 6), ChoiceChip(label: const Text('Stok Menipis'), selected: ref.watch(filterStockStatusProvider) == 'menipis', selectedColor: Colors.amber.shade200, onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = s? 'menipis' : null), const SizedBox(width: 6), ChoiceChip(label: const Text('Stok Habis'), selected: ref.watch(filterStockStatusProvider) == 'habis', selectedColor: Colors.red.shade200, onSelected: (s) => ref.read(filterStockStatusProvider.notifier).state = s? 'habis' : null), for (var cat in categories)...[const SizedBox(width: 6), ChoiceChip(label: Text(cat), selected: ref.watch(filterCategoryProvider) == cat, onSelected: (s) => ref.read(filterCategoryProvider.notifier).state = s? cat : null)]]))]));
  }
  Widget _buildSummaryRow({required CatalogSummary summary}) { return Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: Row(children: [_buildMiniStatCard('Total SKU', summary.totalSKU.toString(), Colors.blue), _buildMiniStatCard('Aset Modal', formatRupiah(summary.totalAssetValue), Colors.green), _buildMiniStatCard('Stok Tipis', summary.lowStockCount.toString(), Colors.orange), _buildMiniStatCard('Non-Aktif', summary.inactiveCount.toString(), Colors.red)])); }
  Widget _buildMiniStatCard(String label, String value, Color color) { return Expanded(child: Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.3), width: 1)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0), child: Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)])))); }
  Widget _buildProductRowCard(ProductData prod) { Color stockColor = const Color(0xFF00A65A); if (prod.stock <= 0) { stockColor = Colors.red; } else if (prod.stock <= prod.minStock) { stockColor = Colors.orange; } return Card(elevation: 0.5, margin: const EdgeInsets.symmetric(vertical: 4), color: prod.statusActive == 'aktif'? Colors.white : Colors.grey.shade200, child: ListTile(title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('SKU: ${prod.id} | ${prod.categoryId} - ${formatRupiah(prod.sellPriceGeneral)}', style: const TextStyle(fontSize: 11)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: stockColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text('${prod.stock.toStringAsFixed(0)} Pcs', style: TextStyle(color: stockColor, fontWeight: FontWeight.bold, fontSize: 12))), onTap: () => _openFormMasterBarang(context, product: prod))); }

  @override Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider); final query = ref.watch(searchQueryProvider); final catFilter = ref.watch(filterCategoryProvider); final stockFilter = ref.watch(filterStockStatusProvider); final sortRule = ref.watch(sortByProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: StreamBuilder<List<ProductData>>(stream: db.select(db.products).watch(), builder: (context, snapshot) {
        if (!snapshot.hasData) { return const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))); }
        final rawProducts = snapshot.data!; double totalHppAsset = 0; int lowStock = 0; int nonAktif = 0; Set<String> categories = {'Umum'}; for (var p in rawProducts) { if (p.statusActive!= 'aktif') nonAktif++; if (p.stock <= p.minStock && p.stock > 0) lowStock++; if (p.stock > 0) totalHppAsset += (p.stock * p.buyPrice); categories.add(p.categoryId); }
        List<ProductData> filteredList = rawProducts.where((p) { final matchesQuery = p.name.toLowerCase().contains(query) || (p.shortName?? '').toLowerCase().contains(query) || p.id.toLowerCase().contains(query) || (p.barcode?? '').toLowerCase().contains(query); final matchesCategory = catFilter == null || p.categoryId == catFilter; bool matchesStock = true; if (stockFilter == 'menipis') matchesStock = p.stock <= p.minStock && p.stock > 0; if (stockFilter == 'habis') matchesStock = p.stock <= 0; if (stockFilter == 'aman') matchesStock = p.stock > p.minStock; return matchesQuery && matchesCategory && matchesStock; }).toList();
        filteredList.sort((a, b) { switch (sortRule) { case 'name_desc': return b.name.compareTo(a.name); case 'price_asc': return a.sellPriceGeneral.compareTo(b.sellPriceGeneral); case 'price_desc': return b.sellPriceGeneral.compareTo(a.sellPriceGeneral); case 'stock_asc': return a.stock.compareTo(b.stock); case 'stock_desc': return b.stock.compareTo(a.stock); default: return a.name.compareTo(b.name); } });
        return Column(children: [_buildTopActionBar(context, categories.toList()), _buildSummaryRow(summary: CatalogSummary(totalSKU: rawProducts.length, totalAssetValue: totalHppAsset, lowStockCount: lowStock, inactiveCount: nonAktif)), Expanded(child: filteredList.isEmpty? const Center(child: Text('Data barang tidak ditemukan.')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filteredList.length, itemBuilder: (c, idx) => _buildProductRowCard(filteredList[idx])))]);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: RadialHalfCircleFab(onAddProduct: () => _openFormMasterBarang(context)),
    );
  }
}

class FormMasterBarangSheet extends ConsumerWidget {
  const FormMasterBarangSheet({super.key});
  Widget _buildSectionHeader(String title) { return Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007F00)))); }
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider); final notifier = ref.read(productFormProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(state.name.isEmpty? 'Tambah Item Baru' : 'Edit Master Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), automaticallyImplyLeading: false, actions: [if (state.name.isNotEmpty) IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () async { await notifier.deleteProduct(state.id); if (context.mounted) Navigator.pop(context); }), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSectionHeader('1. Identitas Produk (Product Identity)'),
        TextFormField(initialValue: state.id, decoration: const InputDecoration(labelText: 'SKU / ID Produk (Auto)', border: OutlineInputBorder()), enabled: false),
        const SizedBox(height: 10),
        TextFormField(initialValue: state.name, decoration: const InputDecoration(labelText: 'Nama Produk Lengkap (Wajib)*', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(name: v)),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(initialValue: state.shortName, maxLength: 25, decoration: const InputDecoration(labelText: 'Nama Singkat Struk 58mm', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(shortName: v))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: state.barcode, decoration: const InputDecoration(labelText: 'Barcode EAN13 / QR', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(barcode: v)))]),

        _buildSectionHeader('2. Kategori & Klasifikasi Lokasi'),
        Row(children: [Expanded(child: DropdownButtonFormField<String>(value: state.categoryId, items: [state.categoryId, 'Umum', 'Makanan', 'Minuman', 'Otomotif'].toSet().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => notifier.updateField(categoryId: v), decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()))), IconButton(icon: const Icon(Icons.add_box, color: Color(0xFF00A65A)), onPressed: () async { String? newCat = await ProductFormDialogs.showQuickTextDialog(context: context, title: 'Tambah Kategori Baru', labelField: 'Nama Kategori'); if (newCat!= null) notifier.updateField(categoryId: newCat); })]),

        _buildSectionHeader('3. Pricing Engine & Margin Auto Calculate'),
        Row(children: [Expanded(child: TextFormField(initialValue: state.buyPrice.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'HPP / Modal', prefixText: 'Rp ', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(buyPrice: double.tryParse(v)?? 0))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: state.sellPriceGeneral.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual Umum', prefixText: 'Rp ', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(sellPriceGeneral: double.tryParse(v)?? 0)))]),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)), child: Text('Margin: ${state.marginPercentage.toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800))),

        _buildSectionHeader('4. Multi-Unit & Konversi Grosir'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Satuan Konversi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), TextButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Satuan'), onPressed: () async { final res = await ProductFormDialogs.showUnitConversionDialog(context: context, baseBuyPrice: state.buyPrice, baseSellPrice: state.sellPriceGeneral); if (res!= null) { notifier.addUnit(res['unitName'], res['conversion'], res['buyPriceUnit'], res['sellPriceUnit'], res['barcode']); } })]),
        if (state.units.isEmpty) const Text('Hanya Satuan Dasar (Pcs).', style: TextStyle(fontSize: 11, color: Colors.grey)),
        for (var unt in state.units) Card(child: ListTile(dense: true, title: Text('1 ${unt.unitName} = ${unt.conversion} Pcs'), subtitle: Text('Jual: ${formatRupiah(unt.sellPriceUnit)}'), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => notifier.removeUnit(unt.id)))),

        _buildSectionHeader('5. Manajemen Varian Manual (Auto +Vxxx)'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Varian Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), TextButton.icon(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue), label: const Text('Tambah Varian', style: TextStyle(color: Colors.blue)), onPressed: () { final nextIndex = state.variants.length + 1; final autoSuffix = '+V${nextIndex.toString().padLeft(3, '0')}'; final baseId = state.id.isEmpty? 'PSB-${DateTime.now().millisecondsSinceEpoch}' : state.id; notifier.addManualVariant(skuId: '$baseId$autoSuffix', defaultName: 'Opsi Varian $nextIndex', defaultPrice: state.sellPriceGeneral); })]),
        if (state.variants.isEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('Single SKU Item (Tidak ada varian).', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
        for (int i = 0; i < state.variants.length; i++) Builder(builder: (context) { final vr = state.variants[i]; final displaySuffix = vr.id.contains('+V')? '+V${vr.id.split('+V').last}' : '+V${(i + 1).toString().padLeft(3, '0')}'; return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text('SKU Varian: $displaySuffix', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800))), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => notifier.removeVariant(vr.id))]), Row(children: [Expanded(flex: 3, child: TextFormField(key: ValueKey('name_${vr.id}'), initialValue: vr.variantName, decoration: const InputDecoration(labelText: 'Nama Varian', border: OutlineInputBorder()), onChanged: (v) => notifier.updateVariantDetail(vr.id, variantName: v))), const SizedBox(width: 8), Expanded(flex: 2, child: TextFormField(key: ValueKey('price_${vr.id}'), initialValue: vr.sellPrice.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()), onChanged: (v) => notifier.updateVariantDetail(vr.id, sellPrice: double.tryParse(v)?? 0)))])]))); }),

        _buildSectionHeader('6. Kontrol Stok & Pengaman Alert'),
        Row(children: [Expanded(child: TextFormField(initialValue: state.stock.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok Awal Fisik', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(stock: double.tryParse(v)?? 0))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: state.minStock.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Batas Minimum Alert', border: OutlineInputBorder()), onChanged: (v) => notifier.updateField(minStock: double.tryParse(v)?? 5)))]),

        _buildSectionHeader('7. Asset Foto & Dokumen Produk'),
        Row(children: [Expanded(child: Container(height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), Text('Foto Produk', style: TextStyle(fontSize: 10))])))), const SizedBox(width: 8), Expanded(child: Container(height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code, color: Colors.grey), Text('Barcode', style: TextStyle(fontSize: 10))]))))]),

        _buildSectionHeader('8. Status & Compliance'),
Row(children: [
  Expanded(child: DropdownButtonFormField<String>(
    value: state.statusActive, 
    items: const [
      DropdownMenuItem(value: 'aktif', child: Text('Aktif Dijual')), 
      DropdownMenuItem(value: 'nonaktif', child: Text('Non-Aktif / Arsip'))
    ], 
    onChanged: (v) => notifier.updateField(statusActive: v!), 
    decoration: const InputDecoration(labelText: 'Status Produk', border: OutlineInputBorder())
  )), 
  const SizedBox(width: 8), 
  Expanded(child: TextFormField(
    initialValue: '', 
    decoration: const InputDecoration(labelText: 'Rak / Gudang (Catatan)', border: OutlineInputBorder(), hintText: 'RAK-A1'), 
    onChanged: (v) {} // cuma catatan, gak wajib save
  ))
]);
}