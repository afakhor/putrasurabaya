import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart' as app_config;
import '../../../../core/utils/format_rupiah.dart';
import 'master_fab_perkakas.dart';
import 'product_form_provider.dart';
import '../stock/kartu_stock_page.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = q.toLowerCase().trim();
    });
  }

  String _sku5(String? code) {
    if (code == null || code.isEmpty) return '00000';
    final c = code.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (c.length <= 5) return c;
    return c.substring(c.length - 5);
  }

  Future<Map<String, double>> _getStockSummary(String productId) async {
    final db = ref.read(localDatabaseProvider);
    final all = await (db.select(db.stockMutations)..where((t) => t.productId.equals(productId))).get();
    double masuk = 0, keluar = 0;
    for (final m in all) {
      if (m.quantity > 0) masuk += m.quantity;
      else keluar += m.quantity.abs();
    }
    final prod = await db.productDao.getProductById(productId);
    return {'sisa': prod?.stock?? 0, 'masuk': masuk, 'keluar': keluar};
  }

  Future<void> _uploadImage(ProductData p) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/product_images');
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    final newPath = '${imgDir.path}/${p.id}.jpg';
    await File(x.path).copy(newPath);
    final db = ref.read(localDatabaseProvider);
    final existing = await (db.select(db.productAssets)..where((t) => t.productId.equals(p.id) & t.isPrimary.equals(true))).getSingleOrNull();
    if (existing!= null) {
      await (db.update(db.productAssets)..where((t) => t.id.equals(existing.id))).write(ProductAssetsCompanion(imagePath: Value(newPath)));
    } else {
      await db.into(db.productAssets).insert(ProductAssetsCompanion.insert(
          id: 'AST-${DateTime.now().millisecondsSinceEpoch}',
          productId: p.id,
          imagePath: newPath,
          isPrimary: const Value(true),
          sortOrder: const Value(0)));
    }
  }

  Widget _imageOrText(ProductData p, ProductAssetData? asset) {
    if (asset!= null && File(asset.imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.file(File(asset.imagePath), width: double.infinity, height: 130, fit: BoxFit.cover),
      );
    }
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
          color: Colors.primaries[p.name.hashCode % Colors.primaries.length].shade100,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Center(
        child: Text('${p.name}\n${_sku5(p.code)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3)),
      ),
    );
  }

  void _showStockDetail(ProductData p) async {
    final summary = await _getStockSummary(p.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('SKU: ${p.code} | Rak: ${p.rackLocation?? '-'}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _stockBox('SISA STOCK', '${summary['sisa']!.toInt()} ${p.unit}', Colors.green, Icons.inventory_2_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _stockBox('MASUK', '+${summary['masuk']!.toInt()}', Colors.blue, Icons.arrow_downward_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _stockBox('KELUAR', '-${summary['keluar']!.toInt()}', Colors.red, Icons.arrow_upward_rounded)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), onPressed: () { Navigator.pop(context); _openForm(context, product: p); }, child: const Text('EDIT HARGA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => KartuStockPage(productId: p.id))); }, child: const Text('KARTU STOCK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))),
          ]),
        ]),
      ),
    );
  }

  Widget _stockBox(String label, String value, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)),
      ]),
    );
  }

  Future<void> _openForm(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);
    if (product!= null) {
      final units = await (db.select(db.productUnits)..where((t) => t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t) => t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t) => t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e) => e.imagePath).toList());
    } else {
      notifier.resetForm();
    }
    if (context.mounted) {
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const FractionallySizedBox(heightFactor: 0.92, child: FormMasterBarangSheet()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))),
        error: (e, s) => Center(child: Text('Error DB: $e')),
        data: (List<ProductData> raw) {
          var filtered = raw.where((p) {
            if (query.isEmpty) return true;
            return p.name.toLowerCase().contains(query) || (p.code?? '').toLowerCase().contains(query) || (p.brand?? '').toLowerCase().contains(query);
          }).toList();
          return Column(children: [
            Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), child: TextField(controller: _searchCtrl, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: 'Cari Perkakas / SKU / Brand...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)), suffixIcon: query.isNotEmpty? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); ref.read(searchQueryProvider.notifier).state = ''; }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: const Color(0xFFF5F5F5)))),
            if (filtered.isEmpty) const Expanded(child: Center(child: Text('Belum ada produk')))
            else Expanded(child: GridView.builder(padding: const EdgeInsets.fromLTRB(10, 8, 10, 90), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.60, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: filtered.length, itemBuilder: (c, i) {
                  final p = filtered[i];
                  final db = ref.watch(localDatabaseProvider);
                  return StreamBuilder<List<ProductAssetData>>(stream: (db.select(db.productAssets)..where((t) => t.productId.equals(p.id) & t.isPrimary.equals(true))).watch(), builder: (ctx, snapAsset) {
                    final asset = snapAsset.data?.isNotEmpty == true? snapAsset.data!.first : null;
                    return app_config.GlassCard(
                      padding: EdgeInsets.zero,
                      radius: 16,
                      onTap: () => _showStockDetail(p),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(children: [
                          _imageOrText(p, asset),
                          Positioned(top: 6, right: 6, child: InkWell(onTap: () => _uploadImage(p), child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)))),
                          Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: p.stock <= p.minStock? Colors.red : Colors.green, borderRadius: BorderRadius.circular(6)), child: Text('Stok:${p.stock.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                          Positioned(bottom: 6, right: 6, child: InkWell(onTap: () => _openForm(context, product: p), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit, size: 14, color: Colors.black87)))),
                        ]),
                        Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('SKU:${p.code?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Rak:${p.rackLocation?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            const Divider(height: 8),
                            const Text('Mutasi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            FutureBuilder<List<StockMutationData>>(future: (db.select(db.stockMutations)..where((t) => t.productId.equals(p.id))..orderBy([(t) => OrderingTerm.desc(t.date)])..limit(2)).get(), builder: (_, s) {
                              final mut = s.data?? [];
                              if (mut.isEmpty) return const Text('Belum ada', style: TextStyle(fontSize: 16, color: Colors.grey));
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: mut.map((m) => Text('${m.type.substring(0, 3)} ${m.quantity > 0? '+' : ''}${m.quantity.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: m.quantity > 0? Colors.green : Colors.red))).toList());
                            }),
                          ])),
                          Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 6)),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('HPP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(formatRupiah(p.buyPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 4),
                            const Text('JUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(formatRupiah(p.sellPriceGeneral > 0? p.sellPriceGeneral : p.sellPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            const Divider(height: 6),
                            Text('T1: ${formatRupiah(p.sellPriceTier1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('T2: ${formatRupiah(p.sellPriceTier2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('T3: ${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ])),
                        ]))),
                      ]),
                    );
                  });
                }));
          ]);
        },
      ),
      floatingActionButton: MasterFabPerkakas(onOpenForm: (ctx, {product}) => _openForm(ctx, product: product)),
    );
  }
}

class FormMasterBarangSheet extends ConsumerStatefulWidget {
  const FormMasterBarangSheet({super.key});
  @override
  ConsumerState<FormMasterBarangSheet> createState() => _FormMasterBarangSheetState();
}

class _FormMasterBarangSheetState extends ConsumerState<FormMasterBarangSheet> {
  Color _marginColor(double m) {
    if (m < 0) return Colors.red.shade700;
    if (m < 10) return Colors.red;
    if (m < 20) return Colors.orange;
    return const Color(0xFF00A65A);
  }

  Widget _buildHargaInput({required String label, required double harga, required double margin, required double laba, required Function(double) onChanged}) {
    final col = _marginColor(margin);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(initialValue: harga == 0? '' : harga.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, prefixText: 'Rp ', border: const OutlineInputBorder(), suffixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)))), onChanged: (v) => onChanged(double.tryParse(v)?? 0)),
      const SizedBox(height: 4),
      Text('Laba ${formatRupiah(laba)} • Margin ${margin.toStringAsFixed(1)}% • HPP ${formatRupiah(ref.read(productFormProvider).buyPrice)}', style: TextStyle(fontSize: 10, color: col)),
      const SizedBox(height: 12),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final allProducts = ref.watch(allProductsStreamProvider);
    return Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.white, title: Text(state.isEditMode? 'Edit Harga Jual Barang' : 'Edit Harga Jual Barang', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Pilih Barang Master (Index SKU)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 8),
      allProducts.when(data: (List<ProductData> list) => DropdownButtonFormField<String>(value: state.id.isEmpty? null : list.any((e) => e.id == state.id)? state.id : null, decoration: const InputDecoration(labelText: 'Pilih Nama Barang / SKU dari Master *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)), items: list.map((ProductData p) => DropdownMenuItem<String>(value: p.id, child: Text('${p.code?? ''} - ${p.name} (HPP:${formatRupiah(p.buyPrice)})', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(), onChanged: (id) async { if (id == null) return; final db = ref.read(localDatabaseProvider); final prod = await db.productDao.getProductById(id); if (prod!= null) { final units = await (db.select(db.productUnits)..where((t) => t.productId.equals(prod.id))).get(); final variants = await (db.select(db.productVariants)..where((t) => t.productId.equals(prod.id))).get(); final assets = await (db.select(db.productAssets)..where((t) => t.productId.equals(prod.id))).get(); notifier.setProduct(prod, units, variants, assets.map((e) => e.imagePath).toList()); } },), loading: () => const LinearProgressIndicator(), error: (e, s) => Text('Error $e')),
      const SizedBox(height: 12),
      if (state.id.isNotEmpty) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${state.code} - ${state.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text('HPP Auto: ${formatRupiah(state.buyPrice)} (dari Pembelian Weighted Avg) • Stok: ${state.stock} • Rak: ${state.rackLocation}', style: const TextStyle(fontSize: 11, color: Colors.blue))])),
      const SizedBox(height: 16),
      const Divider(),
      const Text('HARGA JUAL - MARGIN % DARI HPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF007F00))),
      const SizedBox(height: 12),
      if (state.id.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Pilih barang master dulu di atas', style: TextStyle(color: Colors.grey))))
      else...[
        _buildHargaInput(label: 'Harga Jual Umum *', harga: state.sellPriceGeneral, margin: state.marginGeneral, laba: state.labaGeneral, onChanged: (v) => notifier.updateField(sellPriceGeneral: v)),
        _buildHargaInput(label: 'Tier 1 - Ecer Member', harga: state.sellPriceTier1, margin: state.marginTier1, laba: state.labaTier1, onChanged: (v) => notifier.updateField(sellPriceTier1: v)),
        _buildHargaInput(label: 'Tier 2 - Grosir (>10)', harga: state.sellPriceTier2, margin: state.marginTier2, laba: state.labaTier2, onChanged: (v) => notifier.updateField(sellPriceTier2: v)),
        _buildHargaInput(label: 'Tier 3 - Distributor (>50)', harga: state.sellPriceTier3, margin: state.marginTier3, laba: state.labaTier3, onChanged: (v) => notifier.updateField(sellPriceTier3: v)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { final ok = await notifier.saveProduct(); if (ok && context.mounted) Navigator.pop(context); }, child: const Text('UPDATE HARGA JUAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]
    ]));
  }
}