import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';

// --- IMPORT TABEL TRANSAKSI ---
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart'; // Berisi Transactions & TransactionItems

part 'transaction_dao.g.dart';

/// Model wrapper untuk menggabungkan header transaksi dengan seluruh detail itemnya
class TransactionWithItems {
  final TransactionData transaction;
  final List<TransactionItemData> items;

  TransactionWithItems({
    required this.transaction,
    required this.items,
  });
}

@DriftAccessor(tables: [Transactions, TransactionItems])
class TransactionDao extends DatabaseAccessor<LocalDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. READ & STREAM TRANSAKSI
  // ===========================================================================

  /// Stream daftar transaksi terbaru untuk riwayat penjualan
  Stream<List<TransactionData>> watchRecentTransactions({int limit = 50}) {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  /// Ambil detail transaksi lengkap beserta item-item di dalamnya
  Future<TransactionWithItems?> getTransactionWithItems(String transactionId) async {
    final tx = await (select(transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();

    if (tx == null) return null;

    final items = await getItemsForTransaction(transactionId);
    return TransactionWithItems(transaction: tx, items: items);
  }

  /// Ambil detail item dari sebuah transaksi (ID menggunakan String)
  Future<List<TransactionItemData>> getItemsForTransaction(String transactionId) {
    return (select(transactionItems)
          ..where((i) => i.transactionId.equals(transactionId)))
        .get();
  }

  // ===========================================================================
  // 2. SIMPAN TRANSAKSI BARU (PENJUALAN KASIR / POS)
  // ===========================================================================

  /// Menyimpan transaksi penjualan beserta seluruh item produknya dalam 1 transaksi DB
  Future<void> simpanTransaksi({
    required TransactionsCompanion transactionHeader,
    required List<TransactionItemsCompanion> items,
  }) async {
    await transaction(() async {
      // 1. Insert Header Transaksi
      await into(transactions).insert(transactionHeader);

      // 2. Batch Insert Item Transaksi
      await batch((b) {
        b.insertAll(transactionItems, items);
      });
    });
  }

  // ===========================================================================
  // 3. SINKRONISASI DATA (SYNC QUEUE)
  // ===========================================================================

  /// Ambil semua transaksi yang belum tersinkronisasi ke server (Queue)
  Future<List<TransactionData>> getUnsyncedTransactions() {
    return (select(transactions)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Update status transaksi menjadi tersinkronisasi setelah berhasil diunggah
  Future<void> markAsSynced(String transactionId) {
    return (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(const TransactionsCompanion(isSynced: Value(true)));
  }
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return TransactionDao(db);
});
