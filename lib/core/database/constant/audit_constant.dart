/// Tipe Akses / Aktivitas Sensitif (Audit Trail)
abstract class AuditAction {
  static const String editPrice = 'EDIT_PRICE';
  static const String createStore = 'CREATE_STORE';
  static const String voidTransaction = 'VOID_TRANSACTION';
  static const String mutationPayment = 'MUTATION_PAYMENT';
}

/// Kategori Indikasi Fraud / Kecurangan
abstract class FraudCategory {
  static const String mainHarga = 'MAIN_HARGA';
  static const String tokoFiktif = 'TOKO_FIKTIF';
  static const String manipulasiTagihan = 'MANIPULASI_TAGIHAN';
  static const String voidSuspicious = 'VOID_SUSPICIOUS';
}

/// Level Bahaya Indikasi Fraud
abstract class FraudSeverity {
  static const String kuning = 'kuning'; // Peringatan / Perlu Dicek
  static const String merah = 'merah';   // Bahaya / Potensi Kerugian Tinggi
}
