import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import provider dari folder providers
import '../../providers/dashboard_providers.dart';

class DashboardSummaryCards extends ConsumerWidget {
  const DashboardSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardFinanceSummaryProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return summaryAsync.when(
      data: (data) => Column(
        children: [
          // Baris 1: Omset & Laba Kotor Hari Ini
          Row(
            children: [
              _buildCard(
                title: 'Omset Hari Ini',
                value: currency.format(data.omsetHariIni),
                subtitle: '${data.jumlahTransaksiHariIni} Transaksi',
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(width: 12),
              _buildCard(
                title: 'Est. Laba Kotor',
                value: currency.format(data.labaKotorHariIni),
                subtitle: 'Margin Bersih HPP',
                color: Colors.teal.shade700,
                bgColor: Colors.teal.shade50,
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Baris 2: Piutang & Hutang
          Row(
            children: [
              _buildCard(
                title: 'Sisa Piutang',
                value: currency.format(data.totalSisaPiutang),
                subtitle: '${data.jumlahPiutangAktif} Nota Belum Lunas',
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(width: 12),
              _buildCard(
                title: 'Sisa Hutang',
                value: currency.format(data.totalSisaHutang),
                subtitle: '${data.jumlahHutangAktif} Tagihan Supplier',
                color: Colors.red.shade700,
                bgColor: Colors.red.shade50,
                icon: Icons.assignment_late_outlined,
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        color: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}
