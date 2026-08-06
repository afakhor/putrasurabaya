import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';

final fraudProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).auditLogDao.watchActiveFraudAlerts());
final auditProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).auditLogDao.watchRecentAuditLogs(limit: 100));

class AuditFraudPage extends ConsumerWidget {
  const AuditFraudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frauds = ref.watch(fraudProvider);
    final audits = ref.watch(auditProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTabController(
        length: 2,
        child: Column(children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const TabBar(labelColor: Colors.black, tabs: [
              Tab(icon: Icon(Icons.security, color: Colors.red), text: 'FRAUD ALERTS'),
              Tab(icon: Icon(Icons.video_camera_back, color: Colors.black), text: 'CCTV AUDIT LOG'),
            ]),
          ),
          Expanded(child: TabBarView(children: [
            // TAB 1 FRAUD
            ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.security, color: Colors.white, size: 18)),
                  const SizedBox(width: 10),
                  const Text('Fraud Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 16)),
                  const Spacer(),
                  frauds.when(
                    data: (l) => Chip(label: Text(l.length.toString() + ' Active', style: const TextStyle(fontSize: 11)), backgroundColor: l.isEmpty? Colors.green.shade100 : Colors.red.shade100),
                    loading: () => const SizedBox(),
                    error: (_,__)=> const SizedBox(),
                  ),
                ]),
                const SizedBox(height: 12),
                frauds.when(
                  data: (list) {
                    if(list.isEmpty) {
                      return GlassCard(child: Row(children: const [Icon(Icons.verified_user_outlined, color: Colors.green), SizedBox(width: 10), Text('Tidak ada indikasi fraud, sistem aman.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12))]));
                    }
                    return Column(
                      children: list.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: f.severity == 'merah'? Colors.red : Colors.orange, shape: BoxShape.circle), child: Icon(f.severity == 'merah'? Icons.warning_rounded : Icons.info_rounded, color: Colors.white, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.fraudCategory.toUpperCase() + ' - ' + f.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                                const SizedBox(height: 4),
                                Text(f.detailAnalysis, style: TextStyle(fontSize: 11, color: isDark? Colors.white70: Colors.black87)),
                                const SizedBox(height: 6),
                                Text('User: ' + f.userId + ' | ' + f.createdAt.toString().substring(0,16), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ])),
                            ]),
                            if(f.auditLogId!=null) FutureBuilder(
                              future: ref.read(localDatabaseProvider).auditLogDao.getLogsByReference(f.auditLogId!),
                              builder: (ctx,snap){
                                if(!snap.hasData || snap.data!.isEmpty) return const SizedBox();
                                final log=snap.data!.first;
                                return Container(margin: const EdgeInsets.only(top:8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('CCTV:', style: TextStyle(fontSize:9, fontWeight: FontWeight.bold)),
                                  Text('OLD: ' + (log.oldValue??'-'), style: const TextStyle(fontSize:9, color: Colors.red)),
                                  Text('NEW: ' + (log.newValue??'-'), style: const TextStyle(fontSize:9, color: Colors.green)),
                                ]));
                              },
                            ),
                            Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.check_circle, size:16, color: Colors.green), label: const Text('Resolve', style: TextStyle(fontSize:11)), onPressed: () async {
                              await ref.read(localDatabaseProvider).auditLogDao.resolveFraudAlert(alertId: f.id, ownerUserId: 'owner-01');
                            })),
                          ]),
                        ),
                      )).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e,s) => GlassCard(child: Text('Error ' + e.toString())),
                ),
              ],
            ),
            // TAB 2 AUDIT LOG
            audits.when(
              data: (list) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(12,0,12,100),
                itemCount: list.length,
                itemBuilder: (c,i){
                  final a=list[i];
                  String oldStr = '-';
                  String newStr = '-';
                  try { oldStr = a.oldValue!=null? jsonDecode(a.oldValue!).toString() : '-'; } catch(_){ oldStr = a.oldValue?? '-'; }
                  try { newStr = a.newValue!=null? jsonDecode(a.newValue!).toString() : '-'; } catch(_){ newStr = a.newValue?? '-'; }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        leading: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: Center(child: Text(a.userRole[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                        title: Text(a.actionType + ' - ' + a.userRole + ' (' + a.userId + ')', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins')),
                        subtitle: Text(a.description, style: TextStyle(fontSize: 11, color: isDark? Colors.white70: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(a.createdAt.toString().substring(11,16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        children: [
                          Container(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Ref: ' + (a.referenceId??'-'), style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            const SizedBox(height:8),
                            Row(children: [
                              Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('OLD VALUE', style: TextStyle(fontSize:9, fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(height:4), Text(oldStr, style: const TextStyle(fontSize:10, fontFamily: 'Poppins'))]))),
                              const SizedBox(width:8),
                              Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('NEW VALUE', style: TextStyle(fontSize:9, fontWeight: FontWeight.bold, color: Colors.green)), const SizedBox(height:4), Text(newStr, style: const TextStyle(fontSize:10, fontFamily: 'Poppins'))]))),
                            ]),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e,s) => Text('Error ' + e.toString()),
            ),
          ])),
        ]),
      ),
    );
  }
}