import 'package:flutter/material.dart';
import '../../../core/utils/config.dart';

// MASTER PRODUK
import 'product/product_page.dart';

// PERSEDIAAN - 6 PAGE IPOS 5
import 'master_barang_page.dart';
import 'stock/item_masuk_page.dart';
import 'stock/item_keluar_page.dart';
import 'stock/opname_stock_page.dart';
import 'stock/perakitan_page.dart';
import 'stock/mutasi_stock_page.dart';

// HUTANG SUPPLIER - PAYABLES IPOS
import 'payables/payables_list_page.dart';
import 'payables/payables_dashboard_page.dart';

// PEMBELIAN / KULAK SUPPLIER
import 'purchase/purchase_list_page.dart';
import 'purchase/purchase_input_page.dart';

// PIUTANG CUSTOMER - RECEIVABLES BARU INV-XXX-CSTMR
import 'receivables/receivables_dashboard_page.dart';
import 'receivables/receivables_input_page.dart';
import 'receivables/receivables_list_page.dart';

// LAPORAN - AUTO SYNC
import 'reports/daily_report_page.dart';
import 'reports/monthly_report_page.dart';
import 'reports/closing_book_report_page.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});

  void _showPersediaanMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (_, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('PERSEDIAAN - UD PUTRA SBY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _tile(ctx, Icons.inventory_2_rounded, Colors.blue.shade700, 'Master Barang', 'Stok ReadOnly + Min Stock', const MasterBarangPage()),
              _tile(ctx, Icons.download_rounded, Colors.green.shade700, 'Item Masuk', 'Pembelian / Hadiah / Retur', const ItemMasukPage()),
              _tile(ctx, Icons.upload_rounded, Colors.red.shade700, 'Item Keluar', 'Rusak / Hilang / Sample', const ItemKeluarPage()),
              _tile(ctx, Icons.rule_rounded, Colors.orange.shade800, 'Stok Opname', 'Fisik vs Program', const OpnameStockPage()),
              _tile(ctx, Icons.precision_manufacturing_rounded, Colors.purple.shade700, 'Perakitan / Produksi', 'Bahan Baku -> Jadi', const PerakitanPage()),
              _tile(ctx, Icons.swap_horiz_rounded, Colors.blue.shade700, 'Mutasi Stok', 'Buku Besar + Kartu Stok', const MutasiStokPage()),
            ],
          ),
        ),
      ),
    );
  }

  void _showHutangMenu(BuildContext context) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      const Text('HUTANG SUPPLIER - ANTI BOCOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 16),
      _tile(ctx, Icons.dashboard_rounded, Colors.red.shade700, 'Dashboard Hutang', 'Outstanding + Overdue', const PayablesDashboardPage()),
      _tile(ctx, Icons.request_quote_rounded, Colors.orange.shade700, 'Daftar Hutang', 'Overdue / Due Soon', const PayablesListPage()),
    ])));
  }

  void _showPembelianMenu(BuildContext context) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      const Text('PEMBELIAN / KULAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 16),
      _tile(ctx, Icons.list_alt_rounded, Colors.blue.shade700, 'List Faktur Kulak', 'No Faktur / Supplier', const PurchaseListPage()),
      _tile(ctx, Icons.add_shopping_cart_rounded, Colors.green.shade700, 'Input Kulak Baru', 'Auto Hutang', const PurchaseInputPage()),
    ])));
  }

  void _showPiutangMenu(BuildContext context) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      const Text('PIUTANG CUSTOMER - ANTI NGENDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 16),
      _tile(ctx, Icons.dashboard_rounded, Colors.green.shade700, 'Dashboard Piutang', 'Uang Nyangkut + Aging', const ReceivablesDashboardPage()),
      _tile(ctx, Icons.add_card_rounded, Colors.blue.shade700, 'Input Piutang Baru', 'Auto INV-XXX-CSTMR', const ReceivablesInputPage()),
      _tile(ctx, Icons.list_alt_rounded, Colors.orange.shade700, 'Daftar Piutang Aktif', 'JT Hari Ini + MERAH', const ReceivablesListPage()),
    ])));
  }

  void _showLaporanMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('LAPORAN - AUTO SYNC + TUTUP BUKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text('Omset + Laba Rugi + Neraca + Hutang Piutang + Stock + Kunci Periode', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 16),
        _tile(ctx, Icons.today_rounded, Colors.indigo.shade700, 'Laporan Harian Lengkap', 'Omset, Laba Rugi, Neraca, Void, Mutasi', const DailyReportPage()),
        _tile(ctx, Icons.calendar_month_rounded, Colors.purple.shade700, 'Laporan Bulanan Rekap', 'Hutang + Piutang + Stock + Filter + Autocomplete', const MonthlyReportPage()),
        _tile(ctx, Icons.lock_rounded, Colors.black87, 'TUTUP BUKU FINAL BOS', 'Laba Rugi + Neraca Balance + Kunci Periode + Auto Stock Awal', const ClosingBookReportPage()),
        _tile(ctx, Icons.block_rounded, Colors.red.shade700, 'Laporan Void CCTV', 'Siapa Nge-Void + Alasan', const DailyReportPage()),
      ])),
    );
  }

  static Widget _tile(BuildContext ctx, IconData icon, Color color, String title, String subtitle, Widget page) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = [
      {'title': 'Produk\n24 Kategori', 'subtitle': 'Master + FAB', 'icon': Icons.handyman_rounded, 'color': Colors.orange.shade700, 'type': 'page', 'page': const ProductPage()},
      {'title': 'PIUTANG\nCUSTOMER', 'subtitle': 'INV-XXX + MERAH', 'icon': Icons.credit_score_rounded, 'color': Colors.green.shade700, 'type': 'piutang', 'page': null},
      {'title': 'PERSEDIAAN\nIPOS 5', 'subtitle': '6 Modul Lengkap', 'icon': Icons.inventory_rounded, 'color': Colors.blue.shade700, 'type': 'persediaan', 'page': null},
      {'title': 'HUTANG\nSUPPLIER', 'subtitle': 'Dashboard + List', 'icon': Icons.request_quote_rounded, 'color': Colors.red.shade700, 'type': 'hutang', 'page': null},
      {'title': 'Stok Opname', 'subtitle': 'Fisik vs Program', 'icon': Icons.rule_rounded, 'color': Colors.orange.shade800, 'type': 'page', 'page': const OpnameStockPage()},
      {'title': 'Mutasi & Kartu', 'subtitle': 'Besar + Per Barang', 'icon': Icons.history_edu_rounded, 'color': Colors.indigo, 'type': 'page', 'page': const MutasiStokPage()},
      {'title': 'Pembelian', 'subtitle': 'PO & Masuk', 'icon': Icons.shopping_cart_checkout_rounded, 'color': Colors.purple.shade700, 'type': 'pembelian', 'page': null},
      {'title': 'LAPORAN &\nTUTUP BUKU', 'subtitle': 'Harian + Bulanan + Kunci', 'icon': Icons.analytics_rounded, 'color': Colors.black87, 'type': 'laporan', 'page': null},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Master Data - UD Putra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95),
        itemCount: menus.length,
        itemBuilder: (c, i) {
          final m = menus[i];
          final isLaporan = m['type'] == 'laporan';
          return GlassCard(
            onTap: () {
              final type = m['type'] as String;
              if (type == 'persediaan') { _showPersediaanMenu(context); return; }
              if (type == 'hutang') { _showHutangMenu(context); return; }
              if (type == 'pembelian') { _showPembelianMenu(context); return; }
              if (type == 'piutang') { _showPiutangMenu(context); return; }
              if (type == 'laporan') { _showLaporanMenu(context); return; }
              final page = m['page'] as Widget?;
              if (page!= null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.15), shape: BoxShape.circle), child: Icon(m['icon'] as IconData, size: 32, color: m['color'] as Color)),
                if(isLaporan) Positioned(right: -6, top: -6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)), child: const Text('FINAL', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
              ]),
              const SizedBox(height: 12),
              Text(m['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2)),
              const SizedBox(height: 4),
              Text(m['subtitle'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ]),
          );
        },
      ),
    );
  }
}