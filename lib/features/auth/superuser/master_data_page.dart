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
        'title': 'POS Kasir',
        'subtitle': 'Barcode cepat',
        'icon': Icons.point_of_sale_rounded,
        'color': const Color(0xFF007F00),
        'type': 'soon',
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
        'subtitle': 'PO & Masuk',
        'icon': Icons.shopping_cart_checkout_rounded,
        'color': Colors.purple.shade700,
        'type': 'soon',
        'page': null,
      },
      {
        'title': 'Hutang Piutang',
        'subtitle': 'Supplier & Customer',
        'icon': Icons.request_quote_rounded,
        'color': Colors.red.shade700,
        'type': 'soon',
        'page': null,
      },
      {
        'title': 'Laporan',
        'subtitle': 'Laba & Omset',
        'icon': Icons.analytics_rounded,
        'color': Colors.amber.shade800,
        'type': 'soon',
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
          return GlassCard(
            onTap: () {
              if (isPersediaan) {
                _showPersediaanMenu(context);
                return;
              }
              final page = m['page'] as Widget?;
              if (page!= null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => page));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${m['title']} - Segera hadir')),
                );
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
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: const Text('6', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
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