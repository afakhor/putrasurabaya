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
    final clean = name.replaceAll(RegExp(r'[^A-Z]'), '').toUpperCase();
    if (clean.isEmpty) return 'CUST';
    if (clean.length >= len) return clean.substring(0, len);
    return clean.padRight(len, 'X');
  }

  // === 1. PIUTANG CUSTOMER: INV-110826-CUS8-KURN-143022-582 ===
  static String generateReceivableNo({required String customerId, required String customerName}) {
    return "INV-${_nowDMY()}-${_short(customerId, 4)}-${_nameShort(customerName, 4)}-${_nowHMS()}-${_rand3()}";
  }

  // === 2. HUTANG SUPPLIER: HUT-110826-SUPP-ANUG-1430-1234 ===
  static String generatePayableNo({required String supplierId, required String supplierName}) {
    return "HUT-${_nowDMY()}-${_short(supplierId, 4)}-${_nameShort(supplierName, 4)}-${_nowHMS()}-${_rand4()}";
  }

  // === 3. PEMBELIAN KULAK: KULAK-110826-SUPP-001 ===
  static String generatePurchaseNo() {
    return "KULAK-${_nowDMY()}-${_rand4()}";
  }

  // === 4. PENJUALAN POS: JUAL-110826-143022-582 ===
  static String generateSalesNo() {
    return "JUAL-${_nowDMY()}-${_nowHMS()}-${_rand3()}";
  }

  // === 5. OPNAME: OPN-110826-1430 ===
  static String generateOpnameNo() {
    return "OPN-${_nowDMY()}-${_nowHMS().substring(0,4)}-${_rand3()}";
  }

  // === 6. MUTASI: MUT-110826-143022 ===
  static String generateMutasiNo() {
    return "MUT-${_nowDMY()}-${_nowHMS()}";
  }

  // === LOGIC UMUR NGENDAP ===
  static int hitungUmurNgendap(DateTime invoiceDate) {
    return DateTime.now().difference(invoiceDate).inDays;
  }

  static String warnaNgendap(int umur) {
    if (umur > 90) return 'MERAH';
    if (umur > 60) return 'ORANGE';
    if (umur > 30) return 'KUNING';
    return 'HIJAU';
  }

  static Color warnaNgendapColor(int umur) {
    // ignore: avoid_web_libraries_in_flutter
    // Return string color untuk logic, kalau mau Color pakai ini di UI:
    // if (umur > 90) return Colors.red;
    return warnaNgendap(umur) as dynamic;
  }

  static String statusTempo(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'OVERDUE ${diff.abs()} hari';
    if (diff == 0) return 'JATUH TEMPO HARI INI';
    if (diff <= 3) return 'DUE SOON $diff hari lagi';
    return 'BELUM JATUH TEMPO';
  }
}