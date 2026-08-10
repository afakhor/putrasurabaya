import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart' as app_config;
import 'cctv_analytics_page.dart';

final fraudProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).auditLogDao.watchActiveFraudAlerts());
final auditProvider = StreamProvider((ref) => ref.watch(localDatabaseProvider).auditLogDao.watchRecentAuditLogs(limit: 100));

class AuditFraudPage extends ConsumerWidget {
  const AuditFraudPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTabController(
        length: 2,
        child: Column(children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const TabBar(
              labelColor: Colors.black,
              labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 11),
              tabs: [
                Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'FRAUD ALERTS'),
                Tab(icon: Icon(Icons.remove_red_eye_rounded, size: 18), text: 'MATA ELANG'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [
              FraudListView(),
              CctvAnalyticsPage(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class FraudListView extends ConsumerWidget {
  const FraudListView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frauds = ref.watch(fraudProvider);
    return frauds.when(
      data: (list) {
        if (list.isEmpty) return Center(child: app_config.GlassCard(child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.verified_user, color: Colors.green), SizedBox(width:8), Text('Aman - Tidak ada fraud')])));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12,0,12,100),
          itemCount: list.length,
          itemBuilder: (c,i){
            final f = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom:8),
              child: app_config.GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(backgroundColor: (f.severity)=='merah'? Colors.red : Colors.orange, radius: 14, child: const Icon(Icons.warning, size:14, color: Colors.white)),
                    const SizedBox(width:8),
                    Expanded(child: Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12))),
                    Chip(label: Text('${list.length} Active', style: const TextStyle(fontSize:9))),
                  ]),
                  const SizedBox(height:4),
                  Text(f.detailAnalysis??'', style: const TextStyle(fontSize:11)),
                  Text('User: ${f.userId}', style: const TextStyle(fontSize:9, color: Colors.grey)),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () async { await ref.read(localDatabaseProvider).auditLogDao.resolveAlert(f.id, 'owner-01'); }, child: const Text('Resolve'))),
                ]),
              ),
            );
          },
        );
      },
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text(e.toString())),
    );
  }
}

class AuditListView extends ConsumerWidget {
  const AuditListView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audits = ref.watch(auditProvider);
    return audits.when(
      data: (list) => ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,100), itemCount: list.length, itemBuilder: (c,i){
        final a = list[i];
        String oldV = a.oldValue?? '-'; String newV = a.newValue?? '-';
        try { oldV = jsonDecode(oldV).toString(); } catch(_){}
        try { newV = jsonDecode(newV).toString(); } catch(_){}
        return Padding(padding: const EdgeInsets.only(bottom:8), child: app_config.GlassCard(padding: const EdgeInsets.all(10), child: ExpansionTile(
          title: Text('${a.actionType} - ${a.userRole}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
          subtitle: Text(a.description??'', style: const TextStyle(fontSize:11)),
          children: [
            Container(padding: const EdgeInsets.all(8), color: Colors.red[50], child: Text('OLD: $oldV', style: const TextStyle(fontSize:10, color: Colors.red))),
            Container(padding: const EdgeInsets.all(8), color: Colors.green[50], child: Text('NEW: $newV', style: const TextStyle(fontSize:10, color: Colors.green))),
          ],
        )));
      }),
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text(e.toString())),
    );
  }
}