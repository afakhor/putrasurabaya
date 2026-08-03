import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';

final financeProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchFinanceSummary());
final riskProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchOwnerRiskStatus());

class DashboardOwnerPage extends ConsumerWidget {
  const DashboardOwnerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final risk = ref.watch(riskProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: finance.when(
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          children: [
            risk.when(
              data: (r) => GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Status Toko: $r', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _card(context, 'Omset Hari Ini', 'Rp ${d.omsetHariIni}', Icons.trending_up_rounded, Colors.blue),
                _card(context, 'Piutang', 'Rp ${d.totalSisaPiutang}', Icons.receipt_long_rounded, Colors.orange),
                _card(context, 'Hutang', 'Rp ${d.totalSisaHutang}', Icons.money_off_rounded, Colors.red),
                _card(context, 'Stok Menipis', '${d.stokMenipisCount} item', Icons.warning_rounded, Colors.purple),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _card(BuildContext ctx, String t, String v, IconData i, Color c) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(i, color: c, size: 20),
          ),
          const Spacer(),
          Text(t, style: const TextStyle(fontSize: 11, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}