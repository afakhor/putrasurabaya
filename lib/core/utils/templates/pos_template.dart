import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'struk_dto.dart'; // Import DTO
import '../struk_components.dart';

class PosReceiptTemplate extends StatelessWidget {
  final PosReceiptDTO data; // Menerima DTO

  const PosReceiptTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
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
        StrukInfoText("Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
        const StrukDivider(),

        // Loop Item menggunakan DTO
        ...data.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal)
        )),

        const StrukDivider(),

        // Ringkasan Pembayaran
        StrukRow("TOTAL:", currencyFormatter.format(data.total), isBold: true),

        if (data.paymentMethod == 'cash') ...[
          StrukRow("BAYAR:", currencyFormatter.format(data.paidAmount)),
          StrukRow("KEMBALI:", currencyFormatter.format(data.change)),
        ] else if (data.paymentMethod == 'tempo') ...[
          StrukRow("DP/UM:", currencyFormatter.format(data.paidAmount)),
          const StrukStatusTag(status: "PIUTANG", isUnpaid: true),
          StrukRow("SISA HUTANG:", currencyFormatter.format(data.debt), isBold: true),
        ],

        const SizedBox(height: 10),
        const StrukInfoText("Terima Kasih atas Kunjungan Anda"),
      ],
    );
  }
}
