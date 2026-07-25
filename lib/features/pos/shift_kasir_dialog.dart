// lib/features/pos/shift_kasir_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/format_rupiah.dart';
import '../auth/auth_provider.dart';

class ShiftKasirDialog extends ConsumerStatefulWidget {
  const ShiftKasirDialog({super.key});

  @override
  ConsumerState<ShiftKasirDialog> createState() => _ShiftKasirDialogState();
}

class _ShiftKasirDialogState extends ConsumerState<ShiftKasirDialog> {
  final _uangFisikCtrl = TextEditingController();
  final _alasanCtrl = TextEditingController();

  double _totalCashPenjualan = 0;
  double _totalNonCashPenjualan = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final modalAwal = authState.initialCash;
    final uangSeharusnya = modalAwal + _totalCashPenjualan;

    return AlertDialog(
      title: const Text('Tutup Shift Kasir & Rekonsiliasi Laci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Column(
                children: [
                  _rowInfo('Modal Awal Laci:', formatRupiah(modalAwal)),
                  _rowInfo('Penjualan Tunai (Cash):', formatRupiah(_totalCashPenjualan)),
                  _rowInfo('Penjualan Non-Cash (QRIS/Transfer):', formatRupiah(_totalNonCashPenjualan)),
                  const Divider(),
                  _rowInfo('Uang Seharusnya di Laci:', formatRupiah(uangSeharusnya), isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uangFisikCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Uang Fisik Hasil Hitung Laci', prefixText: 'Rp ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _alasanCtrl,
              decoration: const InputDecoration(labelText: 'Catatan / Alasan jika ada selisih', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
          onPressed: () {
            ref.read(authProvider.notifier).tutupKasir();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift Kasir Berhasil Ditutup & Dicetak.')));
          },
          child: const Text('TUTUP KASIR', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _rowInfo(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
