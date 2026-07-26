import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/finance_table.dart'; // <--- TAMBAHKAN IMPORT INI

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
      ..where(receivables.status.isNotIn(['paid', 'LUNAS']))
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
      ..where(receivables.dueDate.isLessThanOrEqualToValue(limit) &
          receivables.status.isNotIn(['paid', 'LUNAS']))
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

  /// Catat Piutang Baru (Biasanya dipanggil dari modul Kasir / Checkout)
  Future<void> catatPiutangBaru({
    required String transactionId,
    required String customerId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaPiutang = totalAmount - dpAmount;
    final status =
        sisaPiutang <= 0 ? 'paid' : (dpAmount > 0 ? 'partial' : 'unpaid');
    final receivableId = 'RC-${DateTime.now().millisecondsSinceEpoch}';

    await transaction(() async {
      // 1. Catat ke tabel Receivables
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

      // 2. Update Total Utang Pelanggan di tabel Customers
      final customer = await (select(customers)
            ..where((tbl) => tbl.id.equals(customerId)))
          .getSingleOrNull();

      if (customer != null) {
        final newDebt = customer.totalDebt + sisaPiutang;
        await (update(customers)..where((tbl) => tbl.id.equals(customerId)))
            .write(
          CustomersCompanion(totalDebt: Value(newDebt)),
        );
      }

      // 3. Jika ada DP, catat ke DebtPayments (Arus Kas Masuk)
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

  /// Pembayaran cicilan / pelunasan piutang pelanggan
  Future<bool> bayarAngsuranPiutang({
    required String receivableId,
    required double nominalBayar,
    required String paymentMethod,
    String? notes,
  }) async {
    return transaction(() async {
      // 1. Ambil data piutang saat ini
      final item = await (select(receivables)
            ..where((tbl) => tbl.id.equals(receivableId)))
          .getSingleOrNull();

      if (item == null) {
        throw Exception('Data piutang tidak ditemukan');
      }
      if (item.remainingAmount <= 0) {
        throw Exception('Piutang ini sudah lunas');
      }

      // Proteksi agar bayar tidak melebihi sisa hutang (mencegah minus)
      final actualBayar = nominalBayar > item.remainingAmount
          ? item.remainingAmount
          : nominalBayar;

      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = newRemaining <= 0 ? 'paid' : 'partial';

      // 2. Update tabel Receivables
      final updatedRows = await (update(receivables)
            ..where((tbl) => tbl.id.equals(receivableId)))
          .write(
        ReceivablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      // 3. Potong saldo utang pelanggan di tabel Customers
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

      // 4. Catat riwayat kas masuk di tabel DebtPayments
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AR-${DateTime.now().millisecondsSinceEpoch}',
          refId: receivableId,
          type: 'receivable_collect',
          amount: actualBayar,
          paymentMethod: paymentMethod,
          notes: Value(notes ??
              (newRemaining <= 0
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

  /// Ambil riwayat pembayaran spesifik untuk 1 nota piutang
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
