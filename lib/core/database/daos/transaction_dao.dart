import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems])
class TransactionDao extends DatabaseAccessor<LocalDatabase> with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  /// 1. Ambil semua transaksi yang belum tersinkronisasi (Queue)
  Future<List<TransactionData>> getUnsyncedTransactions() {
    return (select(transactions)..where((t) => t.isSynced.equals(false))).get();
  }

  /// 2. Update status menjadi tersinkronisasi setelah berhasil diunggah (ID menggunakan String)
  Future<void> markAsSynced(String transactionId) {
    return (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(const TransactionsCompanion(isSynced: Value(true)));
  }

  /// 3. Ambil detail item dari sebuah transaksi (ID menggunakan String)
  Future<List<TransactionItemData>> getItemsForTransaction(String transactionId) {
    return (select(transactionItems)..where((i) => i.transactionId.equals(transactionId))).get();
  }
}

/// Provider Riverpod untuk TransactionDao
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return TransactionDao(db);
});
