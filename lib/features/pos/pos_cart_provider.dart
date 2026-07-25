// lib/features/pos/pos_cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/database/daos/receivables_dao.dart'; // <--- IMPORT DI SINI

class PosCartNotifier extends StateNotifier<PosCartState> {
  final LocalDatabase _db;

  PosCartNotifier(this._db) : super(PosCartState());

  Future<bool> processCheckout({
    required String paymentMethod, // 'cash', 'qris', atau 'tempo'
    required String customerId,
    required double dpAmount,
    required DateTime? dueDate,
  }) async {
    // 1. Simpan Transaksi Penjualan Utama & Detail
    final txId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    // ... simpan ke tabel transactions & transaction_items ...

    // 2. Jika Metode Bayar = TEMPO, catat ke tabel Receivables via DAO
    if (paymentMethod == 'tempo') {
      await _db.catatPenjualanTempo(
        transactionId: txId,
        customerId: customerId,
        totalAmount: state.totalPrice,
        dpAmount: dpAmount,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
      );
    }

    return true;
  }
}
