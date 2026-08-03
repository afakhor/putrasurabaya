import 'package:flutter/material.dart';
import '../../../core/utils/config.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(padding: const EdgeInsets.fromLTRB(12,12,12,100), children: [
        const Text('Laporan & Tutup Buku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
        const SizedBox(height: 12),
        GlassCard(onTap: (){}, child: ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Laporan Harian'), subtitle: const Text('Rekap omset, laba, transaksi'), trailing: const Icon(Icons.chevron_right))),
        GlassCard(onTap: (){}, child: ListTile(leading: const Icon(Icons.book), title: const Text('Tutup Buku Bulanan'), subtitle: const Text('Kunci transaksi & audit'), trailing: const Icon(Icons.chevron_right))),
      ]),
    );
  }
}