import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';

final fraudProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchActiveFraudAlerts());
final auditProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchRecentAuditLogs(50));

class AuditFraudPage extends ConsumerWidget {
  const AuditFraudPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frauds = ref.watch(fraudProvider);
    final audits = ref.watch(auditProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Fraud Alert Aktif', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      frauds.when(data: (list) => Column(children: list.map((f) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)), child: Row(children: [const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text('${f.salesmanName}: ${f.alertType} - ${f.description}', style: const TextStyle(color: Colors.black, fontSize: 12)))]))).toList()), loading: () => const LinearProgressIndicator(), error: (e,s) => Text('Error $e')),
      const SizedBox(height: 20),
      const Text('Audit Trail 50 Terakhir', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      audits.when(data: (list) => Column(children: list.map((a) => Container(margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(10)), child: ListTile(title: Text('${a.actionType} - ${a.salesmanName}', style: const TextStyle(color: Colors.black, fontSize: 12)), subtitle: Text('${a.createdAt}', style: const TextStyle(color: Colors.black54, fontSize: 10))))).toList()), loading: () => const LinearProgressIndicator(), error: (e,s) => Text('Error $e')),
    ]);
  }
}