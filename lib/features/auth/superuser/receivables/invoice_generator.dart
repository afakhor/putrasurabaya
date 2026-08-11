import 'dart:math';

class InvoiceGenerator {
  static final _rand = Random();
  static String _rand3() => _rand.nextInt(999).toString().padLeft(3, '0');
  static String _rand4() => _rand.nextInt(9999).toString().padLeft(4, '0');
  
  static String _nowDMY() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2,'0')}${now.month.toString().padLeft(2,'0')}${now.year.toString().substring(2)}";
  }
  
  static String _nowHMS() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}";
  }

  static String _short(String id, int len) {
    if (id.isEmpty) return 'X'.padRight(len, 'X');
    final clean = id.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    if (clean.length >= len) return clean.substring(clean.length - len);
    return clean.padRight(len, 'X');
  }

  static String _nameShort(String name, int len) {
    if (name.isEmpty) return 'CUST'.substring(0, len);
    final clean = name.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    if (clean.isEmpty) return 'CUST';
    if (clean.length >= len) return clean.substring(0, len);
    return clean.padRight(len, 'X');
  }

  static String generateReceivableNo({required String customerId, required String customerName}) {
    return "INV-${_nowDMY()}-${_short(customerId, 4)}-${_nameShort(customerName, 4)}-${_nowHMS()}-${_rand3()}";
  }

  static String generatePayableNo({required String supplierId, required String supplierName}) {
    return "HUT-${_nowDMY()}-${_short(supplierId, 4)}-${_nameShort(supplierName, 4)}-${_nowHMS()}-${_rand4()}";
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