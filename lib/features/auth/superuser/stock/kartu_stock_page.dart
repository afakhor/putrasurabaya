import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/utils/config.dart';

class KartuStokPage extends ConsumerWidget {
  final String productId;
  const KartuStokPage({super.key, required this.productId});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final kartu = ref.watch(kartuStokStreamProvider(productId));
    final prodStream = ref.watch(productDaoProvider).watchProductById(productId);
    return Scaffold(appBar: AppBar(title: Text('Kartu Stok'), actions: [IconButton(icon: Icon(Icons.build_circle), tooltip: 'Perbaikan Saldo', onPressed: () async {
      final ok = await showDialog<bool>(context: context, builder: (_)=> AlertDialog(title: Text('Perbaikan Saldo'), content: Text('Hitung ulang dari awal by date? Ini akan rewrite stockAfter.'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: Text('Perbaiki'))]));
      if(ok==true){ await ref.read(stockMutationDaoProvider).prosesPerbaikanSaldo(productId); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saldo diperbaiki'))); }
    })]),
      body: Column(children: [
        prodStream.when(data: (p)=> p==null? SizedBox(): GlassCard(margin: EdgeInsets.all(12), child: ListTile(title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Stok: ${p.stock} | HPP: ${p.buyPrice} | Rak: ${p.rackLocation}'))), loading: ()=> SizedBox(), error: (_,__)=> SizedBox()),
        Container(color: Colors.grey[100], padding: EdgeInsets.all(8), child: Row(children: [
          Expanded(child: Row(children: [Container(width:10,height:10,color:Colors.white), SizedBox(width:4), Text('Normal', style: TextStyle(fontSize:9))])),
          Expanded(child: Row(children: [Container(width:10,height:10,color:Colors.amber[50]), SizedBox(width:4), Text('1-2', style: TextStyle(fontSize:9))])),
          Expanded(child: Row(children: [Container(width:10,height:10,color:Colors.red[50]), SizedBox(width:4), Text('>=3', style: TextStyle(fontSize:9))])),
          Expanded(child: Row(children: [Container(width:10,height:10,color:Colors.red[100]), SizedBox(width:4), Text('Minus', style: TextStyle(fontSize:9))])),
        ])),
        Container(color: Colors.black87, padding: EdgeInsets.symmetric(horizontal:12,vertical:8), child: Row(children: [Expanded(flex:3, child: Text('TGL | TIPE', style: TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.bold))), Expanded(child: Text('AWAL', style: TextStyle(color: Colors.white, fontSize:10))), Expanded(child: Text('MUTASI', style: TextStyle(color: Colors.white, fontSize:10))), Expanded(child: Text('AKHIR', style: TextStyle(color: Colors.white, fontSize:10))), Expanded(child: Text('HPP', style: TextStyle(color: Colors.white, fontSize:10)))])),
        Expanded(child: kartu.when(data: (list){
          final warningCount = list.where((e)=> e.mutation.type=='OPNAME' && e.mutation.quantity.abs()>=3).length;
          return Column(children: [
            if(warningCount>0) Container(width: double.infinity, color: Colors.red, padding: EdgeInsets.all(8), child: Text('$warningCount WARNING selisih besar >=3 pcs - Cek Fraud Page', style: TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (c,i){
              final d=list[i]; final m=d.mutation;
              Color bg=Colors.white; if(m.stockAfter<0) bg=Colors.red[100]!; else if(m.type=='OPNAME' && m.quantity.abs()>=3) bg=Colors.red[50]!; else if(m.type=='OPNAME' && m.quantity.abs()>=1) bg=Colors.amber[50]!;
              return Container(color: bg, padding: EdgeInsets.symmetric(horizontal:12,vertical:6), child: Row(children: [
                Expanded(flex:3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.date.toString().substring(0,16), style: TextStyle(fontSize:10, fontWeight: FontWeight.bold)), Text(m.type, style: TextStyle(fontSize:9)), Text(m.referenceNo, style: TextStyle(fontSize:8, color: Colors.grey))])),
                Expanded(child: Text('${m.stockBefore.toStringAsFixed(0)}', style: TextStyle(fontSize:10))),
                Expanded(child: Text('${m.quantity>0?'+':''}${m.quantity.toStringAsFixed(0)}', style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: m.quantity>0? Colors.green : Colors.red))),
                Expanded(child: Text('${m.stockAfter.toStringAsFixed(0)}', style: TextStyle(fontSize:10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('${m.hppSnapshot.toStringAsFixed(0)}', style: TextStyle(fontSize:10))),
              ]));
            })),
          ]);
        }, loading: ()=> Center(child: CircularProgressIndicator()), error: (e,s)=> Center(child: Text('$e')))),
      ]),
    );
  }
}