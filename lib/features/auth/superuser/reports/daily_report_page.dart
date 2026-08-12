import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

// ================= PROVIDER LAPORAN =================
final reportDateProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59));
});

final dailyReportProvider = FutureProvider<DailyReportData>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final range = ref.watch(reportDateProvider);
  return DailyReportData.generate(db, range);
});

class DailyReportData {
  final double omset, hpp, labaKotor, totalBiaya, labaBersih;
  final double totalAsetLancar, totalAsetTetap, totalHutang, modal;
  final double nilaiStock, piutangAktif, hutangAktif, cashOnHand;
  final int totalTransaksi, totalVoid, totalItemTerjual;
  final List<SalesData> voidList;
  final List<StockMovementData> mutasiList;

  DailyReportData({
    required this.omset, required this.hpp, required this.labaKotor,
    required this.totalBiaya, required this.labaBersih,
    required this.totalAsetLancar, required this.totalAsetTetap,
    required this.totalHutang, required this.modal,
    required this.nilaiStock, required this.piutangAktif,
    required this.hutangAktif, required this.cashOnHand,
    required this.totalTransaksi, required this.totalVoid,
    required this.totalItemTerjual, required this.voidList, required this.mutasiList,
  });

  static Future<DailyReportData> generate(LocalDatabase db, DateTimeRange range) async {
    // 1. OMSET & HPP dari tabel sales
    final sales = await db.salesDao.getSalesByDateRange(range.start, range.end);
    final omset = sales.fold<double>(0, (p, e) => p + e.totalAmount);
    final hpp = sales.fold<double>(0, (p, e) => p + e.hppTotal);
    final totalTransaksi = sales.length;
    final totalItem = sales.fold<int>(0, (p, e) => p + e.totalQty);

    // 2. VOID
    final voidSales = await db.salesDao.getVoidByDateRange(range.start, range.end);
    
    // 3. BIAYA / PENGELUARAN
    final biaya = await db.expenseDao.getTotalByDateRange(range.start, range.end);

    // 4. STOCK VALUE (AUTO SYNC)
    final nilaiStock = await db.productDao.getTotalStockValue();
    final mutasi = await db.stockDao.getMutasiByDateRange(range.start, range.end);

    // 5. PIUTANG & HUTANG (AUTO SYNC)
    final piutang = await db.receivablesDao.getTotalActiveReceivableAmount();
    final hutang = await db.payablesDao.getTotalActivePayableAmount();

    // 6. ASET TETAP
    final asetTetap = await db.assetDao.getTotalAssetValue();
    final cash = await db.cashDao.getCashBalance();

    final labaKotor = omset - hpp;
    final labaBersih = labaKotor - biaya;
    final asetLancar = nilaiStock + piutang + cash;

    return DailyReportData(
      omset: omset, hpp: hpp, labaKotor: labaKotor, totalBiaya: biaya, labaBersih: labaBersih,
      totalAsetLancar: asetLancar, totalAsetTetap: asetTetap, totalHutang: hutang, modal: asetLancar + asetTetap - hutang,
      nilaiStock: nilaiStock, piutangAktif: piutang, hutangAktif: hutang, cashOnHand: cash,
      totalTransaksi: totalTransaksi, totalVoid: voidSales.length, totalItemTerjual: totalItem,
      voidList: voidSales, mutasiList: mutasi,
    );
  }
}

// ================= UI LAPORAN =================
class DailyReportPage extends ConsumerWidget {
  const DailyReportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateProvider);
    final report = ref.watch(dailyReportProvider);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian Bos'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: () async {
            final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now(), initialDateRange: range);
            if(picked != null) ref.read(reportDateProvider.notifier).state = picked;
          }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> ref.refresh(dailyReportProvider)),
        ],
      ),
      body: report.when(
        data: (d) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // FILTER INFO
            Card(color: Colors.indigo.shade50, child: ListTile(leading: const Icon(Icons.calendar_today), title: Text('${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}'), subtitle: Text('${d.totalTransaksi} transaksi | ${d.totalItemTerjual} item'))),
            
            // OMSET
            _section('1. OMSET & LABA RUGI', [
              _row('Omset Penjualan', f.format(d.omset), Colors.green, true),
              _row('HPP (Modal Barang)', f.format(d.hpp), Colors.orange),
              _row('Laba Kotor', f.format(d.labaKotor), Colors.blue, true),
              _row('Total Biaya Operasional', f.format(d.totalBiaya), Colors.red),
              const Divider(),
              _row('LABA BERSIH', f.format(d.labaBersih), d.labaBersih >=0 ? Colors.green : Colors.red, true, 18),
            ]),

            // NERACA AUTO SYNC
            _section('2. NERACA - AUTO SYNC STOCK & ASET', [
              _row('Nilai Stock (Auto)', f.format(d.nilaiStock), Colors.blue),
              _row('Piutang Aktif (INV-XXX)', f.format(d.piutangAktif), Colors.orange),
              _row('Cash On Hand', f.format(d.cashOnHand), Colors.green),
              _row('Total Aset Lancar', f.format(d.totalAsetLancar), Colors.indigo, true),
              const SizedBox(height: 8),
              _row('Aset Tetap (Etalase, dll)', f.format(d.totalAsetTetap), Colors.brown),
              const Divider(),
              _row('Hutang Supplier (HUT-XXX)', f.format(d.totalHutang), Colors.red),
              _row('MODAL BERSIH', f.format(d.modal), Colors.purple, true, 16),
            ]),

            // TRANSAKSI VOID
            _section('3. TRANSAKSI VOID - CCTV', [
              Text('Total Void: ${d.totalVoid} transaksi', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              ...d.voidList.map((v) => ListTile(dense: true, tileColor: Colors.red.shade50, leading: const Icon(Icons.block, color: Colors.red), title: Text(v.invoiceNo?? v.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)), subtitle: Text('Void by: ${v.voidBy} | ${v.voidReason}'), trailing: Text(f.format(v.totalAmount)))),
              if(d.voidList.isEmpty) const Text('Aman, tidak ada void', style: TextStyle(color: Colors.grey)),
            ]),

            // MUTASI STOCK AUTO
            _section('4. MUTASI STOCK - AUTO SYNC PEMBELIAN & PENJUALAN', [
              ...d.mutasiList.take(20).map((m) => ListTile(dense: true, leading: Icon(m.type=='IN'? Icons.arrow_downward : Icons.arrow_upward, color: m.type=='IN'? Colors.green: Colors.red), title: Text(m.productName?? m.productId, style: const TextStyle(fontSize: 12)), subtitle: Text('${m.type} | ${m.reason} | ${DateFormat('HH:mm').format(m.createdAt)}'), trailing: Text('${m.qty>0?"+":""}${m.qty}', style: TextStyle(color: m.type=='IN'? Colors.green: Colors.red, fontWeight: FontWeight.bold)))),
              if(d.mutasiList.isEmpty) const Text('Tidak ada mutasi di periode ini'),
            ]),

            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: ()=> _exportPdf(context, d, range), icon: const Icon(Icons.picture_as_pdf), label: const Text('EXPORT PDF BOS'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.indigo)),
          ],
        ),
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)), const Divider(), ...children])));
  Widget _row(String label, String value, Color color, [bool bold=false, double size=14]) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: size, fontWeight: bold? FontWeight.bold: FontWeight.normal)), Text(value, style: TextStyle(fontSize: size, fontWeight: bold? FontWeight.bold: FontWeight.w500, color: color))]));
  
  void _exportPdf(BuildContext ctx, DailyReportData d, DateTimeRange r) {
    // TODO: pakai package pdf
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Export PDF - Coming soon, data sudah siap')));
  }
}