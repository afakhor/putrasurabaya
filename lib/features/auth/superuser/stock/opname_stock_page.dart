import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'persediaan_stock_barang.dart';

class OpnameStockPage extends ConsumerStatefulWidget { const OpnameStockPage({super.key}); @override ConsumerState<OpnameStockPage> createState()=> _OpnameState(); }

class _OpnameState extends ConsumerState<OpnameStockPage> {
  String? pid; String? pname; double stokProgram=0;
  final fisikC=TextEditingController();
  DateTime tgl=DateTime.now();
  final rakC=TextEditingController();
  final notesC=TextEditingController();

  @override void dispose(){
    fisikC.dispose(); rakC.dispose(); notesC.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final selisih = (double.tryParse(fisikC.text)??0) - stokProgram;
    return Scaffold(
      appBar: AppBar(title: const Text('Opname - Tgl Mundur')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ElevatedButton(onPressed: () async {
          final id = await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PersediaanStockBarangPage(isPickMode:true)));
          if(id!=null){
            final prod = await ref.read(localDatabaseProvider).productDao.getProductById(id);
            if(mounted) setState((){ pid=id; pname=prod?.name; stokProgram=(prod?.stock??0).toDouble(); rakC.text=prod?.rackLocation??''; });
          }
        }, child: Text(pname??'Pilih Barang')),
        if(pid!=null) Card(child: ListTile(title: Text('Stok Program: $stokProgram'), subtitle: Text('Selisih: $selisih'), trailing: selisih.abs()>=3? Chip(label: const Text('MERAH >=3', style: TextStyle(color: Colors.white, fontSize:10)), backgroundColor: Colors.red) : selisih.abs()>=1? Chip(label: const Text('KUNING 1-2', style: TextStyle(fontSize:10)), backgroundColor: Colors.amber) : null)),
        TextField(controller: fisikC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Stok Fisik Hitung'), onChanged: (_)=> setState((){})),
        ListTile(title: Text('Tanggal: ${tgl.toString().substring(0,16)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
          final d=await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDate: tgl);
          if(d!=null){
            final t=await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(tgl));
            if(mounted) setState(()=> tgl=DateTime(d.year,d.month,d.day,t?.hour??DateTime.now().hour,t?.minute??DateTime.now().minute));
          }
        }),
        TextField(controller: rakC, decoration: const InputDecoration(labelText:'Rak Baru')),
        TextField(controller: notesC, decoration: const InputDecoration(labelText:'Keterangan Opname')),
        const SizedBox(height:20),
        ElevatedButton(onPressed: () async {
          if(pid==null) return;
          if(fisikC.text.isEmpty) return;
          await ref.read(localDatabaseProvider).stockMutationDao.catatOpname(productId: pid!, stokFisik: double.parse(fisikC.text), refNo: 'OPN-${tgl.millisecondsSinceEpoch}', userId: 'owner-01', notes: notesC.text, date: tgl, newRack: rakC.text.isEmpty?null:rakC.text);
          if(mounted) Navigator.pop(context);
        }, child: const Text('Simpan Opname')),
      ])
    );
  }
}