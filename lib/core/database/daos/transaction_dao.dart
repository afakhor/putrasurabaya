import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';

part 'transaction_dao.g.dart';

class TransactionWithItems {
  final TransactionData transaction;
  final List<TransactionItemData> items;
  TransactionWithItems({required this.transaction, required this.items});
}

@DriftAccessor(tables: [Transactions, TransactionItems])
class TransactionDao extends DatabaseAccessor<LocalDatabase> with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  // POS - PAKAI ORCHESTRATOR 1 PINTU
  Future<void> insertTransaction({
    required TransactionsCompanion transactionHeader,
    required List<TransactionItemsCompanion> items,
  }) {
    return db.prosesTransaksiPenyimpanan(
      dataTransaksi: transactionHeader,
      itemTransaksi: items,
    );
  }

  Future<void> voidTransaction({required String transactionId, required String voidByUserId, required String reason}) async {
    return transaction(() async {
      final tx = await (select(transactions)..where((t) => t.id.equals(transactionId))).getSingleOrNull();
      if (tx == null) throw Exception('Transaksi tidak ditemukan');
      if ([DebtStatus.voidStatus, 'VOID', 'CANCELLED', 'Batal'].contains(tx.status)) throw Exception('Sudah di-void');
      
      final items = await (select(transactionItems)..where((ti) => ti.transactionId.equals(transactionId))).get();
      for (final item in items) {
        await db.stockMutationDao.catatItemMasuk(
          productId: item.productId,
          qty: item.quantity * item.conversionFactor,
          refNo: 'VOID-${tx.invoiceNo}',
          userId: voidByUserId,
          notes: 'Void ${tx.invoiceNo}: $reason',
        );
      }
      await (update(transactions)..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(status: const Value(DebtStatus.voidStatus), notes: Value(reason), updatedAt: Value(DateTime.now()), isSynced: const Value(false)),
      );
    });
  }

  Stream<List<TransactionData>> watchTodayTransactions() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return (select(transactions)..where((t) => t.date.isBetweenValues(start, end) & t.status.isNotIn(['CANCELLED', 'VOID', DebtStatus.voidStatus]))..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }
  Future<TransactionWithItems?> getTransactionWithItemsById(String id) async {
    final tx = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tx == null) return null;
    final list = await (select(transactionItems)..where((ti) => ti.transactionId.equals(id))).get();
    return TransactionWithItems(transaction: tx, items: list);
  }
  Future<List<TransactionData>> getUnsyncedTransactions() => (select(transactions)..where((t) => t.isSynced.equals(false))).get();
  Future<void> markAsSynced(List<String> ids) => (update(transactions)..where((t) => t.id.isIn(ids))).write(const TransactionsCompanion(isSynced: Value(true)));
}

final transactionDaoProvider = Provider<TransactionDao>((ref) => TransactionDao(ref.watch(localDatabaseProvider)));
final todayTransactionsProvider = StreamProvider<List<TransactionData>>((ref) => ref.watch(transactionDaoProvider).watchTodayTransactions());