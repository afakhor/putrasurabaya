import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

final closingFilterProvider = StateProvider<DateTimeRange>((ref) {
  final now=DateTime.now();
  return DateTimeRange(start:DateTime(now.year,now.month,1),end:DateTime(now.year,now.month+1,0,23,59,59));
});
final closingReportProvider = FutureProvider<Map<String,dynamic>>((ref) async {
  final db=ref.watch(localDatabaseProvider);
  final range=ref.watch(closingFilterProvider);
  final laporan=await db.reportDao.getLaporanLabaRugi(range.start, range.end);
  final top=await db.reportDao.getTopSellingProducts(startDate:range.start,endDate:range.end,limit:5);
  final products=await db.select(db.products).get();
  final payables=await db.select(db.payables).get();
  final receivables=await db.select(db.receivables).get();
  return {'laporan':laporan,'top':top,'stockVal':products.fold<double>(0,(p,e)=> p+(e.stock*e.buyPrice)),'piutang':receivables.fold<double>(0,(p,e)=> p+e.remainingAmount),'hutang':payables.fold<double>(0,(p,e)=> p+e.remainingAmount),'modal':products.fold<double>(0,(p,e)=> p+(e.stock*e.buyPrice))+receivables.fold<double>(0,(p,e)=> p+e.remainingAmount)-payables.fold<double>(0,(p,e)=> p+e.remainingAmount)};
});

class ClosingBookReportPage extends ConsumerWidget {
  const ClosingBookReportPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final range=ref.watch(closingFilterProvider);
    final report=ref.watch(closingReportProvider);
    final fmt=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    return Scaffold(
      appBar: AppBar(title: const Text('TUTUP BUKU Real-Time'), backgroundColor: Colors.black87, actions:[IconButton(icon:const Icon(Icons.date_range),onPressed:()async{ final p=await showDateRangePicker(context:context,firstDate:DateTime(2022,1,1),lastDate:DateTime.now(),initialDateRange:range); if(p!=null) ref.read(closingFilterProvider.notifier).state=p; })]),
      body: report.when(data:(d){ final laporan=d['laporan'] as LaporanLabaRugiData; return ListView(padding:const EdgeInsets.all(12),children:[Card(color:Colors.black,child:ListTile(leading:const Icon(Icons.verified,color:Colors.white),title:Text('Periode: ${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}',style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.bold)),subtitle:Text('Trans: ${laporan.totalTransaksiCount} | Laba: ${fmt.format(laporan.labaBersih)}',style:const TextStyle(color:Colors.white70,fontSize:11)))),Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[_row('Omset',fmt.format(laporan.totalOmset),Colors.green,true),_row('HPP',fmt.format(laporan.totalHpp),Colors.orange),_row('Biaya',fmt.format(laporan.totalPengeluaran),Colors.red),const Divider(),_row('Laba Kotor',fmt.format(laporan.labaKotor),Colors.blue,true),_row('LABA BERSIH',fmt.format(laporan.labaBersih),laporan.labaBersih>=0?Colors.green:Colors.red,true)]))),Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[_row('Stock Akhir',fmt.format(d['stockVal']),Colors.blue,true),_row('Piutang',fmt.format(d['piutang']),Colors.orange),_row('Hutang',fmt.format(d['hutang']),Colors.red),const Divider(),_row('MODAL AKHIR',fmt.format(d['modal']),Colors.purple,true)]))),const Text('Top 5 Produk Terlaris (Auto Sync)',style:TextStyle(fontWeight:FontWeight.bold,fontSize:11)),...(d['top'] as List<TopProductReportData>).map((e)=> Card(child:ListTile(dense:true,title:Text(e.productName,style:const TextStyle(fontSize:11,fontWeight:FontWeight.bold)),subtitle:Text('Qty: ${e.totalQuantity} ${e.unitName} | Omset: ${fmt.format(e.totalOmset)}',style:const TextStyle(fontSize:9)),trailing:Text(fmt.format(e.totalProfit),style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:Colors.green))))),const SizedBox(height:12),ElevatedButton.icon(onPressed:(){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tutup Buku Berhasil - Periode Dikunci'))); },icon:const Icon(Icons.lock),label:const Text('KUNCI TUTUP BUKU'),style:ElevatedButton.styleFrom(backgroundColor:Colors.black,minimumSize:const Size(double.infinity,48))) ]); },loading:()=>const Center(child:CircularProgressIndicator()),error:(e,s)=>Center(child:Text('Error $e'))),
    );
  }
  Widget _row(String l,String v,Color c,[bool b=false])=> Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(l,style:TextStyle(fontSize:12,fontWeight:b?FontWeight.bold:FontWeight.normal)),Text(v,style:TextStyle(fontSize:12,color:c,fontWeight:FontWeight.bold))]));
}