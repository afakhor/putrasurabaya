import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../../../../core/database/tables/category_table.dart';
import 'product_form_provider.dart';

class MasterFabPerkakas extends ConsumerStatefulWidget {
  final Function(BuildContext, {ProductData? product})? onOpenForm;
  const MasterFabPerkakas({super.key, this.onOpenForm});
  @override ConsumerState<MasterFabPerkakas> createState()=> _MasterFabPerkakasState();
}

class _MasterFabPerkakasState extends ConsumerState<MasterFabPerkakas> with TickerProviderStateMixin {
  late AnimationController _mainC, _subC;
  late Animation<double> _mainA, _subA;
  int? _selected;
  @override void initState(){ super.initState(); _mainC=AnimationController(duration: const Duration(milliseconds:280), vsync:this); _subC=AnimationController(duration: const Duration(milliseconds:220), vsync:this); _mainA=CurvedAnimation(parent:_mainC, curve:Curves.easeOutBack); _subA=CurvedAnimation(parent:_subC, curve:Curves.easeOutBack); }
  @override void dispose(){ _mainC.dispose(); _subC.dispose(); super.dispose(); }
  void _close(){ _subC.reverse(); _mainC.reverse(); setState(()=> _selected=null); }
  void _toggle(){ if(_mainC.isCompleted|| _mainC.isAnimating){ _close(); } else { _mainC.forward(); } }

  @override Widget build(BuildContext context){
    return SizedBox(width:320, height:420, child: Stack(alignment: Alignment.bottomRight, children: [
      if(_selected==1)..._buildEmergency(),
     ..._buildMain(),
      FloatingActionButton(heroTag:'master_fab', backgroundColor:_mainC.isCompleted? Colors.black87 : const Color(0xFF007F00), onPressed:_toggle, child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _mainA)),
    ]));
  }

  List<Widget> _buildMain(){
    final opts = [
      {'t':'Form Master','ic':Icons.add_box_rounded,'c':const Color(0xFF00A65A)},
      {'t':'Emergency','ic':Icons.warning_amber_rounded,'c':Colors.red.shade800},
      {'t':'Quick 10','ic':Icons.grid_view_rounded,'c':Colors.amber.shade900},
    ];
    const r=115.0;
    return List.generate(3, (i){
      final ang=(pi/2)*(i/2);
      return AnimatedBuilder(animation:_mainA, builder: (_, __){
        final p=_mainA.value; final dx=-r*p*cos(ang); final dy=-r*p*sin(ang);
        final sel=_selected==i; final other=_selected!=null && sel==false;
        return Transform.translate(offset: Offset(dx,dy), child: Opacity(opacity: other?0.35:p.clamp(0.0,1.0), child: FloatingActionButton.small(heroTag:'main_$i', backgroundColor: sel? Colors.blueGrey.shade900 : opts[i]['c'] as Color, onPressed: (){
          if(i==0){ _close(); ref.invalidate(productFormProvider); if(widget.onOpenForm!=null) widget.onOpenForm!(context); }
          else if(i==2){ _close(); _showQuickGrid(); }
          else { if(_selected==i){ _subC.reverse(); setState(()=> _selected=null); } else { setState(()=> _selected=i); _subC.forward(from:0); } }
        }, child: Icon(opts[i]['ic'] as IconData, color:Colors.white))));
      });
    });
  }

  List<Widget> _buildEmergency(){
    final items = [
      {'l':'Koreksi Stok','ic':Icons.gavel_rounded,'c':Colors.red.shade700,'fn': _koreksiStok},
      {'l':'Ubah Harga','ic':Icons.monetization_on_rounded,'c':Colors.amber.shade900,'fn': _ubahHarga},
      {'l':'Mutasi Log','ic':Icons.history,'c':Colors.purple.shade700,'fn': _lihatMutasi},
    ];
    const pr=115.0; const sr=75.0; final pa=pi/4; final pdx=-pr*cos(pa); final pdy=-pr*sin(pa);
    return List.generate(items.length, (j){
      const spread=pi/3; final start=pa-spread/2; final step=spread/(items.length-1); final cur=start+j*step;
      return AnimatedBuilder(animation:_subA, builder: (_, __){
        final p=_subA.value; final dx=pdx-sr*p*cos(cur); final dy=pdy-sr*p*sin(cur);
        return Transform.translate(offset: Offset(dx,dy), child: Opacity(opacity:p.clamp(0.0,1.0), child: Transform.scale(scale:p, child: FloatingActionButton.small(heroTag:'em_$j', backgroundColor: items[j]['c'] as Color, onPressed: (){ _close(); (items[j]['fn'] as Function())(); }, child: Icon(items[j]['ic'] as IconData, color:Colors.white, size:18)))));
      });
    });
  }

  void _showQuickGrid(){
    final db=ref.read(localDatabaseProvider);
    final shortcuts = [
      {'title':'Kategori','icon':Icons.category,'color':Colors.blue,'act': _addKategori},
      {'title':'Sub-Kategori','icon':Icons.layers,'color':Colors.deepOrange,'act': _addSubKategori},
      {'title':'Supplier','icon':Icons.local_shipping,'color':Colors.green.shade800,'act': ()=> _addSupplier(db)},
      {'title':'Customer','icon':Icons.people,'color':Colors.teal,'act': ()=> _addCustomer(db)},
      {'title':'Satuan','icon':Icons.straighten,'color':Colors.cyan.shade700,'act': _addUnit},
      {'title':'Brand','icon':Icons.branding_watermark,'color':Colors.indigo,'act': _addBrand},
      {'title':'Scan','icon':Icons.qr_code_scanner,'color':Colors.purple,'act': ()=> _dummy('Scanner')},
      {'title':'Label','icon':Icons.print,'color':Colors.brown,'act': ()=> _dummy('Cetak Label')},
      {'title':'Import','icon':Icons.upload_file,'color':const Color(0xFF10B981),'act': ()=> _dummy('Import')},
      {'title':'Export','icon':Icons.picture_as_pdf,'color':Colors.red,'act': ()=> _dummy('Export')},
    ];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx)=> Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: GridView.builder(shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), itemCount: shortcuts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4, childAspectRatio:0.8), itemBuilder: (c,i){
      final it=shortcuts[i];
      return InkWell(onTap: (){ Navigator.pop(ctx); (it['act'] as Function())(); }, child: Column(children: [CircleAvatar(backgroundColor: (it['color'] as Color).withOpacity(0.15), child: Icon(it['icon'] as IconData, color: it['color'] as Color)), const SizedBox(height:6), Text(it['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold))]));
    })));
  }

  void _dummy(String s){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  void _addKategori() async { final c=TextEditingController(); final res=await showDialog<String>(context: context, builder: (ctx)=> AlertDialog(title: const Text('Kategori Perkakas Baru'), content: TextField(controller:c, decoration: const InputDecoration(labelText:'Nama Kategori', border: OutlineInputBorder())), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(ctx,c.text), child: const Text('Simpan'))])); if(res!=null && res.isNotEmpty){ final dao=ref.read(localDatabaseProvider).categoryDao; await dao.createCategory(name:res, type:CategoryType.product, iconName:'handyman', colorHex:'#FF9800', sortOrder: DateTime.now().millisecond); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori $res disimpan'))); } }
  void _addSubKategori() async { final dao=ref.read(localDatabaseProvider).categoryDao; final parents=await dao.watchByType(CategoryType.product).first; String? sel; final c=TextEditingController(); if(!mounted) return; showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text('Sub-Kategori'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(hint: const Text('Induk 24 Kategori'), items: parents.map((e)=> DropdownMenuItem(value:e.id, child: Text(e.name, style: const TextStyle(fontSize:12)))).toList(), onChanged:(v)=> sel=v, decoration: const InputDecoration(border: OutlineInputBorder())), const SizedBox(height:10), TextField(controller:c, decoration: const InputDecoration(labelText:'Nama Sub', border: OutlineInputBorder()))]), actions: [ElevatedButton(onPressed: () async { if(c.text.isNotEmpty && sel!=null){ await dao.createCategory(name:c.text, type:CategoryType.product, description:'Sub dari $sel'); if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sub ${c.text} tersimpan'))); } } }, child: const Text('Simpan'))]])); }
  void _addSupplier(LocalDatabase db){ final c=TextEditingController(); showModalBottomSheet(context: context, builder: (ctx)=> Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Supplier Perkakas', style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller:c, decoration: const InputDecoration(labelText:'Nama Supplier')), const SizedBox(height:10), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { await db.into(db.suppliers).insert(SuppliersCompanion.insert(id:'SPL-${DateTime.now().millisecondsSinceEpoch}', name:c.text)); if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier disimpan'))); } }, child: const Text('Simpan')))]))); }
  void _addCustomer(LocalDatabase db){ final c=TextEditingController(); showModalBottomSheet(context: context, builder: (ctx)=> Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Customer Baru', style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller:c, decoration: const InputDecoration(labelText:'Nama Customer')), const SizedBox(height:10), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { final dao=db.customerDao; await dao.createCustomer(name:c.text); if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer disimpan'))); } }, child: const Text('Simpan')))]))); }
  void _addUnit(){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Satuan: Pcs Set Dus'))); }
  void _addBrand(){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand ditambah'))); }
  void _koreksiStok(){ final sku=TextEditingController(); final qty=TextEditingController(); showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text('Koreksi Stok + Mutasi'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller:sku, decoration: const InputDecoration(labelText:'SKU / Barcode')), TextField(controller:qty, decoration: const InputDecoration(labelText:'Qty +/-'))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () async { final db=ref.read(localDatabaseProvider); final prod=await (db.select(db.products)..where((t)=> t.id.equals(sku.text) | t.barcode.equals(sku.text) | t.code.equals(sku.text))).getSingleOrNull(); if(prod!=null){ final delta=double.tryParse(qty.text)??0; final after=prod.stock+delta; await (db.update(db.products)..where((t)=> t.id.equals(prod.id))).write(ProductsCompanion(stock: Value(after))); await db.stockMutationDao.addMutation(productId:prod.id, type:'opname', quantity:delta, stockAfter:after, hpp:prod.buyPrice, notes:'Koreksi FAB'); if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${prod.name} stok $after'))); } } }, child: const Text('Eksekusi', style: TextStyle(color:Colors.white)))]])); }
  void _ubahHarga(){ final sku=TextEditingController(); final price=TextEditingController(); showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text('Ubah Harga Kilat'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller:sku, decoration: const InputDecoration(labelText:'SKU')), TextField(controller:price, decoration: const InputDecoration(labelText:'Harga Baru'))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900), onPressed: () async { final db=ref.read(localDatabaseProvider); final prod=await (db.select(db.products)..where((t)=> t.id.equals(sku.text))).getSingleOrNull(); if(prod!=null){ await (db.update(db.products)..where((t)=> t.id.equals(prod.id))).write(ProductsCompanion(sellPriceGeneral: Value(double.tryParse(price.text)?? prod.sellPriceGeneral))); if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga updated'))); } } }, child: const Text('Update', style: TextStyle(color:Colors.white)))]])); }
  void _lihatMutasi(){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka History Mutasi Stok'))); }
}