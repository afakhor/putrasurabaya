import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'persediaan_stock_barang.dart';

class ItemMasukPage extends ConsumerStatefulWidget {
  const ItemMasukPage({super.key});
  @override ConsumerState<ItemMasukPage> createState()=> _MasukState();
}

class _MasukState extends ConsumerState<ItemMasukPage> {
  String? pid; String? pname;
  final qtyC=TextEditingController(text:'1');
  final hargaC=TextEditingController();
  final rakC=TextEditingController();
  final notesC=TextEditingController(text:'Pembelian');

  @override void dispose(){
    qtyC.dispose(); hargaC.dispose(); rakC.dispose(); notesC.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Masuk + HPP MA')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ElevatedButton(onPressed: () async {
          final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode:true)));
          if(id!=null){
            final prod = await ref.read(localDatabaseProvider).productDao.getProductById(id);
            setState((){
              pid=id;
              pname=prod?.name;
              rakC.text=prod?.rackLocation??'';
              hargaC.text = (prod?.buyPrice ?? 0).toStringAsFixed(0); // FIX DISINI
            });
          }
        }, child: Text(pname??'Pilih Barang')),
        const SizedBox(height:12),
        TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Qty Masuk (+)', border: OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller: hargaC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Harga Beli / HPP Masuk (untuk MA)', border: OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller: rakC, decoration: const InputDecoration(labelText:'Rak Baru (opsional)', border: OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller: notesC, decoration: const InputDecoration(labelText:'Catatan: Pembelian/Hadiah/Retur', border: OutlineInputBorder())),
        const SizedBox(height:20),
        SizedBox(height:48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async {
          if(pid==null) return;
          try{
            await ref.read(localDatabaseProvider).stockMutationDao.catatItemMasuk(productId: pid!, qty: double.parse(qtyC.text), hargaBeli: double.tryParse(hargaC.text), refNo: 'IN-${DateTime.now().millisecondsSinceEpoch}', userId: 'owner-01', notes: notesC.text, newRack: rakC.text.isEmpty?null:rakC.text);
            if(mounted){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masuk OK - HPP MA Jalan')));
              Navigator.pop(context);
            }
          }catch(e){
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }, child: const Text('SIMPAN MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ])
    );
  }
}