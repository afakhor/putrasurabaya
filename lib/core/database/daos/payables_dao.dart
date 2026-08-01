import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import terpadu menggunakan package scheme konsisten
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'payables_dao.g.dart';

@DriftAccessor(tables: [Payables, DebtPayments, Suppliers])
class PayablesDao extends DatabaseAccessor<LocalDatabase>
    with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM DAFTAR HUTANG (PAYABLES)
  // ===========================================================================

  /// Stream Hutang Aktif (Belum Lunas / Cicilan)
  Stream<List<PayableData>> watchActivePayables() {
    return (select(payables)
          ..where((tbl) =>
              tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Alias Stream Hutang Aktif
  Stream<List<PayableData>> watchUnpaidPayables() => watchActivePayables();

  /// Stream Hutang Jatuh Tempo / Lewat Tanggal
  Stream<List<PayableData>> watchOverduePayables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    return (select(payables)
          ..where((tbl) =>
              tbl.dueDate.isSmallerOrEqualValue(limit) &
              tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.dueDate, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Stream Hutang Berdasarkan Supplier Spesifik
  Stream<List<PayableData>> watchPayablesBySupplier(String supplierId) {
    return (select(payables)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.dueDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Stream Detail 1 Data Hutang
  Stream<PayableData?> watchPayableById(String id) {
    return (select(payables)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Ambil Detail 1 Data Hutang (Future)
  Future<PayableData?> getPayableById(String id) {
    return (select(payables)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Stream Hutang Aktif Gabungan dengan Nama Supplier (Untuk UI Tampilan Laporan/List)
  Stream<List<PayableWithSupplier>> watchActivePayablesWithSupplier() {
    final query = select(payables).join([
      innerJoin(suppliers, suppliers.id.equalsExp(payables.supplierId)),
    ])
      ..where(payables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
      ..orderBy([
        OrderingTerm(expression: payables.dueDate, mode: OrderingMode.asc)
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PayableWithSupplier(
          payable: row.readTable(payables),
          supplier: row.readTable(suppliers),
        );
      }).toList();
    });
  }

  /// Hitung Total Sisa Hutang Aktif Seluruh Supplier (Guna Summary Keuangan)
  Future<double> getTotalRemainingPayables() async {
    final sumExp = payables.remainingAmount.sum();
    final query = selectOnly(payables)
      ..addColumns([sumExp])
      ..where(payables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]));
    final row = await query.getSingleOrNull();
    return row?.read(sumExp) ?? 0.0;
  }

  // ===========================================================================
  // 2. TRANSAKSI (MUTASI HUTANG & PEMBAYARAN ANGSURAN)
  // ===========================================================================

  /// Catat Pembelian Tempo Baru (Memunculkan Kartu Hutang Supplier)
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
          isSynced: const Value(false),
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
            isSynced: const Value(false),
          ),
        );
      }
    });
  }

  /// Alias Catat Pembelian Tempo
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

  /// Catat Bayar Angsuran / Pelunasan Hutang Supplier
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
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
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
              (newStatus == DebtStatus.paid || newStatus == DebtStatus.lunas
                  ? 'Pelunasan Hutang Supplier'
                  : 'Angsuran Hutang Supplier')),
          isSynced: const Value(false),
        ),
      );

      return updatedRows > 0;
    });
  }

  /// Alias Bayar Angsuran Hutang Supplier
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
  // 3. RIWAYAT PEMBAYARAN (DEBT PAYMENTS)
  // ===========================================================================

  /// Ambil Riwayat Cicilan Hutang Spesifik (Future)
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

  /// Stream Real-Time Riwayat Cicilan Hutang Spesifik
  Stream<List<DebtPaymentData>> watchPaymentHistory(String payableId) {
    return (select(debtPayments)
          ..where((tbl) =>
              tbl.refId.equals(payableId) & tbl.type.equals('payable_pay'))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.paymentDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }
}

// ===========================================================================
// DTO HELPER: PAYABLE + SUPPLIER
// ===========================================================================

class PayableWithSupplier {
  final PayableData payable;
  final SupplierData supplier;

  PayableWithSupplier({
    required this.payable,
    required this.supplier,
  });
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final payablesDaoProvider = Provider<PayablesDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return PayablesDao(db);
});
