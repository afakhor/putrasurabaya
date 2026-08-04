import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../../../../core/database/tables/category_table.dart';
import '../../../../core/utils/config.dart';
import '../../../../core/utils/format_rupiah.dart';
import 'master_fab_perkakas.dart';
import 'product_form_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterCategoryProvider = StateProvider<String?>((ref) => null);
final filterStockStatusProvider = StateProvider<String?>((ref) => null);
final sortByProvider = StateProvider<String>((ref) => 'name_asc');

final productsStreamProvider = StreamProvider.autoDispose<List<ProductData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.select(db.products).watch();
});

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});
  @override ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override void dispose(){ _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onSearchChanged(String q){
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), (){
      ref.read(searchQueryProvider.notifier).state = q.toLowerCase();
    });
  }

  Future<void> _openForm(BuildContext context, {ProductData? product}) async {
    final notifier = ref.read(productFormProvider.notifier);
    final db = ref.read(localDatabaseProvider);
    if(product!=null){
      final units = await (db.select(db.productUnits)..where((t)=> t.productId.equals(product.id))).get();
      final variants = await (db.select(db.productVariants)..where((t)=> t.productId.equals(product.id))).get();
      final assets = await (db.select(db.productAssets)..where((t)=> t.productId.equals(product.id))).get();
      notifier.setProduct(product, units, variants, assets.map((e)=> e.imagePath).toList());
    } else {
      ref.invalidate(productFormProvider);
    }
    if(context.mounted){
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx)=> FractionallySizedBox(heightFactor: 0.92, child: const FormMasterBarangSheet()),
      );
    }
  }

  @override Widget build(BuildContext context){
    final query = ref.watch(searchQueryProvider);
    final catFilter = ref.watch(filterCategoryProvider);
    final stockFilter = ref.watch(filterStockStatusProvider);
    final sortRule = ref.watch(sortByProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final categoryDao = ref.read(localDatabaseProvider).categoryDao;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: productsAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('Error: $e')),
        data: (rawProducts){
          // filter
          var filtered = rawProducts.where((p){
            final mq = p.name.toLowerCase().contains(query) || (p.barcode??'').toLowerCase().contains(query) || (p.code??'').toLowerCase().contains(query) || p.id.toLowerCase().contains(query);
            final mc = catFilter==null || p.categoryId==catFilter;
            bool ms=true;
            if(stockFilter=='menipis') ms = p.stock <= p.minStock && p.stock>0;
            if(stockFilter=='habis') ms = p.stock<=0;
            if(stockFilter=='aman') ms = p.stock > p.minStock;
            return mq && mc && ms;
          }).toList();

          filtered.sort((a,b){
            switch(sortRule){
              case 'name_desc': return b.name.compareTo(a.name);
              case 'price_desc': return b.sellPriceGeneral.compareTo(a.sellPriceGeneral);
              case 'price_asc': return a.sellPriceGeneral.compareTo(b.sellPriceGeneral);
              case 'stock_asc': return a.stock.compareTo(b.stock);
              case 'stock_desc': return b.stock.compareTo(a.stock);
              default: return a.name.compareTo(b.name);
            }
          });

          return Column(children: [
            _buildTopBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
              child: Row(children: [
                _statChip('Total SKU: ${rawProducts.length}', Colors.blue),
                const SizedBox(width:6),
                _statChip('Filter: ${filtered.length}', Colors.green),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                ? Center(child: GlassCard(child: const Text('Tidak ada perkakas, tambah via FAB hijau', style: TextStyle(fontFamily:'Poppins'))))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12,0,12,90),
                    itemCount: filtered.length,
                    itemBuilder: (c,i){
                      final prod = filtered[i];
                      Color sc = prod.stock<=0? Colors.red : prod.stock<=prod.minStock? Colors.orange : const Color(0xFF00A65A);
                      return Padding(
                        padding: const EdgeInsets.only(bottom:8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          onTap: ()=> _openForm(context, product: prod),
                          child: Row(children: [
                            Container(width:42, height:42, decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.handyman, color: sc)),
                            const SizedBox(width:10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(prod.name, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily:'Poppins')),
                              const SizedBox(height:2),
                              Text('${prod.categoryId} • ${prod.brand??''} • ${formatRupiah(prod.sellPriceGeneral)}', maxLines:1, style: const TextStyle(fontSize:10, color: Colors.black54, fontFamily:'Poppins')),
                              const SizedBox(height:2),
                              Text('SKU: ${prod.code?? prod.id} • ${prod.stock.toStringAsFixed(0)} ${prod.unit}', style: TextStyle(fontSize:10, color: sc, fontWeight: FontWeight.bold, fontFamily:'Poppins')),
                            ])),
                            const Icon(Icons.chevron_right, size:18, color: Colors.black26),
                          ]),
                        ),
                      );
                    },
                  ),
            ),
          ]);
        },
      ),
      floatingActionButton: MasterFabPerkakas(onOpenForm: (ctx,{product})=> _openForm(ctx, product: product)),
    );
  }

  Widget _buildTopBar(BuildContext context){
    return GlassCard(
      radius: 0,
      padding: const EdgeInsets.fromLTRB(12,12,12,12),
      child: Column(children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontFamily:'Poppins', fontSize:13),
          decoration: InputDecoration(
            hintText: 'Cari Perkakas, SKU, Barcode...',
            hintStyle: const TextStyle(fontFamily:'Poppins', fontSize:12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00A65A)),
            suffixIcon: _searchCtrl.text.isNotEmpty? IconButton(icon: const Icon(Icons.clear, size:18), onPressed: (){ _searchCtrl.clear(); _onSearchChanged(''); }) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical:0, horizontal:12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height:10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip(label:'Semua', selected: ref.watch(filterCategoryProvider)==null, onTap: ()=> ref.read(filterCategoryProvider.notifier).state=null),
            const SizedBox(width:6),
            _filterChip(label:'Menipis', selected: ref.watch(filterStockStatusProvider)=='menipis', onTap: (){
              final cur=ref.read(filterStockStatusProvider);
              ref.read(filterStockStatusProvider.notifier).state = cur=='menipis'? null : 'menipis';
            }, color: Colors.orange),
            const SizedBox(width:6),
            _filterChip(label:'Habis', selected: ref.watch(filterStockStatusProvider)=='habis', onTap: (){
              final cur=ref.read(filterStockStatusProvider);
              ref.read(filterStockStatusProvider.notifier).state = cur=='habis'? null : 'habis';
            }, color: Colors.red),
            const SizedBox(width:6),
            StreamBuilder<List<CategoryData>>(
              stream: ref.read(localDatabaseProvider).categoryDao.watchByType(CategoryType.product),
              builder: (c,snap){
                final cats = snap.data?? [];
                return Row(children: cats.take(8).map((cat){
                  final sel = ref.watch(filterCategoryProvider)==cat.name;
                  return Padding(padding: const EdgeInsets.only(right:6), child: _filterChip(label:cat.name, selected: sel, onTap: ()=> ref.read(filterCategoryProvider.notifier).state = sel? null : cat.name));
                }).toList());
              },
            ),
          ]),
        ),
        const SizedBox(height:6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _sortChip('A-Z', 'name_asc'),
            _sortChip('Z-A', 'name_desc'),
            _sortChip('Harga ↑', 'price_asc'),
            _sortChip('Harga ↓', 'price_desc'),
            _sortChip('Stok ↓', 'stock_desc'),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip({required String label, required bool selected, required VoidCallback onTap, Color? color}){
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize:11, fontFamily:'Poppins', color: selected? Colors.white : Colors.black87)),
      selected: selected,
      selectedColor: color?? const Color(0xFF00A65A),
      backgroundColor: Colors.white.withOpacity(0.9),
      onSelected: (_)=> onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _sortChip(String label, String value){
    final sel = ref.watch(sortByProvider)==value;
    return Padding(padding: const EdgeInsets.only(right:6), child: ChoiceChip(label: Text(label, style: TextStyle(fontSize:10, fontFamily:'Poppins', color: sel? Colors.white : Colors.black87)), selected: sel, selectedColor: Colors.black87, backgroundColor: Colors.white, onSelected: (_)=> ref.read(sortByProvider.notifier).state=value));
  }

  Widget _statChip(String text, Color color){
    return Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), child: Text(text, style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: color, fontFamily:'Poppins')));
  }
}

class FormMasterBarangSheet extends ConsumerStatefulWidget {
  const FormMasterBarangSheet({super.key});
  @override ConsumerState<FormMasterBarangSheet> createState()=> _FormMasterBarangSheetState();
}

class _FormMasterBarangSheetState extends ConsumerState<FormMasterBarangSheet> {
  @override Widget build(BuildContext context){
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final categoryStream = ref.read(localDatabaseProvider).categoryDao.watchByType(CategoryType.product);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(state.name.isEmpty? 'Tambah Perkakas Baru' : 'Edit ${state.name}', style: const TextStyle(fontSize:14, fontWeight: FontWeight.bold, fontFamily:'Poppins')),
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('1. Identitas Perkakas', style: TextStyle(fontWeight: FontWeight.bold, fontFamily:'Poppins', fontSize:12, color: Color(0xFF007F00))),
          const SizedBox(height:10),
          TextFormField(initialValue: state.name, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'Nama Perkakas Lengkap *', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(name: v)),
          const SizedBox(height:10),
          StreamBuilder<List<CategoryData>>(stream: categoryStream, builder: (c,snap){
            final cats = snap.data?? [];
            return DropdownButtonFormField<String>(
              value: cats.any((e)=> e.name==state.categoryId)? state.categoryId : null,
              hint: const Text('Pilih 24 Kategori Perkakas', style: TextStyle(fontFamily:'Poppins', fontSize:12)),
              items: cats.map((e)=> DropdownMenuItem(value: e.name, child: Text(e.name, style: const TextStyle(fontFamily:'Poppins', fontSize:12)))).toList(),
              onChanged: (v)=> notifier.updateField(categoryId: v),
              decoration: const InputDecoration(labelText:'Kategori Perkakas', border: OutlineInputBorder()),
            );
          }),
          const SizedBox(height:10),
          TextFormField(initialValue: state.barcode, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'Barcode / SKU', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(barcode: v)),
        ])),
        const SizedBox(height:12),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('2. Harga & Stok', style: TextStyle(fontWeight: FontWeight.bold, fontFamily:'Poppins', fontSize:12, color: Color(0xFF007F00))),
          const SizedBox(height:10),
          Row(children: [
            Expanded(child: TextFormField(initialValue: state.buyPrice.toStringAsFixed(0), keyboardType: TextInputType.number, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'HPP Modal', prefixText:'Rp ', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(buyPrice: double.tryParse(v)??0))),
            const SizedBox(width:8),
            Expanded(child: TextFormField(initialValue: state.sellPriceGeneral.toStringAsFixed(0), keyboardType: TextInputType.number, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'Harga Jual', prefixText:'Rp ', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(sellPriceGeneral: double.tryParse(v)??0))),
          ]),
          const SizedBox(height:10),
          Row(children: [
            Expanded(child: TextFormField(initialValue: state.stock.toStringAsFixed(0), keyboardType: TextInputType.number, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'Stok', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(stock: double.tryParse(v)??0))),
            const SizedBox(width:8),
            Expanded(child: TextFormField(initialValue: state.unit, style: const TextStyle(fontFamily:'Poppins'), decoration: const InputDecoration(labelText:'Satuan', border: OutlineInputBorder()), onChanged: (v)=> notifier.updateField(unit: v))),
          ]),
        ])),
        const SizedBox(height:20),
        SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
          final ok = await notifier.saveProduct();
          if(ok && context.mounted){
            // catat mutasi awal jika produk baru
            if(state.stock>0){
              final db=ref.read(localDatabaseProvider);
              await db.stockMutationDao.addMutation(productId: state.id, type:'opname', quantity: state.stock, stockAfter: state.stock, hpp: state.buyPrice, notes:'Stok awal FAB', refNo:'INIT');
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perkakas disimpan & mutasi dicatat')));
          }
        }, child: const Text('SIMPAN PERKAKAS', style: TextStyle(color:Colors.white, fontWeight: FontWeight.bold, fontFamily:'Poppins')))),
      ]),
    );
  }
}