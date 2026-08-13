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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(padding: const EdgeInsets.all(12), children: [
        // HEADER
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.bolt, color: Colors.amber, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SHORTCUT BOS - REAL TIME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text('Dari barang ready sampai lunas, semua auto sync tanpa admin', style: TextStyle(color: Colors.white70, fontSize: 11))]))])),

        const SizedBox(height: 12),
        // ===== SHORTCUT 1: BARANG READY SAMPAI TERJUAL + PIUTANG =====
        _sectionTitle('1. PENJUALAN & PIUTANG (Ready -> Terjual -> Lunas)', Colors.green),
        _shortcutCard(
          icon: Icons.point_of_sale_rounded, color: Colors.green, title: 'Input Barang Ready Jual Sampai Terjual',
          desc: 'Tier 1,2,3 + Mutasi harga + Stok real-time',
          onTap: () => Navigator.pushNamed(context, '/pos'),
          trailing: StreamBuilder<List<ProductData>>(stream: db.productDao.watchActiveProducts(), builder: (_, s){ final count=s.data?.length??0; return Text('$count SKU Ready', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)); }),
        ),
        _shortcutCard(
          icon: Icons.receipt_long_rounded, color: Colors.orange, title: 'List Invoice Piutang Belum Lunas Sampai Lunas',
          desc: 'Tunai / Transfer / BG / Cek + Mutasi pembayaran',
          onTap: () => Navigator.pushNamed(context, '/receivables'),
          trailing: StreamBuilder<List<ReceivableData>>(stream: db.receivablesDao.watchActiveReceivables().map((list)=> list.map((e)=> e.receivable).toList()), builder: (_, s){ final data=s.data??[]; final total=data.fold<double>(0, (p,e)=> p+e.remainingAmount); return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${data.length} INV', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(fmt.format(total), style: const TextStyle(fontSize: 9, color: Colors.orange))]); }),
        ),
        StreamBuilder<List<dynamic>>(stream: db.receivablesDao.watchOverdueReceivables().map((list)=> list.map((e)=> e.receivable).toList()), builder: (_, s){
          final overdue=s.data??[];
          if(overdue.isEmpty) return const SizedBox();
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)), child: Row(children: [Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20), const SizedBox(width: 8), Expanded(child: Text('${overdue.length} Piutang OVERDUE ${fmt.format(overdue.fold<double>(0,(p,e)=>p+e.remainingAmount))}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700))), TextButton(onPressed: ()=> Navigator.pushNamed(context, '/receivables'), child: const Text('Lihat', style: TextStyle(fontSize: 11)))]));
        }),

        const SizedBox(height: 12),
        // ===== SHORTCUT 2: BARANG MASUK SAMPAI SIAP JUAL + HUTANG =====
        _sectionTitle('2. PEMBELIAN & HUTANG (Masuk -> Ready -> Lunas)', Colors.blue),
        _shortcutCard(
          icon: Icons.inventory_rounded, color: Colors.blue, title: 'Input Barang Masuk Sampai Siap Jual',
          desc: 'Harga beli + Rak + Mutasi masuk + HPP auto',
          onTap: () => Navigator.pushNamed(context, '/purchase'),
          trailing: FutureBuilder<List<StockMutationData>>(future: (db.select(db.stockMutations)..where((t)=> t.type.equals('masuk') | t.type.equals('pembelian'))..orderBy([(t)=> OrderingTerm.desc(t.date)])..limit(1)).get(), builder: (_, s){ final last=s.data?.isNotEmpty==true? s.data!.first : null; return Text(last==null?'Belum ada': '${DateFormat('dd/MM HH:mm').format(last.date)}', style: const TextStyle(fontSize: 9)); }),
        ),
        _shortcutCard(
          icon: Icons.request_quote_rounded, color: Colors.red, title: 'List Invoice Kulak Belum Lunas Sampai Lunas',
          desc: 'Tunai / Transfer / BG + Mutasi hutang ke supplier',
          onTap: () => Navigator.pushNamed(context, '/payables'),
          trailing: StreamBuilder<List<PayableData>>(stream: db.payablesDao.watchActivePayables(), builder: (_, s){ final data=s.data??[]; final total=data.fold<double>(0, (p,e)=> p+e.remainingAmount); return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${data.length} Faktur', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(fmt.format(total), style: const TextStyle(fontSize: 9, color: Colors.red))]); }),
        ),

        const SizedBox(height: 12),
        // ===== SHORTCUT 3: PENTING LAINNYA REALTIME =====
        _sectionTitle('3. SHORTCUT PENTING LAINNYA (Realtime)', Colors.purple),
        Row(children: [
          Expanded(child: _miniCard(icon: Icons.trending_down_rounded, color: Colors.red, title: 'Stock NIPIS', subtitle: 'Auto detect', onTap: ()=> Navigator.pushNamed(context, '/low-stock'), stream: db.productDao.getLowStockProducts().asStream().map((l)=> '${l.length} SKU'))),
          const SizedBox(width: 8),
          Expanded(child: _miniCard(icon: Icons.local_fire_department_rounded, color: Colors.orange, title: 'Stock MATI 90 Hari', subtitle: 'Tidak laku', onTap: ()=> Navigator.pushNamed(context, '/dead-stock'), stream: Future.value('Cek').asStream())),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _miniCard(icon: Icons.people_alt_rounded, color: Colors.indigo, title: 'Top Customer Ngutang', subtitle: 'Paling sering', onTap: ()=> Navigator.pushNamed(context, '/top-debtors'), stream: db.customerDao.watchTopDebtors().map((l)=> '${l.length} Cust'))),
          const SizedBox(width: 8),
          Expanded(child: _miniCard(icon: Icons.category_rounded, color: Colors.teal, title: 'Laba Per Kategori', subtitle: 'Auto sync', onTap: ()=> Navigator.pushNamed(context, '/category-profit'), stream: Future.value('Realtime').asStream())),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _miniCard(icon: Icons.money_off_rounded, color: Colors.pink, title: 'Pengeluaran Hari Ini', subtitle: 'Biaya operasional', onTap: ()=> Navigator.pushNamed(context, '/expenses'), stream: (db.select(db.expenses)..where((t)=> t.date.isBiggerOrEqualValue(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))).watch().map((l)=> fmt.format(l.fold<double>(0,(p,e)=>p+e.amount))))),
          const SizedBox(width: 8),
          Expanded(child: _miniCard(icon: Icons.lock_rounded, color: Colors.black, title: 'Tutup Buku', subtitle: 'Kunci periode', onTap: ()=> Navigator.pushNamed(context, '/closing-book'), stream: Future.value('Siap').asStream())),
        ]),

        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isDark? const Color(0xFF1E293B) : Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.info_outline, size: 16), SizedBox(width: 8), Expanded(child: Text('Semua shortcut real-time dari awal (1 Jan 2022) sampai hari ini. Tanpa input admin, auto update dari transaksi jual/beli.', style: TextStyle(fontSize: 10)))])),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _sectionTitle(String t, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Container(width: 4, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c))]));
  Widget _shortcutCard({required IconData icon, required Color color, required String title, required String desc, required VoidCallback onTap, Widget? trailing}) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)), title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: Text(desc, style: const TextStyle(fontSize: 10)), trailing: trailing ?? const Icon(Icons.chevron_right, size: 18), onTap: onTap));
  Widget _miniCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap, required Stream<String> stream}) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))]), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)), const SizedBox(height: 6), StreamBuilder<String>(stream: stream, builder: (_, s)=> Text(s.data??'...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))) ]))));
}