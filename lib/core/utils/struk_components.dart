import 'package:flutter/material.dart';

// ===========================================================================
// 1. STRUK HEADER: Judul Struk
// ===========================================================================
class StrukHeader extends StatelessWidget {
  final String title;
  const StrukHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

// ===========================================================================
// 2. STRUK ROW: Baris Item (Nama Produk & Harga)
// ===========================================================================
class StrukRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double fontSize;

  const StrukRow(
    this.label, 
    this.value, {
    this.isBold = false, 
    this.fontSize = 12, 
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          ),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        ],
      ),
    );
  }
}

// ===========================================================================
// 3. STRUK DIVIDER: Pemisah
// ===========================================================================
class StrukDivider extends StatelessWidget {
  const StrukDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Divider(color: Colors.grey, height: 1, thickness: 1),
    );
  }
}

// ===========================================================================
// 4. STRUK STATUS TAG: Label Status (LUNAS / UNPAID)
// ===========================================================================
class StrukStatusTag extends StatelessWidget {
  final String status;
  final bool isUnpaid;

  const StrukStatusTag({required this.status, this.isUnpaid = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isUnpaid ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isUnpaid ? Colors.red.shade900 : Colors.green.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ===========================================================================
// 5. STRUK INFO TEXT: Info Tambahan (Tanggal, No. Faktur)
// ===========================================================================
class StrukInfoText extends StatelessWidget {
  final String text;
  const StrukInfoText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87));
  }
}
