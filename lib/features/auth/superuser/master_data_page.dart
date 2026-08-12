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
import 'receivables/invoice_generator.dart';

// LAPORAN HARIAN - BARU BOS
import 'reports/daily_report_page.dart';

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
              const Text('PERSEDIAAN - UD PUTRA SBY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
              const Text('6 Modul ala IPOS 5 - Sinkron HPP Moving Average', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
              _tile(ctx, Icons.inventory_2_rounded, Colors.blue.shade700, 'Master Barang', 'Stok ReadOnly + Min Stock + Pilih Kartu Stok', const MasterBarangPage()),
              _tile(ctx, Icons.download_rounded, Colors.green.shade700, 'Item Masuk', 'Pembelian / Hadiah / Retur - HPP Naik', const ItemMasukPage()),
              _tile(ctx, Icons.upload_rounded, Colors.red.shade700, 'Item Keluar', 'Rusak / Hilang / Sample Toko', const ItemKeluarPage()),
              _tile(ctx, Icons.rule_rounded, Colors.orange.shade800, 'Stok Opname', 'Fisik vs Program + Tanggal Mundur + Warning', const OpnameStockPage()),
              _tile(ctx, Icons.precision_manufacturing_rounded, Colors.purple.shade700, 'Perakitan / Produksi', 'Bahan Baku -> Barang Jadi', const PerakitanPage()),
              _tile(ctx, Icons.swap_horiz_rounded, Colors.blue.shade700, 'Mutasi Stok + Kartu Stok', 'Buku Besar + Rapor 1 Barang + Kuning/Merah', const MutasiStokPage()),
            ],
          ),
        ),
      ),
    );
  }

  void _showHutangMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('HUTANG SUPPLIER - ANTI BOCOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
            const Text('1 Faktur = 1 Payable = 1 Mutasi + CCTV Analytics', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            _tile(ctx, Icons.dashboard_rounded, Colors.red.shade700, 'Dashboard Hutang', 'Outstanding + Overdue + Aging + Top 5 Supplier', const PayablesDashboardPage()),
            _tile(ctx, Icons.request_quote_rounded, Colors.orange.shade700, 'Daftar Hutang Supplier', 'Overdue / Due Soon / Belum Jatuh Tempo - Anti Fiktif', const PayablesListPage()),
            _tile(ctx, Icons.analytics_rounded, Colors.purple.shade700, 'CCTV Hutang (Audit)', 'BAYAR_HUTANG + HUTANG_FIKTIF_DETECT', const PayablesDashboardPage()),
          ],
        ),
      ),
    );
  }

  void _showPembelianMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('PEMBELIAN / KULAK SUPPLIER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
            const Text('Invoice Supplier + Auto Index + Masuk Hutang Supplier', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            _tile(ctx, Icons.list_alt_rounded, Colors.blue.shade700, 'List Faktur Kulak', 'Cari: No Faktur / Supplier / Tanggal - Auto Index', const PurchaseListPage()),
            _tile(ctx, Icons.add_shopping_cart_rounded, Colors.green.shade700, 'Input Kulak Baru', 'Invoice Supplier + Supplier + Tanggal + Item', const PurchaseInputPage()),
            _tile(ctx, Icons.request_quote_rounded, Colors.red.shade700, 'Lihat Hutang Supplier', 'Setelah kulak, hutang auto masuk sini', const PayablesListPage()),
          ],
        ),
      ),
    );
  }

  void _showPiutangMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('PIUTANG CUSTOMER - ANTI NGENDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
            const Text('INV-DDMMYY-IDCSTMR-NAMA-JAM-RAND + CCTV + Aging MERAH', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            _tile(ctx, Icons.dashboard_rounded, Colors.green.shade700, 'Dashboard Piutang Bos', 'Uang Nyangkut + Aging 0-7, 8-30, 31-60, >60 + Top 10 Overdue', const ReceivablesDashboardPage()),
            _tile(ctx, Icons.add_card_rounded, Colors.blue.shade700, 'Input Piutang Baru', 'Auto INV-XXX-CSTMR + Pilih Kenapa Ngendap', const ReceivablesInputPage()),
            _tile(ctx, Icons.list_alt_rounded, Colors.orange.shade700, 'Daftar Piutang Aktif', 'Search + JT Hari Ini + Overdue MERAH', const ReceivablesListPage()),
          ],
        ),
      ),
    );
  }

  void _showLaporanMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('LAPORAN HARIAN - AUTO SYNC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
            const Text('Omset + Laba Rugi + Neraca + Void + Mutasi Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            _tile(ctx, Icons.today_rounded, Colors.indigo.shade700, 'Laporan Harian Lengkap', 'Omset, Laba Rugi, Neraca, Void, Mutasi - Filter Tanggal', const DailyReportPage()),
            _tile(ctx, Icons.bar_chart_rounded, Colors.green.shade700, 'Laporan Omset', 'Harian / Mingguan / Bulanan + Grafik', const DailyReportPage()),
            _tile(ctx, Icons.account_balance_wallet_rounded, Colors.purple.shade700, 'Laporan Neraca', 'Aset Lancar + Tetap + Hutang + Modal Auto', const DailyReportPage()),
            _tile(ctx, Icons.block_rounded, Colors.red.shade700, 'Laporan Void', 'Siapa Nge-Void + Alasan + CCTV', const DailyReportPage()),
          ],
        ),
      ),
    );
  }

  static Widget _tile(BuildContext ctx, IconData icon, Color color, String title, String subtitle, Widget page) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = [
      {
        'title': 'Produk Perkakas\n24 Kategori',
        'subtitle': 'Master + FAB emas',
        'icon': Icons.handyman_rounded,
        'color': Colors.orange.shade700,
        'type': 'page',
        'page': const ProductPage()
      },
      {
        'title': 'PIUTANG\nCUSTOMER',
        'subtitle': 'INV-XXX + Aging MERAH',
        'icon': Icons.credit_score_rounded,
        'color': Colors.green.shade700,
        'type': 'piutang',
        'page': null,
      },
      {
        'title': 'PERSEDIAAN\nIPOS 5',
        'subtitle': '6 Modul Lengkap',
        'icon': Icons.inventory_rounded,
        'color': Colors.blue.shade700,
        'type': 'persediaan',
        'page': null,
      },
      {
        'title': 'HUTANG\nSUPPLIER',
        'subtitle': 'Dashboard + List',
        'icon': Icons.request_quote_rounded,
        'color': Colors.red.shade700,
        'type': 'hutang',
        'page': null,
      },
      {
        'title': 'Stok Opname',
        'subtitle': 'Fisik vs Program',
        'icon': Icons.rule_rounded,
        'color': Colors.orange.shade800,
        'type': 'page',
        'page': const OpnameStockPage(),
      },
      {
        'title': 'Mutasi & Kartu',
        'subtitle': 'Besar + Per Barang',
        'icon': Icons.history_edu_rounded,
        'color': Colors.indigo,
        'type': 'page',
        'page': const MutasiStokPage(),
      },
      {
        'title': 'Penjualan',
        'subtitle': 'Riwayat & Retur',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.teal.shade700,
        'type': 'soon',
        'page': null,
      },
      {
        'title': 'Pembelian',
        'subtitle': 'PO & Masuk + Hutang',
        'icon': Icons.shopping_cart_checkout_rounded,
        'color': Colors.purple.shade700,
        'type': 'pembelian',
        'page': null,
      },
      {
        'title': 'LAPORAN\nHARIAN',
        'subtitle': 'Omset + Laba + Neraca',
        'icon': Icons.analytics_rounded,
        'color': Colors.amber.shade800,
        'type': 'laporan',
        'page': null,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Master Data - UD Putra', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: menus.length,
        itemBuilder: (c, i) {
          final m = menus[i];
          final isPersediaan = m['type'] == 'persediaan';
          final isHutang = m['type'] == 'hutang';
          final isPembelian = m['type'] == 'pembelian';
          final isPiutang = m['type'] == 'piutang';
          final isLaporan = m['type'] == 'laporan';
          return GlassCard(
            onTap: () {
              if (isPersediaan) { _showPersediaanMenu(context); return; }
              if (isHutang) { _showHutangMenu(context); return; }
              if (isPembelian) { _showPembelianMenu(context); return; }
              if (isPiutang) { _showPiutangMenu(context); return; }
              if (isLaporan) { _showLaporanMenu(context); return; }
              final page = m['page'] as Widget?;
              if (page!= null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => page));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m['title']} - Segera hadir')));
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: (m['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: (m['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Icon(m['icon'] as IconData, size: 32, color: m['color'] as Color),
                    ),
                    if (isPersediaan)
                      Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('6', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                    if (isHutang)
                      Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                    if (isPembelian)
                      Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)), child: const Text('KULAK', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                    if (isPiutang)
                      Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)), child: const Text('INV', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                    if (isLaporan)
                      Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(10)), child: const Text('AUTO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(m['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12, height: 1.2)),
                const SizedBox(height: 4),
                Text(m['subtitle'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Poppins')),
              ],
            ),
          );
        },
      ),
    );
  }
}