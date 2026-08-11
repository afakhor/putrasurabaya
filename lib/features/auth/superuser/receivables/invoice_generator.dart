import 'dart:math';

class InvoiceGenerator {
  static String generateReceivableNo({required String customerId, required String customerName}) {
    final now = DateTime.now();
    final dmy = "${now.day.toString().padLeft(2,'0')}${now.month.toString().padLeft(2,'0')}${now.year.toString().substring(2)}";
    final custShort = customerId.length >=4 ? customerId.substring(customerId.length-4).toUpperCase() : customerId.toUpperCase();
    final nameClean = customerName.replaceAll(' ', '').toUpperCase();
    final nameShort = nameClean.length >=4 ? nameClean.substring(0,4) : nameClean.padRight(4,'X');
    final time = "${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}";
    final rand = Random().nextInt(999).toString().padLeft(3,'0');
    // Hasil: INV-110826-CUS8-KURN-143022-582
    return "INV-$dmy-$custShort-$nameShort-$time-$rand";
  }

  static int hitungUmurNgendap(DateTime invoiceDate) {
    return DateTime.now().difference(invoiceDate).inDays;
  }

  static String warnaNgendap(int umur) {
    if (umur > 90) return 'MERAH';
    if (umur > 60) return 'ORANGE';
    if (umur > 30) return 'KUNING';
    return 'HIJAU';
  }
}