import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struk_components.dart';
import 'struk_dto.dart';

class PosReceiptTemplate extends StatelessWidget {
  final PosReceiptDTO data;

  const PosReceiptTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrukHeader("UD. PUTRA SURABAYA"),
        const StrukInfoText("Jl. Surabaya - Sidoarjo"),
        StrukInfoText("Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
        const StrukDivider(),

        ...data.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currency.format(it.subtotal)
        )),

        const StrukDivider(),
        StrukRow("TOTAL:", currency.format(data.total), isBold: true),

        if (data.paymentMethod == 'cash') ...[
          StrukRow("BAYAR:", currency.format(data.paidAmount)),
          StrukRow("KEMBALI:", currency.format(data.change)),
        ] else if (data.paymentMethod == 'tempo') ...[
          StrukRow("DP/UM:", currency.format(data.paidAmount)),
          const StrukStatusTag(status: "PIUTANG", isUnpaid: true),
          StrukRow("SISA HUTANG:", currency.format(data.debt), isBold: true),
        ],
        
        const SizedBox(height: 10),
        const StrukInfoText("Terima Kasih atas Kunjungan Anda"),
      ],
    );
  }
}
