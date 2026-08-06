import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'persediaan_stock_barang.dart';

class ItemMasukPage extends ConsumerStatefulWidget { const ItemMasukPage({super.key}); @override ConsumerState<ItemMasukPage> createState()=> _MasukState(); }
class _MasukState extends ConsumerState<ItemMasukPage> {
  String? pid; String? pname; final qtyC=TextEditingController(text:'1'); final hargaC=TextEditingController(); final rakC=TextEditingController(); final notesC=TextEditingController(text:'Pembelian');
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Item Masuk + HPP MA')), body: ListView(padding: EdgeInsets.all(16), children: [
      ElevatedButton(onPressed: () async { final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> PersediaanStockBarangPage(isPickMode:true))); if(id!=null){ final prod = await ref.read(productDaoProvider).getProductById(id); setState((){ pid=id; pname=prod?.name; rakC.text=prod?.rackLocation??''; hargaC.text=prod?.buyPrice.toStringAsFixed(0)??''; }); } }, child: Text(pname??'Pilih Barang')),
      SizedBox(height:12), TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText:'Qty Masuk (+)', border: OutlineInputBorder())),
      SizedBox(height:12), TextField(controller: hargaC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText:'Harga Beli / HPP Masuk (untuk MA)', border: OutlineInputBorder())),
      SizedBox(height:12), TextField(controller: rakC, decoration: InputDecoration(labelText:'Rak Baru (opsional)', border: OutlineInputBorder())),
      SizedBox(height:12), TextField(controller: notesC, decoration: InputDecoration(labelText:'Catatan: Pembelian/Hadiah/Retur', border: OutlineInputBorder())),
      SizedBox(height:20), SizedBox(height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A65A)), onPressed: () async {
        if(pid==null) return;
        try{ await ref.read(stockMutationDaoProvider).catatItemMasuk(productId: pid!, qty: double.parse(qtyC.text), hargaBeli: double.tryParse(hargaC.text), refNo: 'IN-${DateTime.now().millisecondsSinceEpoch}', userId: 'owner-01', notes: notesC.text, newRack: rakC.text.isEmpty?null:rakC.text); if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masuk OK - HPP MA Jalan'))); Navigator.pop(context);} }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
      }, child: Text('SIMPAN MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
    ]));
  }
}