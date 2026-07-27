import 'package:drift/drift.dart';

// Gunakan Package Import secara konsisten untuk semua dependency internal
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'receivables_dao.g.dart';

/// Model wrapper untuk menggabungkan data piutang dengan data pelanggan
class ReceivableWithCustomer {
  final ReceivableData receivable;
  final CustomerData? customer;

  ReceivableWithCustomer({
    required this.receivable,
    this.customer,
  });
}

@DriftAccessor(tables: [Receivables, Customers, DebtPayments])
class ReceivablesDao extends DatabaseAccessor<LocalDatabase>
    with _$ReceivablesDaoMixin {
  ReceivablesDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM DAFTAR PIUTANG (RECEIVABLES)
  // ===========================================================================

  /// Stream semua piutang (belum lunas) beserta nama pelanggan
  Stream<List<ReceivableWithCustomer>> watchActiveReceivables() {
    final query = select(receivables).join([
      leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId)),
    ])
      ..where(receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
      ..orderBy([OrderingTerm.asc(receivables.dueDate)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ReceivableWithCustomer(
          receivable: row.readTable(receivables),
          customer: row.readTableOrNull(customers),
        );
      }).toList();
    });
  }

  /// Stream daftar piutang per pelanggan spesifik
  Stream<List<ReceivableData>> watchReceivablesByCustomer(String customerId) {
    return (select(receivables)
          ..where((tbl) => tbl.customerId.equals(customerId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.dueDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Stream piutang yang hampir / sudah jatuh tempo (Overdue)
  Stream<List<ReceivableWithCustomer>> watchOverdueReceivables(
      {DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();

    final query = select(receivables).join([
      leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId)),
    ])
      ..where(receivables.dueDate.isSmallerOrEqualValue(limit) &
          receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
      ..orderBy([OrderingTerm.asc(receivables.dueDate)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ReceivableWithCustomer(
          receivable: row.readTable(receivables),
          customer: row.readTableOrNull(customers),
        );
      }).toList();
    });
  }

  // ===========================================================================
  // 2. TRANSAKSI (MUTASI PIUTANG & PEMBAYARAN)
  // ===========================================================================

  /// Pencatatan Piutang Baru dari Transaksi Kasir
  Future<void> catatPiutangBaru({
    required String transactionId,
    required String customerId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaPiutang = totalAmount - dpAmount;
    final status = DebtStatus.tentukanStatus(sisaPiutang, dpAmount);
    final receivableId = 'RC-${DateTime.now().millisecondsSinceEpoch}';

    await transaction(() async {
      // 1. Simpan ke tabel Receivables
      await into(receivables).insert(
        ReceivablesCompanion.insert(
          id: receivableId,
          transactionId: transactionId,
          customerId: customerId,
          totalAmount: totalAmount,
          paidAmount: Value(dpAmount),
          remainingAmount: sisaPiutang < 0 ? 0.0 : sisaPiutang,
          dueDate: dueDate,
          status: Value(status),
        ),
      );

      // 2. Tambahkan akumulasi hutang pada data Pelanggan
      final customer = await (select(customers)
            ..where((tbl) => tbl.id.equals(customerId)))
          .getSingleOrNull();

      if (customer != null) {
        final newDebt = customer.totalDebt + (sisaPiutang < 0 ? 0.0 : sisaPiutang);
        await (update(customers)..where((tbl) => tbl.id.equals(customerId)))
            .write(
          CustomersCompanion(totalDebt: Value(newDebt)),
        );
      }

      // 3. Catat DP jika ada
      if (dpAmount > 0) {
        await into(debtPayments).insert(
          DebtPaymentsCompanion.insert(
            id: 'PAY-AR-${DateTime.now().millisecondsSinceEpoch}',
            refId: receivableId,
            type: 'receivable_collect',
            amount: dpAmount,
            paymentMethod: 'cash',
            notes: const Value('Uang Muka / DP Penjualan Kasir'),
          ),
        );
      }
    });
  }

  /// Pembayaran Cicilan / Pelunasan Piutang
  Future<bool> bayarAngsuranPiutang({
    required String receivableId,
    required double nominalBayar,
    required String paymentMethod,
    String? notes,
  }) async {
    if (nominalBayar <= 0) {
      throw Exception('Nominal pembayaran tidak valid (harus > 0)');
    }

    return transaction(() async {
      // 1. Ambil data piutang
      final item = await (select(receivables)
            ..where((tbl) => tbl.id.equals(receivableId)))
          .getSingleOrNull();

      if (item == null) throw Exception('Data piutang tidak ditemukan');
      if (item.remainingAmount <= 0) throw Exception('Piutang ini sudah lunas');

      // Proteksi jika pembayaran melebihi sisa piutang
      final actualBayar = nominalBayar > item.remainingAmount
          ? item.remainingAmount
          : nominalBayar;

      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = DebtStatus.tentukanStatus(newRemaining, actualBayar);

      // 2. Update status & sisa piutang
      final updatedRows = await (update(receivables)
            ..where((tbl) => tbl.id.equals(receivableId)))
          .write(
        ReceivablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      // 3. Kurangi akumulasi hutang pada data Pelanggan
      final customer = await (select(customers)
            ..where((tbl) => tbl.id.equals(item.customerId)))
          .getSingleOrNull();

      if (customer != null) {
        final sisaUtangCust = customer.totalDebt - actualBayar;
        await (update(customers)..where((tbl) => tbl.id.equals(item.customerId)))
            .write(
          CustomersCompanion(
              totalDebt: Value(sisaUtangCust < 0 ? 0.0 : sisaUtangCust)),
        );
      }

      // 4. Catat riwayat pembayaran
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AR-${DateTime.now().millisecondsSinceEpoch}',
          refId: receivableId,
          type: 'receivable_collect',
          amount: actualBayar,
          paymentMethod: paymentMethod,
          notes: Value(notes ??
              (newStatus == DebtStatus.paid
                  ? 'Pelunasan Piutang Pelanggan'
                  : 'Angsuran Piutang Pelanggan')),
        ),
      );

      return updatedRows > 0;
    });
  }

  // ===========================================================================
  // 3. RIWAYAT PEMBAYARAN
  // ===========================================================================

  /// Mengambil riwayat pembayaran untuk 1 item piutang
  Future<List<DebtPaymentData>> getPaymentHistory(String receivableId) {
    return (select(debtPayments)
          ..where((tbl) =>
              tbl.refId.equals(receivableId) &
              tbl.type.equals('receivable_collect'))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.paymentDate, mode: OrderingMode.desc)
          ]))
        .get();
  }
}
