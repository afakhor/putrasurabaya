import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/config.dart';
import '../../../core/database/local_database.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          const Text('Laporan & Tutup Buku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          GlassCard(onTap: (){}, child: const ListTile(leading: Icon(Icons.today_rounded), title: Text('Laporan Harian', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), subtitle: Text('Omset, Laba Rugi, Transaksi Void'), trailing: Icon(Icons.chevron_right_rounded))),
          GlassCard(onTap: (){}, child: const ListTile(leading: Icon(Icons.calendar_month_rounded), title: Text('Laporan Bulanan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), subtitle: Text('Rekap piutang, hutang, stok'), trailing: Icon(Icons.chevron_right_rounded))),
          GlassCard(onTap: (){}, child: const ListTile(leading: Icon(Icons.lock_rounded, color: Colors.red), title: Text('Tutup Buku', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), subtitle: Text('Kunci periode & kirim ke owner'), trailing: Icon(Icons.chevron_right_rounded))),
        ],
      ),
    );
  }
}