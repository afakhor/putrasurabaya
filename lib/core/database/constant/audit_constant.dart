abstract class AuditAction {
  static const String editPrice = 'EDIT_PRICE';
  static const String createStore = 'CREATE_STORE';
  static const String voidTransaction = 'VOID_TRANSACTION';
  static const String mutationPayment = 'MUTATION_PAYMENT';
  static const String kulakHppMa = 'KULAK_HPP_MA';
  static const String jualTier1 = 'JUAL_TIER_1';
  static const String jualTier2 = 'JUAL_TIER_2';
  static const String jualTier3 = 'JUAL_TIER_3';
  static const String keluarRusak = 'KELUAR_RUSAK';
  static const String opnamePlus = 'OPNAME_PLUS';
  static const String opnameMinus = 'OPNAME_MINUS_SELISIH';
  static const String opnameMinusSelisih = 'OPNAME_MINUS_SELISIH';
  static const String jualRugi = 'JUAL_RUGI';
}
abstract class FraudCategory {
  static const String mainHarga = 'main_harga';
  static const String jualRugi = 'jual_rugi';
  static const String manipulasiTagihan = 'manipulasi_tagihan';
  static const String general = 'general';
  static const String hutang_overdue = 'hutang_overdue';
  static const String hutang_fiktif = 'hutang_fiktif';
  static const String piutang_macat = 'piutang_macat';
  static const String piutang_overdue = 'piutang_overdue';
  static const String MAIN_HARGA = 'MAIN_HARGA';
  static const String TOKO_FIKTIF = 'TOKO_FIKTIF';
  static const String MANIPULASI_TAGIHAN = 'MANIPULASI_TAGIHAN';
  static const String VOID_SUSPICIOUS = 'VOID_SUSPICIOUS';
  static const String JUAL_RUGI = 'JUAL_RUGI';
}
abstract class FraudSeverity {
  static const String kuning = 'kuning';
  static const String merah = 'merah';
  static const String hijau = 'hijau';
  static const String KUNING = 'kuning';
  static const String MERAH = 'merah';
  static const String HIJAU = 'hijau';
}