import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

class ShortcutPage extends ConsumerWidget {
  const ShortcutPage({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(localDatabaseProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('SHORTCUT BOS - REALTIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(10), children: [
        _header('SHORTCUT 1', 'INPUT INVOICE', Colors.indigo, Icons.receipt_long_rounded),
        _cardAB(context, color: Colors.indigo,
          aTitle: 'Opsi Input Invoice Pembelian', aDesc: 'Banyak item + harga kulak + stock realtime + supplier', aIcon: Icons.shopping_cart_rounded, onATap: () => _go(context, '/purchase'),
          bTitle: 'Opsi Input Invoice Penjualan', bDesc: 'Banyak item + harga jual tier 1,2,3 + stock realtime + customer', bIcon: Icons.point_of_sale_rounded, onBTap: () => _go(context, '/pos'),
          dataWidget: StreamBuilder<List<ProductData>>(stream: db.productDao.watchActiveProducts(), builder: (_, s){ final prods=s.data??[]; final low=prods.where((e)=> e.stock<=e.minStock).length; return Row(children: [Expanded(child: _miniStat('${prods.length} SKU', 'Ready', Colors.green)), Expanded(child: _miniStat('$low SKU', 'Nipis', Colors.red))]); }),
        ),
        _header('SHORTCUT 2', 'INPUT PEMBAYARAN', Colors.green, Icons.payments_rounded),
        _cardAB(context, color: Colors.green,
          aTitle: 'Opsi Input Pembayaran Hutang', aDesc: 'Tunai / TF / BG / Titipan sampai lunas + log', aIcon: Icons.request_quote_rounded, onATap: () => _go(context, '/payables'),
          bTitle: 'Opsi Input Pembayaran Piutang', bDesc: 'Tunai / TF / BG / Titipan sampai lunas + log', bIcon: Icons.payments_rounded, onBTap: () => _go(context, '/receivables'),
          dataWidget: Row(children: [
            Expanded(child: StreamBuilder<List<PayableData>>(stream: db.payablesDao.watchActivePayables(), builder: (_, s){ final data=s.data??[]; return _miniStat(fmt.format(data.fold<double>(0,(p,e)=>p+e.remainingAmount)), 'Hutang ${data.length}', Colors.red); })),
            const SizedBox(width: 6),
            Expanded(child: StreamBuilder<List<ReceivableData>>(stream: (db.select(db.receivables)..where((t)=> t.remainingAmount.isBiggerThanValue(0))).watch(), builder: (_, s){ final data=s.data??[]; return _miniStat(fmt.format(data.fold<double>(0,(p,e)=>p+e.remainingAmount)), 'Piutang ${data.length}', Colors.orange); })),
          ]),
        ),
        _header('SHORTCUT 3', 'MASTER PICKER', Colors.orange, Icons.touch_app_rounded),
        _cardAB(context, color: Colors.orange,
          aTitle: 'A - Pilih Customer / Supplier', aDesc: 'Cari + sisa hutang/piutang + umur', aIcon: Icons.people_alt_rounded, onATap: () => _go(context, '/master-data'),
          bTitle: 'B - Pilih Item / Invoice', bDesc: 'Cari SKU + stock + harga + history', bIcon: Icons.inventory_2_rounded, onBTap: () => _go(context, '/master-data'),
          dataWidget: Row(children: [
            Expanded(child: StreamBuilder<List<CustomerData>>(stream: db.customerDao.watchAllCustomers(), builder: (_, s)=> _miniStat('${s.data?.length??0} Cust', 'Customer', Colors.indigo))),
            const SizedBox(width: 6),
            Expanded(child: StreamBuilder<List<SupplierData>>(stream: db.supplierDao.watchAllSuppliers(), builder: (_, s)=> _miniStat('${s.data?.length??0} Supp', 'Supplier', Colors.teal))),
          ]),
        ),
        _header('SHORTCUT 4', 'MUTASI STOCK REALTIME', Colors.blue, Icons.swap_horiz_rounded),
        _cardAB(context, color: Colors.blue,
          aTitle: 'A - Stock Masuk / Opname', aDesc: 'Pembelian + retur + opname', aIcon: Icons.arrow_downward_rounded, onATap: () => _go(context, '/stock-in'),
          bTitle: 'B - Stock Keluar / Jual', bDesc: 'Penjualan + rusak + kartu stock', bIcon: Icons.arrow_upward_rounded, onBTap: () => _go(context, '/stock-out'),
          dataWidget: FutureBuilder<List<StockMutationData>>(future: (db.select(db.stockMutations)..orderBy([(t)=> OrderingTerm(expression: t.date, mode: OrderingMode.desc)])..limit(3)).get(), builder: (_, s){ final mut=s.data??[]; if(mut.isEmpty) return const Text('Belum ada mutasi', style: TextStyle(fontSize: 9)); return Column(children: mut.map((m)=> Row(children: [Icon(m.quantity>0?Icons.arrow_downward:Icons.arrow_upward, size: 10, color: m.quantity>0?Colors.green:Colors.red), const SizedBox(width: 4), Expanded(child: Text('${m.productId} ${m.type} ${m.quantity}', style: const TextStyle(fontSize: 9)))] )).toList()); }),
        ),
        _header('SHORTCUT 5', 'HARGA & LABA REALTIME', Colors.purple, Icons.trending_up_rounded),
        _cardAB(context, color: Colors.purple,
          aTitle: 'A - Pricing Tier 1,2,3', aDesc: 'HPP vs Jual umum vs tier + margin', aIcon: Icons.price_change_rounded, onATap: () => _go(context, '/pricing'),
          bTitle: 'B - Laba Rugi + Modal', bDesc: 'Omset, HPP, biaya, laba, modal akhir', bIcon: Icons.account_balance_wallet_rounded, onBTap: () => _go(context, '/closing-book'),
          dataWidget: FutureBuilder<Map<String,dynamic>>(future: db.reportDao.getRealTimeReport(), builder: (_, s){ final d=s.data; if(d==null) return const Text('Loading...', style: TextStyle(fontSize: 9)); return Row(children: [Expanded(child: _miniStat(fmt.format(d['omset']), 'Omset', Colors.green)), Expanded(child: _miniStat(fmt.format(d['labaBersih']), 'Laba', (d['labaBersih'] as double)>=0?Colors.green:Colors.red))]); }),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  void _go(BuildContext context, String route){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shortcut $route - Hubungkan ke page Bos'), duration: const Duration(seconds: 1)));
  }

  Widget _header(String no, String title, Color c, IconData icon) => Container(margin: const EdgeInsets.only(top: 14, bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: c, size: 18)), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(no, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))])]));
  Widget _cardAB(BuildContext context, {required Color color, required String aTitle, required String aDesc, required IconData aIcon, required VoidCallback onATap, required String bTitle, required String bDesc, required IconData bIcon, required VoidCallback onBTap, required Widget dataWidget}) {
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(children: [
      InkWell(onTap: onATap, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(aIcon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(aTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(aDesc, style: const TextStyle(fontSize: 10, color: Colors.grey)), Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: const Text('BANYAK ITEM + HARGA + STOCK REALTIME', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))]))]))),
      Divider(height: 1, color: color.withOpacity(0.2)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [Expanded(child: Divider(color: color.withOpacity(0.3))), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('===', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))), Expanded(child: Divider(color: color.withOpacity(0.3)))])),
      InkWell(onTap: onBTap, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(bIcon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(bTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(bDesc, style: const TextStyle(fontSize: 10, color: Colors.grey))]))]))),
      Divider(height: 1, color: color.withOpacity(0.2)),
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.bolt, size: 12, color: color), const SizedBox(width: 4), Text('DATA A/B REAL TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 6), dataWidget])),
    ]));
  }
  Widget _miniStat(String v, String l, Color c) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c), maxLines: 1, overflow: TextOverflow.ellipsis), Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey))]));
}