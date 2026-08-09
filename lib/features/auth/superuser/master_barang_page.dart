import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';
import '../../../core/utils/format_rupiah.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';
import 'product/product_page.dart';
import 'product/product_form_provider.dart';
import 'package:drift/drift.dart';

class MasterBarangPage extends StatelessWidget {
  const MasterBarangPage({super.key});
  @override Widget build(BuildContext context) => const MasterBarangPageFinal();
}

final productFilterProvider = StateProvider<String>((ref)=> 'semua');
final productSortProvider = StateProvider<String>((ref)=> 'nama_az');

class MasterBarangPageFinal extends ConsumerStatefulWidget {
  const MasterBarangPageFinal({super.key});
  @override ConsumerState<MasterBarangPageFinal> createState()=> _MasterFinalState();
}

class _MasterFinalState extends ConsumerState<MasterBarangPageFinal> {
  String q='';

  // 24 KATEGORI PLUS
  final List<String> kategoriList = [
    'Perkakas Tangan','Perkakas Listrik','Perkakas Ukur','Pipa & Plumbing','Listrik & Lampu',
    'Cat & Lem','Besi & Baja','Baut & Mur','Engsel & Kunci','Roda & Kaster',
    'Selang & Karet','Sikat & Kuas','Mata Bor & Pisau','Gergaji & Gerinda','Kabel & Saklar',
    'Keran & Shower','Paku & Sekrup','Amplas & Poles','Ember & Tangga','Gembok & Grendel',
    'Kunci Inggris & Obeng','Tang & Palu','Safety & Helm','Grosir Campur'
  ];

  void _openMasterAdd() {
    final nameC = TextEditingController();
    final codeC = TextEditingController(text: 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'); // AUTO SKU
    final brandC = TextEditingController();
    final rakC = TextEditingController();
    final barcodeC = TextEditingController();
    final descC = TextEditingController();
    String kategori = kategoriList.first;
    String unit = 'pcs';

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=> StatefulBuilder(builder: (ctx,setS)=> Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tambah Barang Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize:16)),
        const Text('Hanya data master, tanpa harga & stok', style: TextStyle(fontSize:11, color: Colors.grey)),
        const SizedBox(height:16),
        TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Barang *', border: OutlineInputBorder())),
        const SizedBox(height:12),
        Row(children: [
          Expanded(child: TextField(controller: codeC, decoration: const InputDecoration(labelText:'SKU Auto *', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          IconButton(onPressed: (){ codeC.text='SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'; }, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height:12),
        DropdownButtonFormField(value: kategori, decoration: const InputDecoration(labelText:'Kategori (24+)', border: OutlineInputBorder()), items: kategoriList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:12)))).toList(), onChanged: (v)=> setS(()=> kategori=v!)),
        const SizedBox(height:12),
        Row(children: [
          Expanded(child: TextField(controller: brandC, decoration: const InputDecoration(labelText:'Brand', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: DropdownButtonFormField(value: unit, decoration: const InputDecoration(labelText:'Satuan', border: OutlineInputBorder()), items: const ['pcs','set','meter','kg','dus','lusin','roll'].map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> setS(()=> unit=v!))),
        ]),
        const SizedBox(height:12),
        Row(children: [
          Expanded(child: TextField(controller: rakC, decoration: const InputDecoration(labelText:'Rak Lokasi', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: barcodeC, decoration: const InputDecoration(labelText:'Barcode', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:12),
        TextField(controller: descC, maxLines:2, decoration: const InputDecoration(labelText:'Deskripsi / Spesifikasi', border: OutlineInputBorder())),
        const SizedBox(height:20),
        SizedBox(width:double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
          if(nameC.text.trim().isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama wajib'))); return; }
          final db = ref.read(localDatabaseProvider);
          await db.productDao.createProductQuick(
            name: nameC.text.trim(), code: codeC.text.trim(), brand: brandC.text.trim(),
            rackLocation: rakC.text.trim(), categoryId: kategori,
          );
          // simpan extra
          final prod = await db.productDao.getByCode(codeC.text.trim());
          if(prod!=null){
            await (db.update(db.products)..where((t)=> t.id.equals(prod.id))).write(ProductsCompanion(
              barcode: Value(barcodeC.text.trim()), description: Value(descC.text.trim()), unit: Value(unit), updatedAt: Value(DateTime.now())
            ));
          }
          if(context.mounted){ Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameC.text} disimpan SKU:${codeC.text}'))); }
        }, child: const Text('SIMPAN MASTER', style: TextStyle(color:Colors.white, fontWeight: FontWeight.bold)))),
      ]))))));
  }

  void _openEditHarga() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_)=> const FractionallySizedBox(heightFactor: 0.92, child: FormMasterBarangSheet()));
  }

  @override Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final sort = ref.watch(productSortProvider);
    final products = ref.watch(allProductsStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(title: const Text('Master Barang - Tier'), backgroundColor: const Color(0xFF00A65A), actions: [
        IconButton(icon: const Icon(Icons.edit), tooltip:'Edit Harga Jual', onPressed: _openEditHarga),
        IconButton(icon: const Icon(Icons.receipt_long), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Smart Search: SKU/Nama/Rak/Brand', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for(final f in ['semua','habis','menipis']) Padding(padding: const EdgeInsets.only(left:8), child: ChoiceChip(label: Text(f.toUpperCase()), selected: filter==f, onSelected: (_)=> ref.read(productFilterProvider.notifier).state=f)))])),
        Expanded(child: products.when(data: (list){
          var f = list.where((p)=> q.isEmpty || p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.rackLocation??'').toLowerCase().contains(q)).toList();
          if(sort=='nama_az') f.sort((a,b)=> a.name.compareTo(b.name));
          if(sort=='nama_za') f.sort((a,b)=> b.name.compareTo(a.name));
          if(sort=='stok_tersedikit') f.sort((a,b)=> a.stock.compareTo(b.stock));
          if(sort=='stok_terbanyak') f.sort((a,b)=> b.stock.compareTo(a.stock));
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
            final p=f[i]; final isHabis = p.stock<=0;
            return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))), child: ListTile(
              leading: CircleAvatar(backgroundColor: isHabis? Colors.red.withOpacity(0.15) : const Color(0xFF00A65A).withOpacity(0.15), child: Icon(Icons.handyman, color: isHabis? Colors.red : const Color(0xFF00A65A))),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
              subtitle: Text('SKU:${p.code} | Stok:${p.stock} | Rak:${p.rackLocation??'-'} | HPP:${formatRupiah(p.buyPrice)}\nUmum:${formatRupiah(p.sellPriceGeneral)} T1:${formatRupiah(p.sellPriceTier1)}', style: const TextStyle(fontSize:10)),
              trailing: PopupMenuButton(onSelected: (v){ if(v=='edit_harga') _openEditHarga(); if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))); }, itemBuilder: (_)=> [const PopupMenuItem(value:'edit_harga', child: Text('Edit Harga Jual')), const PopupMenuItem(value:'kartu', child: Text('Kartu Stok'))]),
            )));
          });
        }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('Error: $e')))),
      ]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: const Color(0xFF00A65A), onPressed: _openMasterAdd, label: const Text('Tambah Barang', style: TextStyle(color:Colors.white)), icon: const Icon(Icons.add_box, color:Colors.white)),
    );
  }
}