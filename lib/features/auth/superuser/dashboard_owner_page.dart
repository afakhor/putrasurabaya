import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

final financeProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchFinanceSummary());
final riskProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchOwnerRiskStatus());

class DashboardOwnerPage extends ConsumerWidget {
  const DashboardOwnerPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final risk = ref.watch(riskProvider);

    return Scaffold(
      body: finance.when(
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            risk.when(data: (r) => Chip(label: Text('Status: $r')), loading: () => const SizedBox(), error: (_,__)=> const SizedBox()),
            const SizedBox(height: 12),
            _card('Omset Hari Ini', 'Rp ${d.omsetHariIni}', Icons.trending_up),
            _card('Piutang', 'Rp ${d.totalSisaPiutang}', Icons.receipt_long),
            _card('Hutang', 'Rp ${d.totalSisaHutang}', Icons.money_off),
            _card('Stok Menipis', '${d.stokMenipisCount} item', Icons.warning),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _card(String t, String v, IconData i) => Card(child: ListTile(leading: Icon(i), title: Text(t), subtitle: Text(v, style: const TextStyle(fontWeight: FontWeight.bold))));
}