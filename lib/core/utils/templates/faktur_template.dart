import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Pastikan Anda mengimpor model Item Anda yang sesungguhnya di sini
// Contoh: import 'package:ud_putra_kasir/features/pos/pos_state.dart'; 
import '../struk_components.dart';

// 1. Model Faktur
class FakturData {
  final String invoiceId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final List<dynamic> items; // Jika memungkinkan, ganti 'dynamic' dengan model item Anda
  final double total;

  FakturData({
    required this.invoiceId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.total,
  });
}

// 2. Template Faktur
class FakturUnpaidTemplate extends StatelessWidget {
  final FakturData data;

  const FakturUnpaidTemplate({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StrukHeader("FAKTUR PENJUALAN"),
        
        // Informasi Faktur
        StrukInfoText("No Faktur: ${data.invoiceId}"),
        StrukInfoText("Kepada: ${data.customerName}"),
        StrukInfoText("Tgl: ${dateFormatter.format(data.date)}"),
        
        const StrukDivider(),
        
        // Loop Item
        // Pastikan 'it' memiliki properti productName, quantity, dan subtotal
        ...data.items.map((it) => StrukRow(
          "${it.productName} x ${it.quantity.toStringAsFixed(0)}", 
          currencyFormatter.format(it.subtotal)
        )),
        
        const StrukDivider(),
        
        // Total Harga
        StrukRow(
          "TOTAL TAGIHAN:", 
          currencyFormatter.format(data.total), 
          isBold: true,
          fontSize: 14 // Sedikit lebih besar agar menonjol
        ),
        
        const SizedBox(height: 8),
        
        // Status & Jatuh Tempo
        const StrukStatusTag(status: "UNPAID", isUnpaid: true),
        
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "Jatuh Tempo: ${dateFormatter.format(data.dueDate)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        
        const SizedBox(height: 15),
        const StrukInfoText("Terima kasih atas kepercayaan Anda."),
      ],
    );
  }
}
