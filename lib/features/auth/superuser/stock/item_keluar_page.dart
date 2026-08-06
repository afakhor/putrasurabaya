import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'persediaan_stock_barang.dart';

class ItemKeluarPage extends ConsumerStatefulWidget { const ItemKeluarPage({super.key}); @override ConsumerState<ItemKeluarPage> createState()=> _KeluarState(); }
class _KeluarState extends ConsumerState<ItemKeluarPage> {
  String? pid; String? pname; final qtyC=TextEditingController(text:'1'); final notesC=TextEditingController(text:'Rusak');
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Item Keluar - Anti Minus')), body: ListView(padding: EdgeInsets.all(16), children: [
      ElevatedButton(onPressed: () async { final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> PersediaanStockBarangPage(isPickMode:true))); if(id!=null){ final prod = await ref.read(productDaoProvider).getProductById(id); setState((){ pid=id; pname=prod?.name; }); } }, child: Text(pname??'Pilih Barang')),
      SizedBox(height:12), TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText:'Qty Keluar (-)', border: OutlineInputBorder())),
      SizedBox(height:12), DropdownButtonFormField<String>(value: notesC.text, decoration: InputDecoration(labelText:'Alasan', border: OutlineInputBorder()), items: ['Rusak','Hilang','Sample','Kadaluarsa','Pakai Internal'].map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> notesC.text=v??''),
      SizedBox(height:20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () async {
        try{ await ref.read(stockMutationDaoProvider).catatItemKeluar(productId: pid!, qty: double.parse(qtyC.text), refNo: 'OUT-${DateTime.now().millisecondsSinceEpoch}', userId: 'owner-01', notes: notesC.text); if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Keluar OK'))); Navigator.pop(context);} }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red)); }
      }, child: Text('SIMPAN KELUAR', style: TextStyle(color: Colors.white))),
    ]));
  }
}