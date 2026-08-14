import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart' as app_config;
import '../../../core/utils/format_rupiah.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';

class MasterBarangPage extends StatelessWidget {
  const MasterBarangPage({super.key});
  @override Widget build(BuildContext context) => const MasterBarangPageFinal();
}

final productFilterProvider = StateProvider<String>((ref) => 'semua');

class MasterBarangPageFinal extends ConsumerStatefulWidget {
  const MasterBarangPageFinal({super.key});
  @override ConsumerState<MasterBarangPageFinal> createState() => _MasterFinalState();
}

class _MasterFinalState extends ConsumerState<MasterBarangPageFinal> {
  String q = '';
  final List<String> kategoriList = [
    'Perkakas Tangan','Perkakas Listrik','Perkakas Ukur','Pipa & Plumbing','Listrik & Lampu',
    'Cat & Lem','Besi & Baja','Baut & Mur','Engsel & Kunci','Roda & Kaster',
    'Selang & Karet','Sikat & Kuas','Mata Bor & Pisau','Gergaji & Gerinda','Kabel & Saklar',
    'Keran & Shower','Paku & Sekrup','Amplas & Poles','Ember & Tangga','Gembok & Grendel',
    'Kunci Inggris & Obeng','Tang & Palu','Safety & Helm','Grosir Campur'
  ];

  Future<void> _uploadImage(ProductData p) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if(x==null) return;
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/product_images');
    if(!await imgDir.exists()) await imgDir.create(recursive: true);
    final newPath = '${imgDir.path}/${p.id}.jpg';
    await File(x.path).copy(newPath);
    final db = ref.read(localDatabaseProvider);
    await (db.update(db.products)..where((t)=> t.id.equals(p.id))).write(ProductsCompanion(
      imagePath: Value(newPath),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar disimpan')));
  }

  String _sku5(String? code){
    if(code==null || code.isEmpty) return '00000';
    final c = code.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if(c.length<=5) return c;
    return c.substring(c.length-5);
  }

  Widget _imageOrText(ProductData p){
    if(p.imagePath!=null && p.imagePath!.isNotEmpty && File(p.imagePath!).existsSync()){
      return ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.file(File(p.imagePath!), width: double.infinity, height: 130, fit: BoxFit.cover));
    }
    // TIDAK UPLOAD = NAMA BARANG + 5 ANGKA SKU
    return Container(
      width: double.infinity, height: 130,
      decoration: BoxDecoration(color: Colors.primaries[p.name.hashCode % Colors.primaries.length].shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Center(child: Text('${p.name}\n${_sku5(p.code)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3))),
    );
  }

  @override Widget build(BuildContext context){
    final products = ref.watch(allProductsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(title: const Text('Master Barang - KATALOG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF00A65A), actions: [
        IconButton(icon: const Icon(Icons.history), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'Cari SKU / Nama / Rak / Brand', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(
          data: (list){
            var f = list.where((p)=> q.isEmpty || p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.brand??'').toLowerCase().contains(q)).toList();
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(10,0,10,90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: f.length,
              itemBuilder: (c,i){
                final p=f[i];
                return app_config.GlassCard(
                  padding: EdgeInsets.zero,
                  radius: 16,
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // GAMBAR / TEXT NAMA + SKU5
                    Stack(children: [
                      _imageOrText(p),
                      Positioned(top: 6, right: 6, child: InkWell(onTap: ()=> _uploadImage(p), child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)))),
                      Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: p.stock<=p.minStock?Colors.red:Colors.green, borderRadius: BorderRadius.circular(6)), child: Text('Stok:${p.stock.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                    ]),
                    // 2 KOLOM
                    Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
                      // KIRI: ALL INFO STOCK & MUTASI - FONT 16px
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // 16px
                        const SizedBox(height: 2),
                        Text('SKU:${p.code??'-'}', style: TextStyle(fontSize: 11, color: isDark?Colors.white70:Colors.black54)),
                        Text('Rak:${p.rackLocation??'-'} | ${p.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), // 12
                        const Divider(height: 8),
                        // INFO STOCK
                        FutureBuilder<List<StockMutationData>>(future: (ref.read(localDatabaseProvider).select(ref.read(localDatabaseProvider).stockMutations)..where((t)=> t.productId.equals(p.id))..orderBy([(t)=> OrderingTerm.desc(t.date)])..limit(2)).get(), builder: (_, s){
                          final mut=s.data??[];
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Mutasi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ...mut.map((m)=> Text('${m.type.substring(0,3)} ${m.quantity>0?'+':''}${m.quantity.toInt()}', style: TextStyle(fontSize: 11, color: m.quantity>0?Colors.green:Colors.red))),
                            if(mut.isEmpty) const Text('Belum ada', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ]);
                        }),
                      ])),
                      Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 6)),
                      // KANAN: HARGA HPP & JUAL TIER - FONT 18px,20px
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('HPP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(formatRupiah(p.buyPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)), // 16px
                        const SizedBox(height: 4),
                        const Text('JUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(formatRupiah(p.sellPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)), // 18px
                        const Divider(height: 6),
                        Text('T1: ${formatRupiah(p.sellPriceTier1??p.sellPrice)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), // 14
                        Text('T2: ${formatRupiah(p.sellPriceTier2??p.sellPrice)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('T3: ${formatRupiah(p.sellPriceTier3??p.sellPrice)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)), // 20px paling besar
                      ])),
                    ]))),
                  ]),
                );
              },
            );
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error $e')),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: const Color(0xFF00A65A), onPressed: (){ /* panggil _openMasterAdd Bos yang lama */ }, label: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 16)), icon: const Icon(Icons.add, color: Colors.white)),
    );
  }
}