import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

final fraudProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchActiveFraudAlerts());
final auditProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchRecentAuditLogs(50));

class AuditFraudPage extends ConsumerWidget {
  const AuditFraudPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frauds = ref.watch(fraudProvider);
    final audits = ref.watch(auditProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit & Fraud')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Fraud Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          frauds.when(
            data: (list) => Column(
              children: list.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: f.severity == 'merah' ? Colors.red.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: f.severity == 'merah' ? Colors.red : Colors.orange)),
                child: Row(children: [
                  Icon(Icons.warning, color: f.severity == 'merah' ? Colors.red : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${f.userId} | ${f.fraudCategory} - ${f.title}\n${f.detailAnalysis}', style: const TextStyle(color: Colors.black, fontSize: 12)))
                ]),
              )).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e,s) => Text('Error $e'),
          ),
          const SizedBox(height: 20),
          const Text('Audit Logs', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          audits.when(
            data: (list) => Column(
              children: list.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(10)),
                child: ListTile(title: Text('${a.actionType} - ${a.userRole} (${a.userId})', style: const TextStyle(color: Colors.black, fontSize: 12)), subtitle: Text('${a.description} - ${a.createdAt}', style: const TextStyle(color: Colors.black54, fontSize: 10))),
              )).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e,s) => Text('Error $e'),
          ),
        ],
      ),
    );
  }
}