import 'package:drift/drift.dart';

// Import terpadu menggunakan package scheme
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'payables_dao.g.dart';

@DriftAccessor(tables: [Payables, DebtPayments, Suppliers])
class PayablesDao extends DatabaseAccessor<LocalDatabase>
    with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  // =======================================
  // 1. QUERY & STREAM DAFTAR HUTANG
  // ======================================

  Stream<List<PayableData>> watchActivePayables() {
    return (select(payables)
          ..where((tbl) => tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Stream<List<PayableData>> watchUnpaidPayables() => watchActivePayables();

  Stream<List<PayableData>> watchOverduePayables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    return (select(payables)
          ..where((tbl) =>
              tbl.dueDate.isSmallerOrEqualValue(limit) &
              tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Stream<List<PayableData>> watchPayablesBySupplier(String supplierId) {
    return (select(payables)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.dueDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // ===========================================================================
  // 2. TRANSAKSI (MUTASI HUTANG & PEMBAYARAN)
  // ===========================================================================

  Future<void> catatPembelianTempo({
    required String purchaseRef,
    required String supplierId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaHutang = totalAmount - dpAmount;
    final status = DebtStatus.tentukanStatus(sisaHutang, dpAmount);
    final payableId = 'AP-${DateTime.now().millisecondsSinceEpoch}';

    await transaction(() async {
      await into(payables).insert(
        PayablesCompanion.insert(
          id: payableId,
          purchaseRef: purchaseRef,
          supplierId: supplierId,
          totalAmount: totalAmount,
          paidAmount: Value(dpAmount),
          remainingAmount: sisaHutang < 0 ? 0.0 : sisaHutang,
          dueDate: dueDate,
          status: Value(status),
        ),
      );

      if (dpAmount > 0) {
        await into(debtPayments).insert(
          DebtPaymentsCompanion.insert(
            id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
            refId: payableId,
            type: 'payable_pay',
            amount: dpAmount,
            paymentMethod: 'cash',
            notes: const Value('Uang Muka / DP Pembelian Stok'),
          ),
        );
      }
    });
  }

  Future<void> catatHutang({
    required String purchaseRef,
    required String supplierId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) =>
      catatPembelianTempo(
        purchaseRef: purchaseRef,
        supplierId: supplierId,
        totalAmount: totalAmount,
        dpAmount: dpAmount,
        dueDate: dueDate,
      );

  Future<bool> bayarAngsuranHutang({
    required String payableId,
    required double nominalBayar,
    required String paymentMethod,
    String? notes,
  }) async {
    if (nominalBayar <= 0) {
      throw Exception('Nominal pembayaran tidak valid (harus > 0)');
    }

    return transaction(() async {
      final item = await (select(payables)
            ..where((tbl) => tbl.id.equals(payableId)))
          .getSingleOrNull();

      if (item == null) throw Exception('Data hutang supplier tidak ditemukan');
      if (item.remainingAmount <= 0) throw Exception('Hutang ini sudah lunas');

      final actualBayar =
          nominalBayar > item.remainingAmount ? item.remainingAmount : nominalBayar;

      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;

      final newStatus = DebtStatus.tentukanStatus(newRemaining, actualBayar);

      final updatedRows = await (update(payables)
            ..where((tbl) => tbl.id.equals(payableId)))
          .write(
        PayablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
          refId: payableId,
          type: 'payable_pay',
          amount: actualBayar,
          paymentMethod: paymentMethod,
          notes: Value(notes ??
              (newStatus == DebtStatus.paid
                  ? 'Pelunasan Hutang Supplier'
                  : 'Angsuran Hutang Supplier')),
        ),
      );

      return updatedRows > 0;
    });
  }

  Future<bool> bayarHutangSupplier({
    required String payableId,
    required double nominalBayar,
    required String paymentMethod,
    String? notes,
  }) =>
      bayarAngsuranHutang(
        payableId: payableId,
        nominalBayar: nominalBayar,
        paymentMethod: paymentMethod,
        notes: notes,
      );

  // ===========================================================================
  // 3. RIWAYAT PEMBAYARAN
  // ===========================================================================

  Future<List<DebtPaymentData>> getPaymentHistory(String payableId) {
    return (select(debtPayments)
          ..where((tbl) =>
              tbl.refId.equals(payableId) & tbl.type.equals('payable_pay'))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.paymentDate, mode: OrderingMode.desc)
          ]))
        .get();
  }
}
