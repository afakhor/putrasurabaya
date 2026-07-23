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
  CatalogSummary({this.totalSKU=0, this.totalAssetValue=0, this.lowStockCount=0, this.inactiveCount=0});
}

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }
  void _onSearchChanged(String q) { if(_debounce?.isActive??false) _debounce!.cancel(); _debounce = Timer(const Duration(milliseconds: 300), ()=> ref.read(searchQueryProvider.notifier).state=q.toLowerCase()); }

  Future<void> _openFormMasterBarang(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);
    if(product!=null){
      final units = await (db.select(db.productUnits)..where((t)=> t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t)=> t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t)=> t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e)=> e.imagePath).toList());
    } else { ref.invalidate(productFormProvider); }
    if(context.mounted) showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_)=> const FractionallySizedBox(heightFactor: 0.9, child: FormMasterBarangSheet()));
  }

  void _showTextEntryDialog(String title) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx)=> AlertDialog(title: Text('Tambah $title'), content: TextField(controller: c, decoration: InputDecoration(labelText: title)), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Simpan'))]));
  }

  Widget _buildTopActionBar(BuildContext context, List<String> categories) {
    return Container(color: Colors.white, padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [Expanded(child: TextField(controller: _searchCtrl, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: 'Cari Nama, SKU, Barcode...', prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 8), PopupMenuButton<String>(icon: const Icon(Icons.sort, color: Color(0xFF007F00)), onSelected: (v)=> ref.read(sortByProvider.notifier).state=v, itemBuilder: (_)=> const [PopupMenuItem(value: 'name_asc', child: Text('Nama A-Z')), PopupMenuItem(value: 'name_desc', child: Text('Nama Z-A')), PopupMenuItem(value: 'price_desc', child: Text('Harga Tertinggi'))])]),
      const SizedBox(height: 8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        ChoiceChip(label: const Text('Semua Stok'), selected: ref.watch(filterStockStatusProvider)==null, onSelected: (s)=> ref.read(filterStockStatusProvider.notifier).state=null),
        const SizedBox(width: 6),
        ChoiceChip(label: const Text('Stok Menipis'), selected: ref.watch(filterStockStatusProvider)=='menipis', onSelected: (s)=> ref.read(filterStockStatusProvider.notifier).state=s?'menipis':null),
        const SizedBox(width: 6),
        ChoiceChip(label: const Text('Stok Habis'), selected: ref.watch(filterStockStatusProvider)=='habis', onSelected: (s)=> ref.read(filterStockStatusProvider.notifier).state=s?'habis':null),
        for(var cat in categories)...[const SizedBox(width: 6), ChoiceChip(label: Text(cat), selected: ref.watch(filterCategoryProvider)==cat, onSelected: (s)=> ref.read(filterCategoryProvider.notifier).state=s?cat:null)]
      ]))
    ]));
  }

  Widget _buildSummaryRow({required CatalogSummary summary}) => Padding(padding: const EdgeInsets.fromLTRB(12,12,12,4), child: Row(children: [_buildMiniStatCard('Total SKU', summary.totalSKU.toString(), Colors.blue), _buildMiniStatCard('Aset Modal', formatRupiah(summary.totalAssetValue), Colors.green), _buildMiniStatCard('Stok Tipis', summary.lowStockCount.toString(), Colors.orange), _buildMiniStatCard('Non-Aktif', summary.inactiveCount.toString(), Colors.red)]));
  Widget _buildMiniStatCard(String label, String value, Color color) => Expanded(child: Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.3))), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis)]))));
  Widget _buildProductRowCard(ProductData prod) { Color c = prod.stock<=0? Colors.red : prod.stock<=prod.minStock? Colors.orange : const Color(0xFF00A65A); return Card(margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.image_not_supported)), title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SKU: ${prod.id} | ${prod.categoryId}', style: const TextStyle(fontSize: 11, color: Colors.grey)), Row(children: [Text(formatRupiah(prod.sellPriceGeneral), style: const TextStyle(color: Color(0xFF00A65A), fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(width: 8), Text('HPP: ${formatRupiah(prod.buyPrice)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))])]), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text('${prod.stock.toStringAsFixed(0)} Pcs', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)))]), onTap: ()=> _openFormMasterBarang(context, product: prod))); }

  @override Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider); final query = ref.watch(searchQueryProvider); final catF = ref.watch(filterCategoryProvider); final stockF = ref.watch(filterStockStatusProvider); final sortRule = ref.watch(sortByProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: StreamBuilder<List<ProductData>>(stream: db.select(db.products).watch(), builder: (context, snap) {
        if(!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A)));
        final raw = snap.data!; double total=0; int low=0; int non=0; Set<String> cats={'Umum'}; for(var p in raw){ if(p.statusActive!='aktif') non++; if(p.stock<=p.minStock && p.stock>0) low++; if(p.stock>0) total+= p.stock*p.buyPrice; cats.add(p.categoryId); }
        List<ProductData> filtered = raw.where((p){ final mq = p.name.toLowerCase().contains(query) || (p.shortName??'').toLowerCase().contains(query) || p.id.toLowerCase().contains(query) || (p.barcode??'').toLowerCase().contains(query); final mc = catF==null || p.categoryId==catF; bool ms=true; if(stockF=='menipis') ms = p.stock<=p.minStock && p.stock>0; if(stockF=='habis') ms = p.stock<=0; if(stockF=='aman') ms = p.stock>p.minStock; return mq&&mc&&ms; }).toList();
        filtered.sort((a,b){ switch(sortRule){ case 'name_desc': return b.name.compareTo(a.name); case 'price_asc': return a.sellPriceGeneral.compareTo(b.sellPriceGeneral); case 'price_desc': return b.sellPriceGeneral.compareTo(a.sellPriceGeneral); case 'stock_asc': return a.stock.compareTo(b.stock); default: return a.name.compareTo(b.name); } });
        return Column(children: [_buildTopActionBar(context, cats.toList()), _buildSummaryRow(summary: CatalogSummary(totalSKU: raw.length, totalAssetValue: total, lowStockCount: low, inactiveCount: non)), Expanded(child: filtered.isEmpty? const Center(child: Text('Data barang tidak ditemukan.')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, itemBuilder: (_,i)=> _buildProductRowCard(filtered[i])))]);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: RadialHalfCircleFab(onAddProduct: ()=> _openFormMasterBarang(context)),
    );
  }
}

class FormMasterBarangSheet extends ConsumerWidget {
  const FormMasterBarangSheet({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider); final notifier = ref.read(productFormProvider.notifier);
    return Scaffold(appBar: AppBar(title: Text(state.name.isEmpty? 'Tambah Item Baru' : 'Edit Master Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context))]), body: ListView(padding: const EdgeInsets.all(16), children: [TextFormField(initialValue: state.name, decoration: const InputDecoration(labelText: 'Nama Produk Lengkap (Wajib)*', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(name: v)), const SizedBox(height: 24), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { final ok = await notifier.saveProduct(); if(ok && context.mounted) Navigator.pop(context); }, child: const Text('EKSEKUSI SIMPAN DATA BARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))]));
  }
}