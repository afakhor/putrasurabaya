import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_providers.dart';
import 'widgets/dashboard_summary_cards.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Method Helper untuk Mengisikan Ulang (Invalidate) Seluruh Provider Dashboard
  void _refreshDashboard(WidgetRef ref) {
    ref.invalidate(dashboardFinanceSummaryProvider);
    ref.invalidate(lowStockProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardFinanceSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Dashboard iPOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => _refreshDashboard(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshDashboard(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Tanggal Hari Ini
              _buildDateHeader(),
              const SizedBox(height: 16),

              // 2. Banner Peringatan Stok Menipis (Otomatis muncul jika ada stok <= minStock)
              summaryAsync.maybeWhen(
                data: (summary) {
                  if (summary.stokMenipisCount > 0) {
                    return _buildLowStockBanner(
                      context,
                      ref,
                      count: summary.stokMenipisCount,
                    );
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // 3. Widget Card Statistik Ringkasan Keuangan
              const DashboardSummaryCards(),

              const SizedBox(height: 24),
              const Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Quick Action Grid Shortcuts
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Header Menampilkan Tanggal Hari Ini
  Widget _buildDateHeader() {
    final todayFormatted =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Hari Ini',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          todayFormatted,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Banner Alert untuk Stok Menipis
  Widget _buildLowStockBanner(BuildContext context, WidgetRef ref,
      {required int count}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade100,
          child:
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
        ),
        title: Text(
          '$count Produk Stok Menipis!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.amber.shade900,
          ),
        ),
        subtitle: const Text(
          'Ketuk untuk melihat daftar barang yang perlu di-restock.',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: () => _showLowStockBottomSheet(context, ref),
      ),
    );
  }

  /// Modal BottomSheet Menampilkan Daftar Produk Stok Menipis
  void _showLowStockBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      const Text(
                        'Produk Perlu Restock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final lowStockAsync = ref.watch(lowStockProductsProvider);

                    return lowStockAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return const Center(
                            child: Text('Semua stok barang aman!'),
                          );
                        }
                        return ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Kode: ${product.barcode ?? '-'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'Sisa: ${product.stock} (Min: ${product.minStock})',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Gagal memuat produk: $err'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Menu Akses Cepat Transaksi
  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85, // Menjaga agar icon & teks pas di layar HP
      children: [
        _buildActionItem(
          context,
          icon: Icons.point_of_sale,
          label: 'Kasir POS',
          color: Colors.blue,
          onTap: () {
            // TODO: Navigasi ke Kasir POS
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.inventory_2_outlined,
          label: 'Barang',
          color: Colors.orange,
          onTap: () {
            // TODO: Navigasi ke Stok / Master Barang
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.shopping_bag_outlined,
          label: 'Pembelian',
          color: Colors.purple,
          onTap: () {
            // TODO: Navigasi ke Pembelian Stok
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.bar_chart_rounded,
          label: 'Laporan',
          color: Colors.teal,
          onTap: () {
            // TODO: Navigasi ke Laporan Keuangan
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
