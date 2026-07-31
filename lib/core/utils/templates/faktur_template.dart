import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struk_components.dart';
import 'struk_dto.dart';

class FakturUnpaidTemplate extends StatelessWidget {
  final FakturDTO data;

  const FakturUnpaidTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StrukHeader("FAKTUR PENJUALAN"),
        const StrukInfoText("UD. PUTRA SURABAYA"),
        const StrukDivider(),

        // Informasi Faktur
        StrukInfoText("No Faktur: ${data.invoiceId}"),
        StrukInfoText("Kepada: ${data.customerName}"),
        StrukInfoText("Tgl: ${dateFormatter.format(data.date)}"),

        const StrukDivider(),

        // Loop Item menggunakan DTO
        ...data.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal),
        )),

        const StrukDivider(),

        // Total Tagihan & Detail Pembayaran
        StrukRow(
          "TOTAL TAGIHAN:", 
          currencyFormatter.format(data.total), 
          isBold: true,
          fontSize: 14,
        ),

        if (data.paidAmount > 0) ...[
          StrukRow("DP / UM:", currencyFormatter.format(data.paidAmount)),
          StrukRow(
            "SISA TAGIHAN:", 
            currencyFormatter.format(data.remainingDebt), 
            isBold: true,
          ),
        ],

        const SizedBox(height: 10),

        // Status & Jatuh Tempo
        const StrukStatusTag(status: "UNPAID / TEMPO", isUnpaid: true),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "Jatuh Tempo: ${dateFormatter.format(data.dueDate)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),

        const SizedBox(height: 20),
        const StrukInfoText("Terima kasih atas kepercayaan Anda."),
        const SizedBox(height: 10), // Padding aman pemotong printer thermal
      ],
    );
  }
}
