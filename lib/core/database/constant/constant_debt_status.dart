class DebtStatus {
  static const String paid = 'paid';
  static const String partial = 'partial';
  static const String unpaid = 'unpaid';
  static const String lunas = 'LUNAS'; // Untuk handle data lama

  /// Logika tunggal penentu status
  static String tentukanStatus(double sisaHutang, double dp) {
    if (sisaHutang <= 0) return DebtStatus.paid;
    if (dp > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }
}
