import 'package:drift/drift.dart';
import 'local_database.dart';

extension PayableExtension on LocalDatabase {
  Future<void> catatPembelianTempo({
    required String purchaseRef,
    required String supplierId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaHutang = totalAmount - dpAmount;
    final status = sisaHutang <= 0 ? 'paid' : (dpAmount > 0 ? 'partial' : 'unpaid');

    await into(payables).insert(
      PayablesCompanion.insert(
        id: 'AP-${DateTime.now().millisecondsSinceEpoch}',
        purchaseRef: purchaseRef,
        supplierId: supplierId,
        totalAmount: totalAmount,
        paidAmount: Value(dpAmount),
        remainingAmount: sisaHutang,
        dueDate: dueDate,
        status: status,
      ),
    );
  }
}
