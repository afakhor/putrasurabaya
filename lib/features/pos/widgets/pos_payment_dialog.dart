import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ud_putra_kasir/features/pos/pos_cart_provider.dart';

class PosPaymentDialog extends ConsumerStatefulWidget {
  final Function(PosCartState cartSnapshot)? onSuccess;

  const PosPaymentDialog({super.key, this.onSuccess});

  @override
  ConsumerState<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends ConsumerState<PosPaymentDialog> {
  late TextEditingController _payController;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final initialPaid = ref.read(posCartProvider).paidAmount;
    _payController = TextEditingController(
      text: initialPaid > 0 ? initialPaid.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _payController.dispose();
    super.dispose();
  }

  void _setNominal(double amount) {
    _payController.text = amount.toStringAsFixed(0);
    ref.read(posCartProvider.notifier).setPaidAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAR HEADER MODAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pembayaran Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // RINGKASAN TOTAL
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormatter.format(cartState.total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A65A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // PILIHAN METODE PEMBAYARAN
            const Text('Metode Bayar', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('Tunai'), icon: Icon(Icons.money)),
                ButtonSegment(value: 'qris', label: Text('QRIS'), icon: Icon(Icons.qr_code)),
                ButtonSegment(value: 'tempo', label: Text('Tempo'), icon: Icon(Icons.history)),
              ],
              selected: {cartState.paymentMethod},
              onSelectionChanged: (selected) {
                final method = selected.first;
                cartNotifier.setPaymentMethod(method);
                if (method == 'qris') {
                  _setNominal(cartState.total); // QRIS otomatis pas
                }
              },
            ),
            const SizedBox(height: 16),

            // 1. OPSI TUNAI (CASH)
            if (cartState.paymentMethod == 'cash') ...[
              TextField(
                controller: _payController,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Uang Diterima',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final amount = double.tryParse(val) ?? 0;
                  cartNotifier.setPaidAmount(amount);
                },
              ),
              const SizedBox(height: 8),

              // TOMBOL QUICK CASH (UANG PAS, 20K, 50K, 100K)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Uang Pas'),
                    onPressed: () => _setNominal(cartState.total),
                  ),
                  ActionChip(
                    label: const Text('Rp 20.000'),
                    onPressed: () => _setNominal(20000),
                  ),
                  ActionChip(
                    label: const Text('Rp 50.000'),
                    onPressed: () => _setNominal(50000),
                  ),
                  ActionChip(
                    label: const Text('Rp 100.000'),
                    onPressed: () => _setNominal(100000),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // STATUS KEMBALIAN / KURANG
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cartState.paidAmount >= cartState.total ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cartState.paidAmount >= cartState.total
                      ? 'Kembali: ${currencyFormatter.format(cartState.change)}'
                      : 'Kurang: ${currencyFormatter.format(cartState.total - cartState.paidAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cartState.paidAmount >= cartState.total ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],

            // 2. OPSI TEMPO / PIUTANG
            if (cartState.paymentMethod == 'tempo') ...[
              ListTile(
                dense: true,
                tileColor: Colors.amber.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: Text(
                  cartState.selectedCustomer == null
                      ? 'Pilih Customer (Wajib untuk Tempo)'
                      : 'Pelanggan: ${cartState.selectedCustomer!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.person_search),
                onTap: () {
                  // Simulasi Pilihan Customer
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _payController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Uang Muka / DP (Kosongkan jika Rp 0)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final amount = double.tryParse(val) ?? 0;
                  cartNotifier.setPaidAmount(amount);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Sisa Utang/Piutang: ${currencyFormatter.format(cartState.debt)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],

            // 3. OPSI QRIS
            if (cartState.paymentMethod == 'qris') ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                      SizedBox(height: 8),
                      Text('Tunjukkan QRIS ke Pembeli', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // TOMBOL EKSEKUSI CHECKOUT
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A65A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  // Validasi pembayaran tunai yang kurang
                  if (cartState.paymentMethod == 'cash' && cartState.paidAmount < cartState.total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nominal pembayaran tunai masih kurang!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  // 1. Simpan snapshot data keranjang sebelum dihapus oleh checkout()
                  final cartSnapshot = ref.read(posCartProvider);

                  // 2. Eksekusi Checkout via PosCartNotifier
                  final success = await cartNotifier.checkout(
                    salesId: 'SALES-01',
                    shiftId: 'SHIFT-01',
                  );

                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context); // Tutup dialog
                      // 3. Panggil callback onSuccess jika dikirim dari pos_page / pos_cart_widget
                      widget.onSuccess?.call(cartSnapshot);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan transaksi'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('PROSES & SIMPAN TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
