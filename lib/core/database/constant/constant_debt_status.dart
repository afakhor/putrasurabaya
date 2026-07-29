import 'package:flutter/material.dart';

/// Class Utama Manajemen Status Hutang / Piutang & Transaksi
class DebtStatus {
  static const String paid = 'paid';
  static const String partial = 'partial';
  static const String unpaid = 'unpaid';
  static const String voidStatus = 'void'; // Untuk transaksi yang dibatalkan
  static const String lunas = 'LUNAS';     // Untuk kompatibilitas data legacy/lama

  /// 1. Logika tunggal penentu status (Metode Utama milikmu)
  static String tentukanStatus(double sisaHutang, double dp) {
    if (sisaHutang <= 0) return DebtStatus.paid;
    if (dp > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }

  /// 2. Helper penentu status langsung dari Total Tagihan & Total Bayar
  static String tentukanStatusFromTotal({
    required double grandTotal,
    required double payAmount,
  }) {
    final sisaHutang = grandTotal - payAmount;
    return tentukanStatus(sisaHutang > 0 ? sisaHutang : 0, payAmount);
  }

  /// 3. Helper Konversi Status DB ke Teks Bahasa Indonesia (Untuk UI)
  static String getLabel(String status) {
    switch (status.toLowerCase()) {
      case paid:
      case lunas:
        return 'LUNAS';
      case partial:
        return 'TEMPO (DP)';
      case unpaid:
        return 'TEMPO (BELUM BAYAR)';
      case voidStatus:
        return 'DIBATALKAN';
      default:
        return status.toUpperCase();
    }
  }

  /// 4. Helper Warna Badge/Status di UI Flutter
  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case paid:
      case lunas:
        return Colors.green;
      case partial:
        return Colors.orange;
      case unpaid:
        return Colors.red;
      case voidStatus:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}

/// Class Tambahan Metode Pembayaran (Terintegrasi)
class PaymentType {
  static const String cash = 'cash';
  static const String credit = 'credit';
  static const String transfer = 'transfer';

  static String getLabel(String type) {
    switch (type.toLowerCase()) {
      case cash:
        return 'Tunai (Cash)';
      case credit:
        return 'Kredit / Tempo';
      case transfer:
        return 'Transfer Bank';
      default:
        return type.toUpperCase();
    }
  }
}
