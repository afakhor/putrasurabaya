import 'package:drift/drift.dart';
import '../local_database.dart';

part 'payables_dao.g.dart';

@DriftAccessor(tables: [Payables, DebtPayments])
class PayablesDao extends DatabaseAccessor<LocalDatabase> with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM DAFTAR HUTANG (PAYABLES)
  // ===========================================================================

  /// Stream semua hutang ke supplier yang belum lunas
  Stream<List<PayableData>> watchActivePayables() {
    return (select(payables)
      ..where((tbl) => tbl.status.isNotIn(['paid']))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)]))
      .watch();
  }

  /// Stream hutang supplier yang hampir / sudah jatuh tempo
  Stream<List<PayableData>> watchOverduePayables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    return (select(payables)
      ..where((tbl) => tbl.dueDate.isLessThanOrEqualToValue(limit) & tbl.status.isNotIn(['paid']))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)]))
      .watch();
  }

  // ===========================================================================
  // 2. TRANSAKSI (MUTASI HUTANG & PEMBAYARAN)
  // ===========================================================================

  /// Pencatatan hutang usaha dari pembelian tempo ke supplier
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

  /// Pembayaran cicilan / pelunasan hutang ke supplier
  Future<void> bayarAngsuranHutang({
    required String payableId,
    required double jumlahBayar,
    required String paymentMethod,
    String? catatan,
  }) async {
    await transaction(() async {
      final item = await (select(payables)..where((tbl) => tbl.id.equals(payableId))).getSingle();

      final newPaid = item.paidAmount + jumlahBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = newRemaining <= 0 ? 'paid' : 'partial';

      await (update(payables)..where((tbl) => tbl.id.equals(payableId))).write(
        PayablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      // Catat Arus Kas Keluar (Debt Payment)
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
          refId: payableId,
          type: 'payable_pay',
          amount: jumlahBayar,
          paymentMethod: paymentMethod,
          notes: Value(catatan ?? 'Pembayaran Hutang Pembelian Supplier'),
        ),
      );
    });
  }
}
