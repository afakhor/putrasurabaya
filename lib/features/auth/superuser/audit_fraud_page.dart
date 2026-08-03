import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';

final fraudProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchActiveFraudAlerts());
final auditProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).dashboardDao.watchRecentAuditLogs(50));

class AuditFraudPage extends ConsumerWidget {
  const AuditFraudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frauds = ref.watch(fraudProvider);
    final audits = ref.watch(auditProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          // HEADER FRAUD
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.security, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              const Text('Fraud Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 16)),
              const Spacer(),
              frauds.when(data: (l) => Chip(label: Text('${l.length} Active', style: const TextStyle(fontSize: 11)), backgroundColor: l.isEmpty? Colors.green.shade100 : Colors.red.shade100), loading: () => const SizedBox(), error: (_,__)=> const SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          frauds.when(
            data: (list) {
              if(list.isEmpty) return GlassCard(child: Row(children: const [Icon(Icons.verified_user_outlined, color: Colors.green), SizedBox(width: 10), Text('Tidak ada indikasi fraud, sistem aman.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12))]));
              return Column(
                children: list.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: f.severity == 'merah'? Colors.red : Colors.orange, shape: BoxShape.circle), child: Icon(f.severity == 'merah'? Icons.warning_rounded : Icons.info_rounded, color: Colors.white, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${f.fraudCategory.toUpperCase()} - ${f.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                        const SizedBox(height: 4),
                        Text('${f.detailAnalysis}', style: TextStyle(fontSize: 11, color: isDark? Colors.white70: Colors.black87)),
                        const SizedBox(height: 6),
                        Text('User: ${f.userId} | ${f.createdAt}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ])),
                    ]),
                  ),
                )).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e,s) => GlassCard(child: Text('Error $e')),
          ),

          const SizedBox(height: 24),
          const Text('Audit Logs Terbaru (50)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 16)),
          const SizedBox(height: 12),
          audits.when(
            data: (list) => Column(
              children: list.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: Center(child: Text(a.userRole[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${a.actionType} - ${a.userRole} (${a.userId})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins')),
                      Text('${a.description}', style: TextStyle(fontSize: 11, color: isDark? Colors.white70: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                    const SizedBox(width: 8),
                    Text('${a.createdAt.toString().substring(11,16)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                ),
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