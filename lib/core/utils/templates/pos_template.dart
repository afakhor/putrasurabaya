import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/features/pos/pos_state.dart'; // Sesuaikan path model Anda
import '../struk_components.dart';

class PosReceiptTemplate extends StatelessWidget {
  final PosCartState cart;

  const PosReceiptTemplate({required this.cart, super.key});

  @override
  Widget build(BuildContext context) {
    // Formatter untuk mata uang
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrukHeader("UD. PUTRA SURABAYA"),
        const StrukInfoText("Jl. Surabaya - Sidoarjo"),
        const StrukInfoText("Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
        const StrukDivider(),
        
        // Loop Daftar Item
        ...cart.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal)
        )),
        
        const StrukDivider(),
        
        // Ringkasan Pembayaran
        StrukRow("TOTAL:", currencyFormatter.format(cart.total), isBold: true),
        
        if (cart.paymentMethod == 'cash') ...[
          StrukRow("BAYAR:", currencyFormatter.format(cart.paidAmount)),
          StrukRow("KEMBALI:", currencyFormatter.format(cart.change)),
        ] else if (cart.paymentMethod == 'tempo') ...[
          StrukRow("DP/UM:", currencyFormatter.format(cart.paidAmount)),
          const StrukStatusTag(status: "PIUTANG", isUnpaid: true),
          StrukRow("SISA HUTANG:", currencyFormatter.format(cart.debt), isBold: true),
        ],
        
        const SizedBox(height: 10),
        const StrukInfoText("Terima Kasih atas Kunjungan Anda"),
      ],
    );
  }
}
