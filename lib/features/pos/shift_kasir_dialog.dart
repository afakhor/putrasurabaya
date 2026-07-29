import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/utils/format_rupiah.dart';
import 'package:ud_putra_kasir/features/auth/auth_provider.dart';

/// Provider untuk menghitung ringkasan transaksi per shift
final shiftSummaryProvider = FutureProvider.family<Map<String, double>, String?>((ref, shiftId) async {
  if (shiftId == null) return {'cash': 0.0, 'nonCash': 0.0};

  final db = ref.watch(localDatabaseProvider);
  final listTrx = await (db.select(db.transactions)
        ..where((tbl) => tbl.shiftId.equals(shiftId)))
      .get();

  double cashSum = 0;
  double nonCashSum = 0;

  for (final trx in listTrx) {
    final method = trx.paymentMethod.toLowerCase();
    if (method == 'cash' || method == 'tunai') {
      // Gunakan grandTotal (atau net cash), bukan trx.paid
      cashSum += trx.grandTotal; 
    } else {
      nonCashSum += trx.grandTotal;
    }
  }

  return {'cash': cashSum, 'nonCash': nonCashSum};
});

class ShiftKasirDialog extends ConsumerStatefulWidget {
  const ShiftKasirDialog({super.key});

  @override
  ConsumerState<ShiftKasirDialog> createState() => _ShiftKasirDialogState();
}

class _ShiftKasirDialogState extends ConsumerState<ShiftKasirDialog> {
  final _uangFisikCtrl = TextEditingController();
  final _alasanCtrl = TextEditingController();

  double _uangFisik = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _uangFisikCtrl.addListener(_onUangFisikChanged);
  }

  void _onUangFisikChanged() {
    final cleanVal = _uangFisikCtrl.text.replaceAll('.', '').replaceAll(',', '');
    setState(() {
      _uangFisik = double.tryParse(cleanVal) ?? 0;
    });
  }

  @override
  void dispose() {
    _uangFisikCtrl.removeListener(_onUangFisikChanged);
    _uangFisikCtrl.dispose();
    _alasanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final modalAwal = authState.initialCash;
    final activeShiftId = authState.activeShiftId;

    final shiftSummaryAsync = ref.watch(shiftSummaryProvider(activeShiftId));

    return AlertDialog(
      title: const Text(
        'Tutup Shift Kasir & Rekonsiliasi Laci',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: shiftSummaryAsync.when(
          loading: () => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Gagal memuat data shift: $err'),
          ),
          data: (data) {
            final totalCashPenjualan = data['cash'] ?? 0.0;
            final totalNonCashPenjualan = data['nonCash'] ?? 0.0;

            final uangSeharusnya = modalAwal + totalCashPenjualan;
            final selisih = _uangFisik - uangSeharusnya;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Ringkasan Sistem
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _rowInfo('Modal Awal Laci:', formatRupiah(modalAwal)),
                      _rowInfo('Penjualan Tunai (Cash):', formatRupiah(totalCashPenjualan)),
                      _rowInfo('Penjualan Non-Cash (QRIS/EDC):', formatRupiah(totalNonCashPenjualan)),
                      const Divider(height: 16),
                      _rowInfo(
                        'Uang Seharusnya di Laci:',
                        formatRupiah(uangSeharusnya),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Input Uang Fisik Hasil Hitung
                TextField(
                  controller: _uangFisikCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Uang Fisik di Laci (Hasil Hitung)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Card Indicators Selisih Real-time
                if (_uangFisikCtrl.text.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selisih == 0
                          ? Colors.green.shade50
                          : (selisih < 0 ? Colors.red.shade50 : Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selisih == 0
                            ? Colors.green
                            : (selisih < 0 ? Colors.red : Colors.orange),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selisih == 0
                              ? 'Status: COCOK (PAS)'
                              : (selisih < 0 ? 'Status: MINUS (KURANG)' : 'Status: SURPLUS (LEBIH)'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selisih == 0
                                ? Colors.green.shade900
                                : (selisih < 0 ? Colors.red.shade900 : Colors.orange.shade900),
                          ),
                        ),
                        Text(
                          formatRupiah(selisih.abs()),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selisih == 0
                                ? Colors.green.shade900
                                : (selisih < 0 ? Colors.red.shade900 : Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Input Catatan / Alasan
                TextField(
                  controller: _alasanCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: selisih != 0
                        ? 'Alasan Selisih (Wajib diisi)*'
                        : 'Catatan Penutupan Shift (Opsional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isSubmitting ? null : () => _submitTutupKasir(shiftSummaryAsync.value),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('TUTUP KASIR', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _submitTutupKasir(Map<String, double>? summaryData) async {
    if (_uangFisikCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah uang fisik di laci terlebih dahulu!')),
      );
      return;
    }

    if (summaryData == null) return;

    final authState = ref.read(authProvider);
    final modalAwal = authState.initialCash;
    final totalCash = summaryData['cash'] ?? 0.0;
    final uangSeharusnya = modalAwal + totalCash;
    final selisih = _uangFisik - uangSeharusnya;

    if (selisih != 0 && _alasanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terdapat selisih laci. Alasan wajib diisi!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authProvider.notifier).tutupKasir(
            actualCash: _uangFisik,
            expectedCash: uangSeharusnya,
            cashDifference: selisih,
            notes: _alasanCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift Kasir Berhasil Ditutup & Rekap Dicetak.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menutup shift: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _rowInfo(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
