import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';

part 'receivables_dao.g.dart';

class ReceivableWithCustomer {
  final ReceivableData receivable;
  final CustomerData? customer;
  ReceivableWithCustomer({required this.receivable, this.customer});
}

@DriftAccessor(tables: [Receivables, Customers, DebtPayments])
class ReceivablesDao extends DatabaseAccessor<LocalDatabase> with _$ReceivablesDaoMixin {
  ReceivablesDao(LocalDatabase db) : super(db);

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

  Stream<List<ReceivableWithCustomer>> searchReceivables(String queryText) {
    if (queryText.trim().isEmpty) return watchActiveReceivables();
    final cleanQuery = '%${queryText.trim().toLowerCase()}%';
    final query = select(receivables).join([
      leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId)),
    ])
      ..where(receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]) &
          (customers.name.lower().like(cleanQuery) |
              receivables.transactionId.lower().like(cleanQuery)))
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

  Stream<List<ReceivableData>> watchReceivablesByCustomer(String customerId) {
    return (select(receivables)
          ..where((tbl) => tbl.customerId.equals(customerId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<ReceivableWithCustomer>> watchOverdueReceivables({DateTime? dateLimit}) {
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

  Future<double> getTotalActiveReceivableAmount() async {
    final query = select(receivables)..where((tbl) => tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]));
    final list = await query.get();
    return list.fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
  }

  Future<void> catatPiutangBaru({
    required String transactionId,
    required String customerId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
    String paymentMethod = 'CASH',
    String? salesId,
    String? userId,
  }) async {
    final now = DateTime.now();
    final sisaPiutang = totalAmount - dpAmount;
    final actualSisa = sisaPiutang < 0 ? 0.0 : sisaPiutang;
    final status = DebtStatus.tentukanStatus(actualSisa, dpAmount);
    final receivableId = 'RC-${now.microsecondsSinceEpoch}';

    await transaction(() async {
      await into(receivables).insert(
        ReceivablesCompanion.insert(
          id: receivableId,
          transactionId: Value(transactionId),
          customerId: Value(customerId),
          salesId: Value(salesId),
          totalAmount: Value(totalAmount),
          paidAmount: Value(dpAmount),
          remainingAmount: Value(actualSisa),
          dueDate: Value(dueDate),
          status: Value(status),
          isSynced: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final customer = await (select(customers)..where((tbl) => tbl.id.equals(customerId))).getSingleOrNull();
      if (customer != null) {
        final newDebt = customer.sisaHutang + actualSisa;
        await (update(customers)..where((tbl) => tbl.id.equals(customerId))).write(
          CustomersCompanion(
            sisaHutang: Value(newDebt),
            isSynced: const Value(false),
            updatedAt: Value(now),
          ),
        );
      }

      if (dpAmount > 0) {
        await into(debtPayments).insert(
          DebtPaymentsCompanion.insert(
            id: 'PAY-AR-${now.microsecondsSinceEpoch}',
            refId: Value(receivableId),
            type: Value('receivable'),
            userId: Value(userId ?? 'SYSTEM'),
            amount: Value(dpAmount),
            paymentMethod: Value(paymentMethod),
            notes: const Value('Uang Muka / DP Penjualan Kasir'),
            isSynced: const Value(false),
            paymentDate: Value(now),
          ),
        );
      }
    });
  }

  Future<bool> bayarAngsuranPiutang({
    required String receivableId,
    required double nominalBayar,
    required String paymentMethod,
    required String userId,
    String? proofImage,
    String? notes,
  }) async {
    if (nominalBayar <= 0) throw Exception('Nominal pembayaran tidak valid (harus > 0)');
    return transaction(() async {
      final now = DateTime.now();
      final item = await (select(receivables)..where((tbl) => tbl.id.equals(receivableId))).getSingleOrNull();
      if (item == null) throw Exception('Data piutang tidak ditemukan');
      if (item.remainingAmount <= 0) throw Exception('Piutang ini sudah lunas');

      final actualBayar = nominalBayar > item.remainingAmount ? item.remainingAmount : nominalBayar;
      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;
      final actualNewRemaining = newRemaining < 0 ? 0.0 : newRemaining;
      final newStatus = DebtStatus.tentukanStatus(actualNewRemaining, actualBayar);

      final updatedRows = await (update(receivables)..where((tbl) => tbl.id.equals(receivableId))).write(
        ReceivablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(actualNewRemaining),
          status: Value(newStatus),
          isSynced: const Value(false),
          updatedAt: Value(now),
        ),
      );

      if (item.customerId != null) {
        final customer = await (select(customers)..where((tbl) => tbl.id.equals(item.customerId!))).getSingleOrNull();
        if (customer != null) {
          final sisaUtangCust = customer.sisaHutang - actualBayar;
          await (update(customers)..where((tbl) => tbl.id.equals(item.customerId!))).write(
            CustomersCompanion(
              sisaHutang: Value(sisaUtangCust < 0 ? 0.0 : sisaUtangCust),
              isSynced: const Value(false),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AR-${now.microsecondsSinceEpoch}',
          refId: Value(receivableId),
          type: Value('receivable'),
          userId: Value(userId),
          amount: Value(actualBayar),
          paymentMethod: Value(paymentMethod),
          proofImage: Value(proofImage),
          notes: Value(notes ?? (newStatus == DebtStatus.paid || newStatus == DebtStatus.lunas ? 'Pelunasan Piutang Pelanggan' : 'Angsuran Piutang Pelanggan')),
          isSynced: const Value(false),
          paymentDate: Value(now),
        ),
      );
      return updatedRows > 0;
    });
  }

  Future<List<DebtPaymentData>> getPaymentHistory(String receivableId) {
    return (select(debtPayments)
          ..where((tbl) => tbl.refId.equals(receivableId) & tbl.type.equals('receivable'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.paymentDate, mode: OrderingMode.desc)]))
        .get();
  }
}

final receivablesDaoProvider = Provider<ReceivablesDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ReceivablesDao(db);
});

final activeReceivablesStreamProvider = StreamProvider<List<ReceivableWithCustomer>>((ref) {
  final dao = ref.watch(receivablesDaoProvider);
  return dao.watchActiveReceivables();
});

final receivableSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredReceivablesStreamProvider = StreamProvider<List<ReceivableWithCustomer>>((ref) {
  final dao = ref.watch(receivablesDaoProvider);
  final query = ref.watch(receivableSearchQueryProvider);
  return dao.searchReceivables(query);
});