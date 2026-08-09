import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';
import 'persediaan_stock_barang.dart';

class PerakitanPage extends ConsumerStatefulWidget {
  const PerakitanPage({super.key});
  @override ConsumerState<PerakitanPage> createState()=> _RakitState();
}

class _RakitState extends ConsumerState<PerakitanPage> {
  String? jadiId; String? jadiName;
  final jadiQtyC=TextEditingController(text:'1');
  List<Map<String,dynamic>> bahan=[];

  @override void dispose(){ jadiQtyC.dispose(); super.dispose(); }

  Future<ProductData?> _getProduct(String id) async {
    return await ref.read(localDatabaseProvider).productDao.getProductById(id);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perakitan - HPP Otomatis')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ElevatedButton(onPressed: () async {
          final id=await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode:true)));
          if(id!=null){ final p=await _getProduct(id); setState((){ jadiId=id; jadiName=p?.name; }); }
        }, child: Text(jadiName==null?'Pilih Barang Jadi': 'Jadi: $jadiName')),
        const SizedBox(height:12),
        TextField(controller: jadiQtyC, decoration: const InputDecoration(labelText:'Qty Jadi', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const Divider(height:30),
        Row(children: [
          const Text('Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () async {
            final id=await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode:true)));
            if(id!=null){
              final p=await _getProduct(id);
              final qtyC=TextEditingController(text:'1');
              final ok=await showDialog<bool>(context: context, builder: (_)=> AlertDialog(
                title: Text('Qty Bahan ${p?.name}'),
                content: TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Qty per 1 jadi', border: OutlineInputBorder())),
                actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Tambah'))]
              ));
              if(ok==true) setState(()=> bahan.add({'productId':id, 'name':p?.name, 'qty':double.tryParse(qtyC.text)??1}));
            }
          })
        ]),
       ...bahan.map((b)=> Card(child: ListTile(title: Text(b['name']), subtitle: Text('Qty: ${b['qty']} per jadi'), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=> setState(()=> bahan.remove(b)))))),
        const SizedBox(height:20),
        SizedBox(height:50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), onPressed: () async {
          if(jadiId==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih barang jadi dulu'))); return; }
          if(bahan.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bahan masih kosong'))); return; }
          final qtyJadi = double.tryParse(jadiQtyC.text)??0;
          if(qtyJadi<=0){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Qty jadi harus >0'))); return; }
          try {
            await ref.read(localDatabaseProvider).stockMutationDao.eksekusiPerakitanProduk(
              finishedProductId: jadiId!, finishedQtyToProduce: qtyJadi,
              materials: bahan.map((e)=> AssemblyMaterialItem(rawProductId: e['productId'], quantityRequiredPerUnit: (e['qty'] as double))).toList(),
              userId: 'owner-01', notes: 'Rakit ${bahan.length} bahan'
            );
            if(mounted){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rakit OK - HPP jadi = total HPP bahan'))); Navigator.pop(context); }
          } catch (e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
          }
        }, child: const Text('RAKIT SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ])
    );
  }
}