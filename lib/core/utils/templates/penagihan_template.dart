// penagihan_template.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struk_components.dart';
import 'struk_dto.dart'; // Import DTO yang baru kita buat

// ===========================================================================
// TEMPLATE 1: PENAGIHAN LUNAS (CASH)
// ===========================================================================
class PenagihanLunasTemplate extends StatelessWidget {
  final double total;
  final String invoiceId;

  const PenagihanLunasTemplate({required this.total, required this.invoiceId, super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrukHeader("BUKTI PEMBAYARAN"),
        StrukInfoText("ID: $invoiceId"),
        const StrukDivider(),
        StrukRow("TOTAL DIBAYAR:", currency.format(total), isBold: true),
        const SizedBox(height: 10),
        const StrukStatusTag(status: "LUNAS", isUnpaid: false),
      ],
    );
  }
}

// ===========================================================================
// TEMPLATE 2: PENAGIHAN SISTEM TITIP (CICILAN)
// ===========================================================================
class PenagihanTitipTemplate extends StatelessWidget {
  final PenagihanDTO data; // Menggunakan DTO, bukan Data Class Database

  const PenagihanTitipTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrukHeader("DETAIL PENAGIHAN"),
        StrukInfoText("ID Faktur: ${data.invoiceId}"),
        const StrukDivider(),
        
        StrukRow("TOTAL HUTANG:", currency.format(data.totalDebt)),
        StrukRow("BAYAR SEKARANG:", currency.format(data.currentPayment), isBold: true),
        StrukRow("SISA HUTANG:", currency.format(data.remainingDebt), isBold: true),
        
        const StrukDivider(),
        const StrukInfoText("RIWAYAT PEMBAYARAN:"),
        ...data.history.map((h) => StrukRow(
          dateFormat.format(h.date), 
          currency.format(h.amount)
        )),
        
        const SizedBox(height: 10),
        if (data.remainingDebt > 0)
          const StrukStatusTag(status: "BELUM LUNAS", isUnpaid: true)
        else
          const StrukStatusTag(status: "LUNAS", isUnpaid: false),
      ],
    );
  }
}
