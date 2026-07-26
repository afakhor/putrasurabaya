import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_providers.dart';
import '../models/dashboard_finance_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardFinanceSummaryProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
              // Header Tanggal Today
              _buildDateHeader(),
              const SizedBox(height: 16),

              // Penanganan State Stream (Loading, Error, Data)
              summaryAsync.when(
                data: (summary) => _buildDashboardContent(
                  context,
                  summary,
                  currencyFormatter,
                ),
                loading: () => const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gagal memuat data dashboard: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Quick Action Grid Shortcuts
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
        ),
      ],
    );
  }

  /// Konten Statistik Utama
  Widget _buildDashboardContent(
    BuildContext context,
    DashboardFinanceSummary summary,
    NumberFormat currency,
  ) {
    return Column(
      children: [
        // Grid Baris 1: Omset & Laba Kotor Hari Ini
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Omset Hari Ini',
                value: currency.format(summary.omsetHariIni),
                subtitle: '${summary.jumlahTransaksiHariIni} Transaksi',
                icon: Icons.payments_outlined,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Est. Laba Kotor',
                value: currency.format(summary.labaKotorHariIni),
                subtitle: 'Margin Bersih HPP',
                icon: Icons.trending_up_rounded,
                color: Colors.teal.shade700,
                bgColor: Colors.teal.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid Baris 2: Tagihan Piutang & Hutang Usaha
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Piutang',
                value: currency.format(summary.totalSisaPiutang),
                subtitle: '${summary.jumlahPiutangAktif} Nota Belum Lunas',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Total Hutang',
                value: currency.format(summary.totalSisaHutang),
                subtitle: '${summary.jumlahHutangAktif} Tagihan Supplier',
                icon: Icons.assignment_late_outlined,
                color: Colors.red.shade700,
                bgColor: Colors.red.shade50,
              ),
            ),
          ],
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
            // Navigasi ke Kasir POS
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.inventory_2_outlined,
          label: 'Barang',
          color: Colors.orange,
          onTap: () {
            // Navigasi ke Stok / Master Barang
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.shopping_bag_outlined,
          label: 'Pembelian',
          color: Colors.purple,
          onTap: () {
            // Navigasi ke Pembelian Stok (AP)
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.bar_chart_rounded,
          label: 'Laporan',
          color: Colors.teal,
          onTap: () {
            // Navigasi ke Laporan Keuangan
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

/// Widget Card Reusable untuk Indikator Angka Statistik
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
