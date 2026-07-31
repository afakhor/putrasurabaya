import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'struk_dto.dart';
import '../struk_components.dart';

class PosReceiptTemplate extends StatelessWidget {
  final PosReceiptDTO data;

  const PosReceiptTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Pastikan rata tengah
      children: [
        const StrukHeader("UD. PUTRA SURABAYA"),
        const StrukInfoText("Jl. Surabaya - Sidoarjo"),
        
        // Metadata Transaksi
        const StrukDivider(),
        StrukInfoText("ID: ${data.invoiceId}"),
        StrukInfoText("Tgl: ${dateFmt.format(data.transactionDate)}"),
        const StrukDivider(),

        // Loop Item
        ...data.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal)
        )),

        const StrukDivider(),

        // Summary
        StrukRow("TOTAL:", currencyFormatter.format(data.total), isBold: true),

        // Logic Pembayaran
        if (data.paymentMethod == 'cash') ...[
          StrukRow("BAYAR:", currencyFormatter.format(data.paidAmount)),
          StrukRow("KEMBALI:", currencyFormatter.format(data.change)),
        ] else if (data.paymentMethod == 'tempo') ...[
          StrukRow("DP/UM:", currencyFormatter.format(data.paidAmount)),
          const StrukStatusTag(status: "PIUTANG", isUnpaid: true),
          StrukRow("SISA HUTANG:", currencyFormatter.format(data.debt), isBold: true),
        ],

        const SizedBox(height: 20), // Padding lebih lega untuk printer thermal
        const StrukInfoText("Terima Kasih atas Kunjungan Anda"),
        const SizedBox(height: 10), // Memberi ruang potong kertas
      ],
    );
  }
}
