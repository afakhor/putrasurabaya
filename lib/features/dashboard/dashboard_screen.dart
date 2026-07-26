import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_providers.dart';
import 'widgets/dashboard_summary_cards.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => ref.invalidate(dashboardFinanceSummaryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardFinanceSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Tanggal Hari Ini
              _buildDateHeader(),
              const SizedBox(height: 16),

              // 2. Widget Card Statistik Ringkasan Keuangan (Omset, Laba, Piutang, Hutang)
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

              // 3. Quick Action Grid Shortcuts
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Header Menampilkan Tanggal Hari Ini
  Widget _buildDateHeader() {
    final todayFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
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

  /// Menu Akses Cepat Transaksi
  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionItem(
          context,
          icon: Icons.point_of_sale,
          label: 'Kasir POS',
          color: Colors.blue,
          onTap: () {
            // TODO: Navigasi ke Halaman Kasir POS
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
            // TODO: Navigasi ke Pembelian Stok (AP)
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
            ),
          ],
        ),
      ),
    );
  }
}
