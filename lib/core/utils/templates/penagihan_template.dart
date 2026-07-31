import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struk_components.dart';
import 'struk_dto.dart';

// ===========================================================================
// TEMPLATE 1: PENAGIHAN LUNAS (CASH / FULL PAYMENT)
// ===========================================================================
class PenagihanLunasTemplate extends StatelessWidget {
  final PenagihanLunasDTO data;

  const PenagihanLunasTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StrukHeader("BUKTI PEMBAYARAN LUNAS"),
        const StrukInfoText("UD. PUTRA SURABAYA"),
        const StrukDivider(),

        StrukInfoText("No Faktur: ${data.invoiceId}"),
        StrukInfoText("Pelanggan: ${data.customerName}"),
        StrukInfoText("Tgl Bayar: ${dateFmt.format(data.paymentDate)}"),
        const StrukDivider(),

        StrukRow("TOTAL DIBAYAR:", currency.format(data.totalPaid), isBold: true),
        
        const SizedBox(height: 12),
        const StrukStatusTag(status: "LUNAS", isUnpaid: false),

        const SizedBox(height: 20),
        const StrukInfoText("Terima kasih atas pembayaran Anda."),
        const SizedBox(height: 10), // Padding aman pemotong printer thermal
      ],
    );
  }
}

// ===========================================================================
// TEMPLATE 2: PENAGIHAN SISTEM TITIP (CICILAN / TEMPO)
// ===========================================================================
class PenagihanTitipTemplate extends StatelessWidget {
  final PenagihanDTO data;

  const PenagihanTitipTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final historyDateFmt = DateFormat('dd/MM/yy HH:mm');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StrukHeader("BUKTI ANGSURAN / TITIP"),
        const StrukInfoText("UD. PUTRA SURABAYA"),
        const StrukDivider(),

        StrukInfoText("No Faktur: ${data.invoiceId}"),
        StrukInfoText("Pelanggan: ${data.customerName}"),
        StrukInfoText("Tgl Bayar: ${dateFmt.format(data.paymentDate)}"),
        const StrukDivider(),

        StrukRow("TOTAL PIUTANG:", currency.format(data.totalDebt)),
        StrukRow("BAYAR SEKARANG:", currency.format(data.currentPayment), isBold: true),
        StrukRow("SISA PIUTANG:", currency.format(data.remainingDebt), isBold: true),

        if (data.history.isNotEmpty) ...[
          const StrukDivider(),
          const StrukInfoText("RIWAYAT ANGSURAN:"),
          const SizedBox(height: 4),
          ...data.history.map((h) => StrukRow(
            historyDateFmt.format(h.date), 
            currency.format(h.amount),
          )),
        ],

        const SizedBox(height: 12),
        if (data.remainingDebt > 0)
          const StrukStatusTag(status: "BELUM LUNAS", isUnpaid: true)
        else
          const StrukStatusTag(status: "LUNAS", isUnpaid: false),

        const SizedBox(height: 20),
        const StrukInfoText("Simpan struk ini sebagai bukti pembayaran sah."),
        const SizedBox(height: 10), // Padding aman pemotong printer thermal
      ],
    );
  }
}
