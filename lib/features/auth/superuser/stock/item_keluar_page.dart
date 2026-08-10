import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'persediaan_stock_barang.dart';

class ItemKeluarPage extends ConsumerStatefulWidget { const ItemKeluarPage({super.key}); @override ConsumerState<ItemKeluarPage> createState()=> _KeluarState(); }

class _KeluarState extends ConsumerState<ItemKeluarPage> {
  String? pid; String? pname;
  final qtyC=TextEditingController(text:'1');
  final notesC=TextEditingController(text:'Rusak');

  @override void dispose(){
    qtyC.dispose(); notesC.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Keluar - Anti Minus')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ElevatedButton(onPressed: () async {
          final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode:true)));
          if(id!=null){
            final prod = await ref.read(localDatabaseProvider).productDao.getProductById(id);
            if(mounted) setState((){ pid=id; pname=prod?.name; });
          }
        }, child: Text(pname??'Pilih Barang')),
        const SizedBox(height:12),
        TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Qty Keluar (-)', border: OutlineInputBorder())),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value: notesC.text, decoration: const InputDecoration(labelText:'Alasan', border: OutlineInputBorder()), items: ['Rusak','Hilang','Sample','Kadaluarsa','Pakai Internal'].map((e)=> DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=> notesC.text=v??''),
        const SizedBox(height:20),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () async {
          if(pid==null) return;
          try{
            await ref.read(localDatabaseProvider).stockMutationDao.catatItemKeluar(productId: pid!, qty: double.parse(qtyC.text), refNo: 'OUT-${DateTime.now().millisecondsSinceEpoch}', userId: 'owner-01', notes: notesC.text);
            if(mounted){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keluar OK')));
              Navigator.pop(context);
            }
          }catch(e){
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
          }
        }, child: const Text('SIMPAN KELUAR', style: TextStyle(color: Colors.white))),
      ])
    );
  }
}