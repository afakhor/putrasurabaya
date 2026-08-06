import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/daos/stock_mutation_dao.dart';
import 'persediaan_stock_barang.dart';

class PerakitanPage extends ConsumerStatefulWidget { const PerakitanPage({super.key}); @override ConsumerState<PerakitanPage> createState()=> _RakitState(); }
class _RakitState extends ConsumerState<PerakitanPage> {
  String? jadiId; String? jadiName; final jadiQtyC=TextEditingController(text:'1');
  List<Map<String,dynamic>> bahan=[]; // {productId, name, qty}
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Perakitan - HPP Otomatis')), body: ListView(padding: EdgeInsets.all(16), children: [
      ElevatedButton(onPressed: () async { final id=await Navigator.push(context, MaterialPageRoute(builder: (_)=> PersediaanStockBarangPage(isPickMode:true))); if(id!=null){ final p=await ref.read(productDaoProvider).getProductById(id); setState((){ jadiId=id; jadiName=p?.name; }); } }, child: Text(jadiName==null?'Pilih Barang Jadi': 'Jadi: $jadiName')),
      TextField(controller: jadiQtyC, decoration: InputDecoration(labelText:'Qty Jadi')),
      Divider(), Row(children: [Text('Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold)), Spacer(), IconButton(icon: Icon(Icons.add), onPressed: () async { final id=await Navigator.push(context, MaterialPageRoute(builder: (_)=> PersediaanStockBarangPage(isPickMode:true))); if(id!=null){ final p=await ref.read(productDaoProvider).getProductById(id); final qtyC=TextEditingController(text:'1'); final ok=await showDialog<bool>(context: context, builder: (_)=> AlertDialog(title: Text('Qty Bahan ${p?.name}'), content: TextField(controller: qtyC, keyboardType: TextInputType.number), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: Text('Tambah'))])); if(ok==true) setState(()=> bahan.add({'productId':id, 'name':p?.name, 'qty':double.parse(qtyC.text)})); } })]),
     ...bahan.map((b)=> ListTile(title: Text(b['name']), subtitle: Text('Qty: ${b['qty']}'), trailing: IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: ()=> setState(()=> bahan.remove(b))))),
      SizedBox(height:20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), onPressed: () async {
        await ref.read(stockMutationDaoProvider).eksekusiPerakitanProduk(finishedProductId: jadiId!, finishedQtyToProduce: double.parse(jadiQtyC.text), materials: bahan.map((e)=> AssemblyMaterialItem(rawProductId: e['productId'], quantityRequiredPerUnit: e['qty'])).toList(), userId: 'owner-01', notes: 'Rakit ${bahan.length} bahan');
        if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rakit OK - HPP jadi = total HPP bahan'))); Navigator.pop(context); }
      }, child: Text('RAKIT SEKARANG', style: TextStyle(color: Colors.white))),
    ]));
  }
}