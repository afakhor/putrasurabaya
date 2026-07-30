import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'struk_dto.dart'; // Import DTO Anda
import '../struk_components.dart';

class FakturUnpaidTemplate extends StatelessWidget {
  // Template menerima data "mentah" yang sudah disiapkan, bukan model kompleks
  final List<ReceiptItemDTO> items;
  final String invoiceId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final double total;

  const FakturUnpaidTemplate({
    required this.items,
    required this.invoiceId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.total,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StrukHeader("FAKTUR PENJUALAN"),
        
        // Informasi Faktur
        StrukInfoText("No Faktur: $invoiceId"),
        StrukInfoText("Kepada: $customerName"),
        StrukInfoText("Tgl: ${dateFormatter.format(date)}"),
        
        const StrukDivider(),
        
        // Loop Item menggunakan DTO
        ...items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal)
        )),
        
        const StrukDivider(),
        
        // Total Harga
        StrukRow(
          "TOTAL TAGIHAN:", 
          currencyFormatter.format(total), 
          isBold: true,
          fontSize: 14 
        ),
        
        const SizedBox(height: 8),
        
        // Status & Jatuh Tempo
        const StrukStatusTag(status: "UNPAID", isUnpaid: true),
        
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "Jatuh Tempo: ${dateFormatter.format(dueDate)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        
        const SizedBox(height: 15),
        const StrukInfoText("Terima kasih atas kepercayaan Anda."),
      ],
    );
  }
}
