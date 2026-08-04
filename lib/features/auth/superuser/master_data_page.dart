import 'package:flutter/material.dart';
import '../../../core/utils/config.dart';
import 'product/product_page.dart';
//import 'pos/pos_page.dart';
//import 'stock/stock_mutation_page.dart'; // kartu stok + mutasi
//import 'sales/sales_history_page.dart'; // riwayat penjualan
//import 'debt/debt_receivable_page.dart'; // faktur hutang/piutang
//import 'purchase/purchase_page.dart';
//import 'report/stock_report_page.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 8 MENU UTAMA ALA IPOS 5 UNTUK UD PUTRA SURABAYA
    final menus = [
      {
        'title': 'Produk Perkakas\n24 Kategori',
        'subtitle': 'Master produk + FAB emas',
        'icon': Icons.handyman_rounded,
        'color': Colors.orange.shade700,
        'page': const ProductPage()
      },
      {
        'title': 'POS Kasir',
        'subtitle': 'Transaksi cepat barcode',
        'icon': Icons.point_of_sale_rounded,
        'color': const Color(0xFF007F00),
        'page': '/PosPage()',
      },
      {
        'title': 'Mutasi Stok',
        'subtitle': 'Item masuk / keluar',
        'icon': Icons.swap_horiz_rounded,
        'color': Colors.blue.shade700,
        'page': '/StockMutationPage()',
      },
      {
        'title': 'Kartu Stok',
        'subtitle': 'Riwayat per produk',
        'icon': Icons.history_edu_rounded,
        'color': Colors.indigo,
        'page': '/StockReportPage()',
      },
      {
        'title': 'Penjualan',
        'subtitle': 'Riwayat & retur jual',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.teal.shade700,
        'page': '/SalesHistoryPage()',
      },
      {
        'title': 'Pembelian',
        'subtitle': 'PO & stok masuk',
        'icon': Icons.shopping_cart_checkout_rounded,
        'color': Colors.purple.shade700,
        'page': '/PurchasePage()',
      },
      {
        'title': 'Faktur Hutang\nPiutang',
        'subtitle': 'Hutang supplier & piutang customer',
        'icon': Icons.request_quote_rounded,
        'color': Colors.red.shade700,
        'page': '/DebtReceivablePage()',
      },
      {
        'title': 'Laporan',
        'subtitle': 'Laba, stok, omset',
        'icon': Icons.analytics_rounded,
        'color': Colors.amber.shade800,
        'page': null, // nanti arahkan ke DashboardDao
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Master Data - UD Putra', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: menus.length,
        itemBuilder: (c, i) {
          final m = menus[i];
          return GlassCard(
            onTap: () {
              if (m['page']!= null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => m['page'] as Widget));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${m['title']} - Segera hadir (hubungkan ke DashboardDao)')),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 12),
                Text(
                  m['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  m['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Poppins'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}