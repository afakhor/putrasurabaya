// lib/core/database/daos/receivables_dao.dart

import 'package:drift/drift.dart';
import '../local_database.dart';

extension ReceivablesDao on LocalDatabase {
  /// Pencatatan piutang dari transaksi penjualan tempo/kredit
  Future<void> catatPenjualanTempo({
    required String transactionId,
    required String customerId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaPiutang = totalAmount - dpAmount;
    final status = sisaPiutang <= 0 ? 'paid' : (dpAmount > 0 ? 'partial' : 'unpaid');

    await into(receivables).insert(
      ReceivablesCompanion.insert(
        id: 'AR-${DateTime.now().millisecondsSinceEpoch}',
        transactionId: transactionId,
        customerId: customerId,
        totalAmount: totalAmount,
        paidAmount: Value(dpAmount),
        remainingAmount: sisaPiutang,
        dueDate: dueDate,
        status: status,
      ),
    );
  }
}
