import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../../../../core/database/tables/category_table.dart';
import '../stock/opname_stock_page.dart';
import '../stock/mutasi_stock_page.dart';
import '../stock/kartu_stock_page.dart';
import '../stock/persediaan_stock_barang.dart';
import 'product_form_provider.dart';

class MasterFabPerkakas extends ConsumerStatefulWidget {
  final Function(BuildContext, {ProductData? product})? onOpenForm;
  const MasterFabPerkakas({super.key, this.onOpenForm});
  @override ConsumerState<MasterFabPerkakas> createState() => _MasterFabPerkakasState();
}

class _MasterFabPerkakasState extends ConsumerState<MasterFabPerkakas> with TickerProviderStateMixin {
  late AnimationController mainC;
  late AnimationController subC;
  int? selected;

  @override void initState() {
    super.initState();
    mainC = AnimationController(duration: const Duration(milliseconds: 280), vsync: this);
    subC = AnimationController(duration: const Duration(milliseconds: 220), vsync: this);
  }

  @override void dispose() {
    mainC.dispose();
    subC.dispose();
    super.dispose();
  }

  void closeFab() {
    subC.reverse();
    mainC.reverse();
    setState(() { selected = null; });
  }

  void toggleFab() {
    if (mainC.isCompleted) { closeFab(); } else { mainC.forward(); }
  }

  @override Widget build(BuildContext context) {
    return SizedBox(
      width: 320, height: 420,
      child: Stack(alignment: Alignment.bottomRight, children: [
        if (selected == 1) ...buildEmergency(),
        ...buildMain(),
        FloatingActionButton(
          heroTag: 'master_fab',
          backgroundColor: mainC.isCompleted ? Colors.black87 : const Color(0xFF007F00),
          onPressed: toggleFab,
          child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: mainC),
        ),
      ]),
    );
  }

  List<Widget> buildMain() {
    const r = 115.0;
    return List.generate(3, (i) {
      final ang = (pi / 2) * (i / 2);
      return AnimatedBuilder(
        animation: mainC,
        builder: (_, __) {
          final p = mainC.value;
          final dx = -r * p * cos(ang);
          final dy = -r * p * sin(ang);
          Color col; IconData ic; String tooltip;
          if (i == 0) { col = const Color(0xFF00A65A); ic = Icons.add_box_rounded; tooltip='Tambah Barang'; }
          else if (i == 1) { col = Colors.red.shade800; ic = Icons.warning_amber_rounded; tooltip='Emergency'; }
          else { col = Colors.amber.shade900; ic = Icons.grid_view_rounded; tooltip='Quick Add'; }
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(opacity: p, child: FloatingActionButton.small(
              heroTag: 'main_$i', backgroundColor: col, tooltip: tooltip,
              onPressed: () {
                if (i == 0) {
                  closeFab();
                  ref.read(productFormProvider.notifier).resetForm();
                  if (widget.onOpenForm != null) widget.onOpenForm!(context);
                } else if (i == 2) {
                  closeFab();
                  showQuickGrid();
                } else {
                  if (selected == i) { subC.reverse(); setState(() { selected = null; }); }
                  else { setState(() { selected = i; }); subC.forward(from: 0); }
                }
              },
              child: Icon(ic, color: Colors.white),
            )),
          );
        },
      );
    });
  }

  List<Widget> buildEmergency() {
    const pr = 115.0; const sr = 75.0; final pa = pi / 4; final pdx = -pr * cos(pa); final pdy = -pr * sin(pa);
    return List.generate(3, (j) {
      const spread = pi / 3; final start = pa - spread / 2; final step = spread / 2; final cur = start + j * step;
      Color col; IconData ic; String tooltip;
      if (j == 0) { col = Colors.red.shade700; ic = Icons.gavel_rounded; tooltip='Koreksi Stok (Opname)'; }
      else if (j == 1) { col = Colors.amber.shade900; ic = Icons.monetization_on_rounded; tooltip='Ubah Harga Cepat'; }
      else { col = Colors.purple.shade700; ic = Icons.history; tooltip='Kartu Stok / Mutasi'; }
      return AnimatedBuilder(animation: subC, builder: (_, __) {
        final p = subC.value; final dx = pdx - sr * p * cos(cur); final dy = pdy - sr * p * sin(cur);
        return Transform.translate(offset: Offset(dx, dy), child: Opacity(opacity: p, child: FloatingActionButton.small(
          heroTag: 'em_$j', backgroundColor: col, tooltip: tooltip,
          onPressed: () { closeFab(); if (j == 0) koreksiStok(); if (j == 1) ubahHarga(); if (j == 2) lihatMutasi(); },
          child: Icon(ic, color: Colors.white, size: 18),
        )));
      });
    });
  }

  void showQuickGrid() {
    final db = ref.read(localDatabaseProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: GridView.count(
        crossAxisCount: 4, shrinkWrap: true, mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: [
          quickItem(ctx, 'Kategori', Icons.category, Colors.blue, addKategori),
          quickItem(ctx, 'Supplier', Icons.local_shipping, Colors.green, () => addSupplierFull(db)),
          quickItem(ctx, 'Customer', Icons.people, Colors.teal, () => addCustomerFull(db)),
          quickItem(ctx, 'Opname', Icons.fact_check, Colors.red, koreksiStok),
          quickItem(ctx, 'Mutasi', Icons.receipt_long, Colors.purple, lihatMutasi),
          quickItem(ctx, 'Master Stok', Icons.inventory_2, const Color(0xFF00A65A), () => Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage()))),
          quickItem(ctx, 'Kartu Stok', Icons.history, Colors.brown, () async {
            final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode: true)));
            if(id!=null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: id)));
          }),
        ],
      )),
    );
  }

  Widget quickItem(BuildContext ctx, String title, IconData ic, Color col, Function() act) {
    return InkWell(onTap: () { Navigator.pop(ctx); act(); }, child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(backgroundColor: col.withOpacity(0.15), child: Icon(ic, color: col)), const SizedBox(height: 6), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily:'Poppins'), textAlign: TextAlign.center)]));
  }

  // === KATEGORI ===
  void addKategori() async {
    final c = TextEditingController();
    final res = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Kategori Baru'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Nama kategori')), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Simpan'))]));
    if (res != null && res.isNotEmpty) {
      final dao = ref.read(localDatabaseProvider).categoryDao;
      await dao.createCategory(name: res, type: CategoryType.product, sortOrder: DateTime.now().millisecond);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori $res ditambah')));
    }
  }

  // === SUPPLIER LENGKAP + KATEGORI META ===
  void addSupplierFull(LocalDatabase db) async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final waC = TextEditingController();
    final alamatC = TextEditingController();
    final kotaC = TextEditingController();
    final picC = TextEditingController();
    String kategori = 'Perkakas Tangan';
    String tipe = 'Grosir';
    final List<String> kategoriList = ['Perkakas Tangan','Perkakas Listrik','Pipa & Plumbing','Listrik & Lampu','Cat & Lem','Besi & Baja','Baut & Mur','Grosir Campur'];
    final List<String> tipeList = ['Pabrik','Distributor','Grosir','Agen','Importir','Lokal'];

    final res = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Supplier Baru Lengkap', style: TextStyle(fontSize:14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Supplier *', border: OutlineInputBorder()), autofocus: true),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: phoneC, decoration: const InputDecoration(labelText:'No HP', prefixIcon: Icon(Icons.phone, size:16), border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: waC, decoration: const InputDecoration(labelText:'No WA *', prefixIcon: Icon(Icons.chat, size:16), border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:8),
        TextField(controller: alamatC, maxLines:2, decoration: const InputDecoration(labelText:'Alamat Lengkap', border: OutlineInputBorder())),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: kotaC, decoration: const InputDecoration(labelText:'Kota', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: picC, decoration: const InputDecoration(labelText:'PIC/Sales', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:12),
        DropdownButtonFormField(value: kategori, decoration: const InputDecoration(labelText:'Kategori Barang', border: OutlineInputBorder()), items: kategoriList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> kategori=v!)),
        const SizedBox(height:8),
        DropdownButtonFormField(value: tipe, decoration: const InputDecoration(labelText:'Tipe Supplier', border: OutlineInputBorder()), items: tipeList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> tipe=v!)),
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx,false), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: ()=> Navigator.pop(ctx,true), child: const Text('Simpan', style: TextStyle(color:Colors.white)))],
    )));

    if(res==true && nameC.text.isNotEmpty){
      await db.into(db.suppliers).insertOnConflictUpdate(SuppliersCompanion.insert(
        id: 'SUP-${DateTime.now().millisecondsSinceEpoch}',
        code: Value('SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
        name: nameC.text,
        phone: Value(phoneC.text),
        wa: Value(waC.text),
        address: Value(alamatC.text),
        kota: Value(kotaC.text),
        picName: Value(picC.text),
        category: Value(kategori),
        type: Value(tipe),
      ));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supplier ${nameC.text} ($kategori - $tipe) disimpan')));
    }
  }

  // === CUSTOMER LENGKAP + KELAS & PEMBAYARAN META ===
  void addCustomerFull(LocalDatabase db) async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final waC = TextEditingController();
    final alamatC = TextEditingController();
    final kotaC = TextEditingController();
    String kelas = 'Retail';
    String bayar = 'Tunai';
    String tier = 'Umum';
    final List<String> kelasList = ['Retail','Member','Grosir','Distributor','Project','Toko','Bengkel'];
    final List<String> bayarList = ['Tunai','Transfer','Tempo 7 Hari','Tempo 14 Hari','Tempo 30 Hari','Bon'];
    final List<String> tierList = ['Umum','Tier1 - Member','Tier2 - Grosir','Tier3 - Distributor'];

    final res = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Customer Baru Lengkap', style: TextStyle(fontSize:14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Customer *', border: OutlineInputBorder()), autofocus: true),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: phoneC, decoration: const InputDecoration(labelText:'No HP', prefixIcon: Icon(Icons.phone, size:16), border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: waC, decoration: const InputDecoration(labelText:'No WA *', prefixIcon: Icon(Icons.chat, size:16), border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:8),
        TextField(controller: alamatC, maxLines:2, decoration: const InputDecoration(labelText:'Alamat Lengkap', border: OutlineInputBorder())),
        const SizedBox(height:8),
        TextField(controller: kotaC, decoration: const InputDecoration(labelText:'Kota', border: OutlineInputBorder())),
        const SizedBox(height:12),
        DropdownButtonFormField(value: kelas, decoration: const InputDecoration(labelText:'Kelas Customer', border: OutlineInputBorder()), items: kelasList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> kelas=v!)),
        const SizedBox(height:8),
        DropdownButtonFormField(value: bayar, decoration: const InputDecoration(labelText:'Pembayaran', border: OutlineInputBorder()), items: bayarList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> bayar=v!)),
        const SizedBox(height:8),
        DropdownButtonFormField(value: tier, decoration: const InputDecoration(labelText:'Tier Harga Auto', border: OutlineInputBorder()), items: tierList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> tier=v!)),
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx,false), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), onPressed: ()=> Navigator.pop(ctx,true), child: const Text('Simpan', style: TextStyle(color:Colors.white)))],
    )));

    if(res==true && nameC.text.isNotEmpty){
      await db.into(db.customers).insertOnConflictUpdate(CustomersCompanion.insert(
        id: 'CUS-${DateTime.now().millisecondsSinceEpoch}',
        code: Value('CUS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
        name: nameC.text,
        phone: Value(phoneC.text),
        wa: Value(waC.text),
        address: Value(alamatC.text),
        kota: Value(kotaC.text),
        kelas: Value(kelas),
        paymentType: Value(bayar),
        tierHarga: Value(tier),
      ));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer ${nameC.text} ($kelas - $bayar - $tier) disimpan')));
    }
  }

  void koreksiStok() => Navigator.push(context, MaterialPageRoute(builder: (_)=> const OpnameStockPage()));
  void ubahHarga() async {
    final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode: true)));
    if(id!=null){
      final prod = await ref.read(localDatabaseProvider).productDao.getProductById(id);
      if(prod!=null && mounted){
        ref.read(productFormProvider.notifier).setProduct(prod, [], [], []);
        if(widget.onOpenForm!=null) widget.onOpenForm!(context, product: prod);
      }
    }
  }
  void lihatMutasi() => Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()));
}