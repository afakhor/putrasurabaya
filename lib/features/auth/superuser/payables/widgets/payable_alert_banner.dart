import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class PayableAlertBanner extends ConsumerWidget {
  const PayableAlertBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(localDatabaseProvider);
    return FutureBuilder<List<String>>(
      future: db.payablesDao.getLevel1MerahAlerts(),
      builder: (c, snap){
        if(!snap.hasData || snap.data!.isEmpty) return const SizedBox();
        final alerts = snap.data!;
        return Container(
          width: double.infinity,
          color: Colors.red[100],
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: alerts.map((e)=> Text('🔴 $e', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))).toList()),
        );
      },
    );
  }
}