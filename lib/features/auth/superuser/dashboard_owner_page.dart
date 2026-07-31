import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';

final financeSummaryProvider = StreamProvider((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.dashboardDao.watchFinanceSummary();
});
final riskStatusProvider = StreamProvider((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.dashboardDao.watchOwnerRiskStatus();
});

class DashboardOwnerPage extends ConsumerWidget {
  const DashboardOwnerPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeSummaryProvider);
    final risk = ref.watch(riskStatusProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        finance.when(
          data: (d) => Row(children: [
            _card('Omset Hari Ini', 'Rp ${d.todaySales}', Icons.trending_up),
            const SizedBox(width: 12),
            _card('Piutang', 'Rp ${d.totalReceivable}', Icons.receipt_long),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e,s) => Text('Error $e', style: const TextStyle(color: Colors.black)),
        ),
        const SizedBox(height: 16),
        const Text('Indikator Risiko Salesman', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        risk.when(
          data: (list) => Column(children: list.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: r.status=='Merah'? Colors.red : r.status=='Kuning'? Colors.orange : Colors.green)),
            child: ListTile(
              leading: Icon(r.status=='Merah'? Icons.error : Icons.check_circle, color: r.status=='Merah'? Colors.red : Colors.green),
              title: Text(r.description, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('${r.salesmanName} - ${r.status}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ),
          )).toList()),
          loading: () => const SizedBox(),
          error: (e,s) => Text('Error $e'),
        ),
      ],
    );
  }
  Widget _card(String title, String val, IconData icon) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Colors.black), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11)), Text(val, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)) ])));
  }
}