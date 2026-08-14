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

class MasterBarangPageFinal extends ConsumerStatefulWidget {
  const MasterBarangPageFinal({super.key});
  @override ConsumerState<MasterBarangPageFinal> createState() => _MasterFinalState();
}

class _MasterFinalState extends ConsumerState<MasterBarangPageFinal> {
  String q = '';

  String _sku5(String? code){
    if(code==null || code.isEmpty) return '00000';
    final c = code.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if(c.length<=5) return c;
    return c.substring(c.length-5);
  }

  Future<Map<String,double>> _getStockSummary(String productId) async {
    final db = ref.read(localDatabaseProvider);
    final all = await (db.select(db.stockMutations)..where((t)=> t.productId.equals(productId))).get();
    double masuk = 0, keluar = 0;
    for(final m in all){
      if(m.quantity > 0) masuk += m.quantity;
      else keluar += m.quantity.abs();
    }
    final prod = await db.productDao.getProductById(productId);
    return {'sisa': prod?.stock??0, 'masuk': masuk, 'keluar': keluar};
  }

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
    final existing = await (db.select(db.productAssets)..where((t)=> t.productId.equals(p.id) & t.isPrimary.equals(true))).getSingleOrNull();
    if(existing!=null){
      await (db.update(db.productAssets)..where((t)=> t.id.equals(existing.id))).write(ProductAssetsCompanion(imagePath: Value(newPath)));
    } else {
      await db.into(db.productAssets).insert(ProductAssetsCompanion.insert(id: 'AST-${DateTime.now().millisecondsSinceEpoch}', productId: p.id, imagePath: newPath, isPrimary: const Value(true), sortOrder: const Value(0)));
    }
  }

  Widget _imageOrText(ProductData p, ProductAssetData? asset){
    if(asset!=null && File(asset.imagePath).existsSync()){
      return ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.file(File(asset.imagePath), width: double.infinity, height: 130, fit: BoxFit.cover));
    }
    return Container(
      width: double.infinity, height: 130,
      decoration: BoxDecoration(color: Colors.primaries[p.name.hashCode % Colors.primaries.length].shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Center(child: Text('${p.name}\n${_sku5(p.code)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3))), // 16px
    );
  }

  void _showStockDetail(ProductData p) async {
    final summary = await _getStockSummary(p.id);
    if(!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:40,height:4,decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height:12),
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // 18px
          Text('SKU: ${p.code} | Rak: ${p.rackLocation??'-'}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height:16),
          // 3 KOLOM STOCK - FONT 16px
          Row(children: [
            Expanded(child: _stockBox('SISA STOCK', '${summary['sisa']!.toInt()} ${p.unit}', Colors.green, Icons.inventory_2_rounded)),
            const SizedBox(width:8),
            Expanded(child: _stockBox('MASUK', '+${summary['masuk']!.toInt()}', Colors.blue, Icons.arrow_downward_rounded)),
            const SizedBox(width:8),
            Expanded(child: _stockBox('KELUAR', '-${summary['keluar']!.toInt()}', Colors.red, Icons.arrow_upward_rounded)),
          ]),
          const SizedBox(height:16),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
            onPressed: (){ Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))); },
            child: const Text('KARTU STOCK LENGKAP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), // 16px
          )),
        ]),
      ),
    );
  }

  Widget _stockBox(String label, String value, Color c, IconData icon) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))),
    child: Column(children: [
      Icon(icon, color: c, size: 20),
      const SizedBox(height:4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)), // 16px STOCK MUTASI
    ]),
  );

  @override Widget build(BuildContext context){
    final products = ref.watch(allProductsStreamProvider);
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.60, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: f.length,
              itemBuilder: (c,i){
                final p=f[i];
                final db = ref.watch(localDatabaseProvider);
                return StreamBuilder<List<ProductAssetData>>(
                  stream: (db.select(db.productAssets)..where((t)=> t.productId.equals(p.id) & t.isPrimary.equals(true))).watch(),
                  builder: (ctx, snapAsset){
                    final asset = snapAsset.data?.isNotEmpty==true? snapAsset.data!.first : null;
                    return app_config.GlassCard(
                      padding: EdgeInsets.zero, radius: 16,
                      onTap: ()=> _showStockDetail(p),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(children: [
                          _imageOrText(p, asset),
                          Positioned(top: 6, right: 6, child: InkWell(onTap: ()=> _uploadImage(p), child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)))),
                          Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: p.stock<=p.minStock?Colors.red:Colors.green, borderRadius: BorderRadius.circular(6)), child: Text('Stok:${p.stock.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                        ]),
                        Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
                          // KIRI: STOCK MUTASI - FONT 16px
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // 16px
                            Text('SKU:${p.code??'-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Rak:${p.rackLocation??'-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), // 12px
                            const Divider(height: 8),
                            const Text('Mutasi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            // STOCK MUTASI FONT 16px
                            FutureBuilder<List<StockMutationData>>(future: (db.select(db.stockMutations)..where((t)=> t.productId.equals(p.id))..orderBy([(t)=> OrderingTerm.desc(t.date)])..limit(2)).get(), builder: (_, s){
                              final mut=s.data??[];
                              if(mut.isEmpty) return const Text('Belum ada', style: TextStyle(fontSize: 16, color: Colors.grey)); // 16px
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: mut.map((m)=> Text('${m.type.substring(0,3)} ${m.quantity>0?'+':''}${m.quantity.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: m.quantity>0?Colors.green:Colors.red))).toList()); // 16px
                            }),
                          ])),
                          Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 6)),
                          // KANAN: HARGA - FONT 16,18,20px
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('HPP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(formatRupiah(p.buyPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)), // 16px
                            const SizedBox(height: 4),
                            const Text('JUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(formatRupiah(p.sellPriceGeneral>0? p.sellPriceGeneral : p.sellPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)), // 18px
                            const Divider(height: 6),
                            Text('T1: ${formatRupiah(p.sellPriceTier1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('T2: ${formatRupiah(p.sellPriceTier2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('T3: ${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)), // 20px
                          ])),
                        ]))),
                      ]),
                    );
                  },
                );
              },
            );
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error $e')),
        )),
      ]),
    );
  }
}