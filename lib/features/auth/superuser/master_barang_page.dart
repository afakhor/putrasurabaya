import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';
import '../../../core/utils/format_rupiah.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';
import 'product/product_page.dart';

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
  final List<String> kategoriList = ['Perkakas Tangan','Perkakas Listrik','Perkakas Ukur','Pipa & Plumbing','Listrik & Lampu','Cat & Lem','Besi & Baja','Baut & Mur','Engsel & Kunci','Roda & Kaster','Selang & Karet','Sikat & Kuas','Mata Bor & Pisau','Gergaji & Gerinda','Kabel & Saklar','Keran & Shower','Paku & Sekrup','Amplas & Poles','Ember & Tangga','Gembok & Grendel','Kunci Inggris & Obeng','Tang & Palu','Safety & Helm','Grosir Campur'];

  // === MERAH: KARTU STOK PICKER INDEX SKU ===
  void _openKartuStokPicker(){
    final searchC = TextEditingController();
    String filter = '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=> StatefulBuilder(builder: (ctx,setS){
        final productsAsync = ref.watch(allProductsStreamProvider);
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Container(width:40,height:4,decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height:12),
              const Text('Pilih Barang - Lihat Kartu Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize:14)),
              const SizedBox(height:12),
              TextField(controller: searchC, decoration: InputDecoration(hintText: 'Cari SKU / Nama', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setS(()=> filter=v.toLowerCase())),
            ])),
            Expanded(child: productsAsync.when(data: (list){
              var f = list.where((p)=> filter.isEmpty || p.name.toLowerCase().contains(filter) || (p.code??'').toLowerCase().contains(filter)).toList();
              return ListView.builder(itemCount: f.length, itemBuilder: (c,i){
                final p=f[i];
                return ListTile(leading: const Icon(Icons.history, color: Color(0xFF00A65A)), title: Text('${p.code} - ${p.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)), subtitle: Text('Stok:${p.stock} | Rak:${p.rackLocation??'-'} | HPP:${formatRupiah(p.buyPrice)}', style: const TextStyle(fontSize:10)), onTap: (){ Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))); });
              });
            }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('Error $e')))),
          ]),
        );
      }));
  }

  // === BIRU: EDIT BARANG MASTER INDEX SKU ===
  void _openEditMaster(ProductData p){
    final nameC = TextEditingController(text: p.name);
    final codeC = TextEditingController(text: p.code??'');
    final brandC = TextEditingController(text: p.brand??'');
    final rakC = TextEditingController(text: p.rackLocation??'');
    final barcodeC = TextEditingController(text: p.barcode??'');
    final descC = TextEditingController(text: p.description??'');
    final minC = TextEditingController(text: p.minStock.toStringAsFixed(0));
    String kategori = kategoriList.contains(p.categoryId)? p.categoryId : kategoriList.first;
    String unit = p.unit.isEmpty? 'pcs' : p.unit;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=> StatefulBuilder(builder: (ctx,setS)=> Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Edit Barang Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize:16)),
          Text('SKU: ${p.code} | ID: ${p.id.substring(0,8)}', style: const TextStyle(fontSize:11, color: Colors.grey)),
          const SizedBox(height:16),
          TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Barang *', border: OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(controller: codeC, decoration: const InputDecoration(labelText:'SKU / Kode *', border: OutlineInputBorder())),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value: kategori, decoration: const InputDecoration(labelText:'Kategori', border: OutlineInputBorder()), items: kategoriList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:12)))).toList(), onChanged: (v)=> setS(()=> kategori=v!)),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: brandC, decoration: const InputDecoration(labelText:'Brand', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: DropdownButtonFormField<String>(value: unit, decoration: const InputDecoration(labelText:'Satuan', border: OutlineInputBorder()), items: const ['pcs','set','meter','kg','dus','lusin','roll'].map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> setS(()=> unit=v!)))]),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: rakC, decoration: const InputDecoration(labelText:'Rak', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextField(controller: barcodeC, decoration: const InputDecoration(labelText:'Barcode', border: OutlineInputBorder())))]),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: minC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Min Stok', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextField(controller: descC, decoration: const InputDecoration(labelText:'Deskripsi', border: OutlineInputBorder())))]),
          const SizedBox(height:20),
          SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
            final db = ref.read(localDatabaseProvider);
            await (db.update(db.products)..where((t)=> t.id.equals(p.id))).write(ProductsCompanion(
              name: Value(nameC.text.trim()), code: Value(codeC.text.trim()), brand: Value(brandC.text.trim()),
              rackLocation: Value(rakC.text.trim()), barcode: Value(barcodeC.text.trim()), description: Value(descC.text.trim()),
              categoryId: Value(kategori), unit: Value(unit), minStock: Value(double.tryParse(minC.text)??5),
              updatedAt: Value(DateTime.now()), isSynced: const Value(false),
            ));
            if(mounted){ Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master diupdate'))); }
          }, child: const Text('UPDATE MASTER', style: TextStyle(color:Colors.white, fontWeight: FontWeight.bold)))),
        ])))));
  }

  void _openMasterAdd(){
    final nameC = TextEditingController(); final codeC = TextEditingController(text: 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final brandC = TextEditingController(); final rakC = TextEditingController(); final barcodeC = TextEditingController(); final descC = TextEditingController();
    String kategori = kategoriList.first; String unit = 'pcs';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=> StatefulBuilder(builder: (ctx,setS)=> Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Tambah Barang Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize:16)),
          const SizedBox(height:16),
          TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Barang *', border: OutlineInputBorder())),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: codeC, decoration: const InputDecoration(labelText:'SKU Auto *', border: OutlineInputBorder()))), const SizedBox(width:8), IconButton(onPressed: (){ codeC.text='SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'; }, icon: const Icon(Icons.refresh))]),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(value: kategori, decoration: const InputDecoration(labelText:'Kategori (24+)', border: OutlineInputBorder()), items: kategoriList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:12)))).toList(), onChanged: (v)=> setS(()=> kategori=v!)),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: brandC, decoration: const InputDecoration(labelText:'Brand', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: DropdownButtonFormField<String>(value: unit, decoration: const InputDecoration(labelText:'Satuan', border: OutlineInputBorder()), items: const ['pcs','set','meter','kg','dus','lusin','roll'].map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> setS(()=> unit=v!)))]),
          const SizedBox(height:12),
          Row(children: [Expanded(child: TextField(controller: rakC, decoration: const InputDecoration(labelText:'Rak', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextField(controller: barcodeC, decoration: const InputDecoration(labelText:'Barcode', border: OutlineInputBorder())))]),
          const SizedBox(height:12),
          TextField(controller: descC, maxLines:2, decoration: const InputDecoration(labelText:'Deskripsi', border: OutlineInputBorder())),
          const SizedBox(height:20),
          SizedBox(width: double.infinity, height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
            if(nameC.text.trim().isEmpty) return;
            final db = ref.read(localDatabaseProvider);
            await db.productDao.createProductQuick(name: nameC.text.trim(), code: codeC.text.trim(), brand: brandC.text.trim(), rackLocation: rakC.text.trim(), categoryId: kategori);
            final prod = await db.productDao.getByCode(codeC.text.trim());
            if(prod!=null){ await (db.update(db.products)..where((t)=> t.id.equals(prod.id))).write(ProductsCompanion(barcode: Value(barcodeC.text.trim()), description: Value(descC.text.trim()), unit: Value(unit), updatedAt: Value(DateTime.now()))); }
            if(mounted) Navigator.pop(context);
          }, child: const Text('SIMPAN MASTER', style: TextStyle(color:Colors.white)))),
        ])))));
  }

  @override Widget build(BuildContext context){
    final products = ref.watch(allProductsStreamProvider);
    return Scaffold(backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Master Barang - Tier'),
        backgroundColor: const Color(0xFF00A65A),
        actions: [
          // MERAH: GANTI JADI ICON KARTU STOK
          IconButton(icon: const Icon(Icons.history), tooltip: 'Kartu Stok', onPressed: _openKartuStokPicker),
          IconButton(icon: const Icon(Icons.receipt_long), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'Cari SKU / Nama / Rak / Brand', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        Expanded(child: products.when(data: (list){
          var f = list.where((p)=> q.isEmpty || p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q)).toList();
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
            final p=f[i];
            return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(
              // Klik card langsung ke Kartu Stok
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
                subtitle: Text('SKU:${p.code} | Stok:${p.stock} | HPP:${formatRupiah(p.buyPrice)}', style: const TextStyle(fontSize:10)),
                // BIRU: GANTI JADI EDIT MASTER
                trailing: IconButton(icon: const Icon(Icons.edit, size:20, color: Colors.black87), tooltip: 'Edit Master', onPressed: ()=> _openEditMaster(p)),
              ),
            ));
          });
        }, loading: ()=> const Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('Error: $e')))),
      ]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: const Color(0xFF00A65A), onPressed: _openMasterAdd, label: const Text('Tambah Barang', style: TextStyle(color:Colors.white)), icon: const Icon(Icons.add_box, color:Colors.white)),
    );
  }
}