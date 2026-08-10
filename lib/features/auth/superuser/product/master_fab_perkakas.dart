import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../stock/opname_stock_page.dart';
import '../stock/mutasi_stock_page.dart';
import '../stock/persediaan_stock_barang.dart';
import 'product_form_provider.dart';

class MasterFabPerkakas extends ConsumerStatefulWidget {
  final Future<void> Function(BuildContext, {ProductData? product})? onOpenForm;
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

  @override void dispose() { mainC.dispose(); subC.dispose(); super.dispose(); }
  void closeFab() { subC.reverse(); mainC.reverse(); setState(()=> selected=null); }
  void toggleFab() { mainC.isCompleted? closeFab() : mainC.forward(); }

  @override Widget build(BuildContext context) {
    return SizedBox(width: 320, height: 420, child: Stack(alignment: Alignment.bottomRight, children: [
      if (selected == 1) ...buildEmergency(),
      ...buildMain(),
      FloatingActionButton(
        heroTag: 'master_fab',
        backgroundColor: mainC.isCompleted? Colors.black87 : const Color(0xFF007F00),
        onPressed: toggleFab,
        child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: mainC),
      ),
    ]));
  }

  List<Widget> buildMain() {
    const r = 115.0;
    return List.generate(3, (i) {
      final ang = (pi / 2) * (i / 2);
      return AnimatedBuilder(animation: mainC, builder: (_, __) {
        final p = mainC.value;
        return Transform.translate(
          offset: Offset(-r * p * cos(ang), -r * p * sin(ang)),
          child: Opacity(opacity: p, child: FloatingActionButton.small(
            heroTag: 'main_$i',
            backgroundColor: i==0? const Color(0xFF00A65A) : i==1? Colors.red.shade800 : Colors.amber.shade900,
            onPressed: (){
              if(i==0){ closeFab(); ref.read(productFormProvider.notifier).resetForm(); if(widget.onOpenForm!=null) widget.onOpenForm!(context); }
              else if(i==2){ closeFab(); showQuickGrid(); }
              else { setState(()=> selected==i? selected=null : selected=i); selected==i? subC.reverse() : subC.forward(from:0); }
            },
            child: Icon(i==0? Icons.add_box_rounded : i==1? Icons.warning_amber_rounded : Icons.grid_view_rounded, color: Colors.white),
          )),
        );
      });
    });
  }

  List<Widget> buildEmergency() {
    const pr = 115.0; const sr = 75.0; final pa = pi/4; final pdx = -pr*cos(pa); final pdy = -pr*sin(pa);
    return List.generate(3, (j){
      const spread = pi/3; final cur = (pa-spread/2) + j*(spread/2);
      return AnimatedBuilder(animation: subC, builder: (_, __){
        final p=subC.value;
        return Transform.translate(offset: Offset(pdx-sr*p*cos(cur), pdy-sr*p*sin(cur)),
          child: Opacity(opacity: p, child: FloatingActionButton.small(
            heroTag: 'em_$j',
            backgroundColor: j==0? Colors.red.shade700 : j==1? Colors.amber.shade900 : Colors.purple.shade700,
            onPressed: (){ closeFab(); if(j==0) koreksiStok(); if(j==1) ubahHarga(); if(j==2) lihatMutasi(); },
            child: Icon(j==0? Icons.gavel_rounded : j==1? Icons.monetization_on_rounded : Icons.history, color: Colors.white, size:18),
          )));
      });
    });
  }

  void showQuickGrid() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=> Padding(padding: const EdgeInsets.all(16), child: GridView.count(
        crossAxisCount: 4, shrinkWrap: true, mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: [
          quickItem(ctx,'Kategori',Icons.category,Colors.blue, addKategori),
          quickItem(ctx,'Supplier',Icons.local_shipping,Colors.green, addSupplierFull),
          quickItem(ctx,'Customer',Icons.people,Colors.teal, addCustomerFull),
          quickItem(ctx,'Opname',Icons.fact_check,Colors.red, koreksiStok),
          quickItem(ctx,'Mutasi',Icons.receipt_long,Colors.purple, lihatMutasi),
          quickItem(ctx,'Master Stok',Icons.inventory_2,const Color(0xFF00A65A), ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage()))),
        ],
      )));
  }

  Widget quickItem(BuildContext ctx, String title, IconData ic, Color col, Function() act) {
    return InkWell(onTap: (){ Navigator.pop(ctx); act(); }, child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(backgroundColor: col.withOpacity(0.15), child: Icon(ic, color: col)), const SizedBox(height:6),
      Text(title, style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold, fontFamily:'Poppins'), textAlign: TextAlign.center)
    ]));
  }

  void addKategori() async {
    final c=TextEditingController();
    final res=await showDialog<String>(context: context, builder: (ctx)=> AlertDialog(
      title: const Text('Kategori Baru'), content: TextField(controller: c, autofocus: true),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(ctx, c.text.trim()), child: const Text('Simpan'))]));
    if(res!=null && res.isNotEmpty){
      await ref.read(localDatabaseProvider).categoryDao.createCategory(name: res, type: 'product', sortOrder: DateTime.now().millisecond);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori $res ditambah')));
    }
  }

  void addSupplierFull() async {
    final nameC=TextEditingController(); final phoneC=TextEditingController(); final waC=TextEditingController();
    final alamatC=TextEditingController(); final kotaC=TextEditingController(); final picC=TextEditingController();
    String kategori='Perkakas Tangan'; String tipe='Grosir';
    final kategoriList=['Perkakas Tangan','Perkakas Listrik','Pipa & Plumbing','Listrik & Lampu','Cat & Lem','Besi & Baja','Baut & Mur','Grosir Campur'];
    final tipeList=['Pabrik','Distributor','Grosir','Agen','Importir','Lokal'];

    final ok=await showDialog<bool>(context: context, builder: (ctx)=> StatefulBuilder(builder: (ctx,setS)=> AlertDialog(
      title: const Text('Supplier Baru', style: TextStyle(fontSize:14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Supplier *', border: OutlineInputBorder())),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: phoneC, decoration: const InputDecoration(labelText:'No HP', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: waC, decoration: const InputDecoration(labelText:'No WA *', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:8),
        TextField(controller: alamatC, maxLines:2, decoration: const InputDecoration(labelText:'Alamat Lengkap', border: OutlineInputBorder())),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: kotaC, decoration: const InputDecoration(labelText:'Kota', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: picC, decoration: const InputDecoration(labelText:'PIC', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:8),
        DropdownButtonFormField(value: kategori, items: kategoriList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> kategori=v!), decoration: const InputDecoration(labelText:'Kategori', border: OutlineInputBorder())),
        const SizedBox(height:8),
        DropdownButtonFormField(value: tipe, items: tipeList.map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> setS(()=> tipe=v!), decoration: const InputDecoration(labelText:'Tipe', border: OutlineInputBorder())),
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx,false), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: ()=> Navigator.pop(ctx,true), child: const Text('Simpan', style: TextStyle(color:Colors.white)))],
    )));
    if(ok==true){
      if(nameC.text.trim().isEmpty || waC.text.trim().isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama & WA wajib'))); return; }
      await ref.read(localDatabaseProvider).supplierDao.createSupplierFull(
        name: nameC.text.trim(), phone: phoneC.text.trim(), wa: waC.text.trim(),
        address: alamatC.text.trim(), kota: kotaC.text.trim(), picName: picC.text.trim(),
        category: kategori, type: tipe,
      );
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supplier ${nameC.text} disimpan')));
    }
  }

  void addCustomerFull() async {
    final nameC=TextEditingController(); final phoneC=TextEditingController(); final waC=TextEditingController();
    final alamatC=TextEditingController(); final kotaC=TextEditingController();
    String kelas='Retail'; String bayar='Tunai'; String tier='Umum';
    final kelasList=['Retail','Member','Grosir','Distributor','Project','Toko','Bengkel'];
    final bayarList=['Tunai','Transfer','Tempo 7 Hari','Tempo 14 Hari','Tempo 30 Hari','Bon'];
    final tierList=['Umum','Tier1 - Member','Tier2 - Grosir','Tier3 - Distributor'];

    final ok=await showDialog<bool>(context: context, builder: (ctx)=> StatefulBuilder(builder: (ctx,setS)=> AlertDialog(
      title: const Text('Customer Baru', style: TextStyle(fontSize:14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText:'Nama Customer *', border: OutlineInputBorder())),
        const SizedBox(height:8),
        Row(children: [
          Expanded(child: TextField(controller: phoneC, decoration: const InputDecoration(labelText:'No HP', border: OutlineInputBorder()))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller: waC, decoration: const InputDecoration(labelText:'No WA *', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height:8),
        TextField(controller: alamatC, maxLines:2, decoration: const InputDecoration(labelText:'Alamat Lengkap', border: OutlineInputBorder())),
        const SizedBox(height:8),
        TextField(controller: kotaC, decoration: const InputDecoration(labelText:'Kota', border: OutlineInputBorder())),
        const SizedBox(height:8),
        DropdownButtonFormField(value: kelas, items: kelasList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> kelas=v!), decoration: const InputDecoration(labelText:'Kelas Customer', border: OutlineInputBorder())),
        const SizedBox(height:8),
        DropdownButtonFormField(value: bayar, items: bayarList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> bayar=v!), decoration: const InputDecoration(labelText:'Pembayaran', border: OutlineInputBorder())),
        const SizedBox(height:8),
        DropdownButtonFormField(value: tier, items: tierList.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:11)))).toList(), onChanged: (v)=> setS(()=> tier=v!), decoration: const InputDecoration(labelText:'Tier Harga Auto', border: OutlineInputBorder())),
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx,false), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), onPressed: ()=> Navigator.pop(ctx,true), child: const Text('Simpan', style: TextStyle(color:Colors.white)))],
    )));
    if(ok==true){
      if(nameC.text.trim().isEmpty || waC.text.trim().isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama & WA wajib'))); return; }
      await ref.read(localDatabaseProvider).customerDao.createCustomerFull(
        name: nameC.text.trim(), phone: phoneC.text.trim(), wa: waC.text.trim(),
        address: alamatC.text.trim(), kota: kotaC.text.trim(),
        kelas: kelas, paymentType: bayar, tierHarga: tier,
      );
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer ${nameC.text} ($kelas - $tier) disimpan')));
    }
  }

  void koreksiStok()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const OpnameStockPage()));
  void ubahHarga() async {
    final id=await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode: true)));
    if(id!=null){ final prod=await ref.read(localDatabaseProvider).productDao.getProductById(id); if(prod!=null && mounted){ ref.read(productFormProvider.notifier).setProduct(prod, [], [], []); if(widget.onOpenForm!=null) widget.onOpenForm!(context, product: prod); } }
  }
  void lihatMutasi()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()));
}