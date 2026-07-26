import 'package:drift/drift.dart';
import '../local_database.dart';

/// Model wrapper untuk menggabungkan data piutang dengan data pelanggan
class ReceivableWithCustomer {
  final Receivable receivable;
  final CustomerData? customer;

  ReceivableWithCustomer({
    required this.receivable,
    this.customer,
  });
}

extension ReceivablesDao on LocalDatabase {
  /// Stream daftar piutang beserta data pelanggan (Join Table)
  Stream<List<ReceivableWithCustomer>> watchReceivablesWithCustomer() {
    final query = select(receivables).join([
      leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ReceivableWithCustomer(
          receivable: row.readTable(receivables),
          customer: row.readTableOrNull(customers),
        );
      }).toList();
    });
  }

  /// Pencatatan piutang baru dari transaksi penjualan tempo/kredit
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
