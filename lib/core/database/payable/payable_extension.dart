import 'package:drift/drift.dart';
import '../local_database.dart';

part 'payables_extension.g.dart';

@DriftAccessor(tables: [Payables, DebtPayments, PayablePayments])
class PayablesDao extends DatabaseAccessor<LocalDatabase>
    with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM DAFTAR HUTANG (PAYABLES)
  // ===========================================================================

  /// Stream semua hutang ke supplier yang belum lunas
  Stream<List<PayableData>> watchActivePayables() {
    return (select(payables)
          ..where((tbl) => tbl.status.isNotIn(['paid', 'LUNAS']))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Alias stream untuk hutang yang belum lunas
  Stream<List<PayableData>> watchUnpaidPayables() => watchActivePayables();

  /// Stream hutang supplier yang hampir / sudah jatuh tempo
  Stream<List<PayableData>> watchOverduePayables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    return (select(payables)
          ..where((tbl) =>
              tbl.dueDate.isLessThanOrEqualToValue(limit) &
              tbl.status.isNotIn(['paid', 'LUNAS']))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Stream daftar hutang per supplier spesifik
  Stream<List<PayableData>> watchPayablesBySupplier(String supplierId) {
    return (select(payables)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
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
    final status =
        sisaHutang <= 0 ? 'paid' : (dpAmount > 0 ? 'partial' : 'unpaid');
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
          status: status,
        ),
      );

      // Jika ada DP awal, catat ke log riwayat pembayaran arus kas keluar
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

  /// Alias method untuk pencatatan hutang supplier
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

  /// Pembayaran cicilan / pelunasan hutang ke supplier
  Future<bool> bayarAngsuranHutang({
    required String payableId,
    required double nominalBayar,
    required String paymentMethod, // 'cash', 'transfer'
    String? notes,
  }) async {
    return transaction(() async {
      final item = await (select(payables)
            ..where((tbl) => tbl.id.equals(payableId)))
          .getSingleOrNull();

      if (item == null) {
        throw Exception('Data hutang supplier tidak ditemukan');
      }

      if (item.remainingAmount <= 0) {
        throw Exception('Hutang ini sudah lunas');
      }

      final newPaid = item.paidAmount + nominalBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = newRemaining <= 0 ? 'paid' : 'partial';

      final updatedRows = await (update(payables)
            ..where((tbl) => tbl.id.equals(payableId)))
          .write(
        PayablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      // Catat log transaksi di DebtPayments
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
          refId: payableId,
          type: 'payable_pay',
          amount: nominalBayar,
          paymentMethod: paymentMethod,
          notes: Value(notes ??
              (newRemaining <= 0
                  ? 'Pelunasan Hutang Supplier'
                  : 'Angsuran Hutang Supplier')),
        ),
      );

      return updatedRows > 0;
    });
  }

  /// Alias method untuk pembayaran angsuran hutang
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

  /// Ambil riwayat angsuran / pembayaran suatu hutang supplier
  Future<List<DebtPayment>> getPaymentHistory(String payableId) {
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
