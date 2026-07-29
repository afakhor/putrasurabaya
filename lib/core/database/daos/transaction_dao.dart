import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/constants/constant_debt_status.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Products])
class TransactionDao extends DatabaseAccessor<LocalDatabase> with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  /// 1. SIMPAN TRANSAKSI ATOMIC (Header + Items + Potong Stok)
  /// Jika salah satu langkah gagal, seluruh perubahan akan di-rollback otomatis oleh SQLite.
  Future<void> insertTransaction({
    required TransactionsCompanion transaction,
    required List<TransactionItemsCompanion> items,
  }) async {
    return transaction(() async {
      // A. Simpan Header Transaksi
      await into(transactions).insert(transaction);

      // B. Simpan Items & Potong Stok Produk
      for (final item in items) {
        await into(transactionItems).insert(item);

        // Ambil data produk terbaru untuk menghitung sisa stok
        final product = await (select(products)
              ..where((p) => p.id.equals(item.productId.value)))
            .getSingleOrNull();

        if (product != null) {
          final sisaStok = product.stock - item.quantity.value;
          await (update(products)..where((p) => p.id.equals(item.productId.value))).write(
            ProductsCompanion(
              stock: Value(sisaStok),
            ),
          );
        }
      }
    });
  }

  /// 2. STREAM TRANSAKSI HARI INI (Untuk Dashboard / Histori Kasir)
  Stream<List<TransactionData>> watchTodayTransactions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  /// 3. AMBIL TRANSAKSI BESERTA DETAIL ITEMS (Untuk Cetak Struk / Struk PDF)
  Future<TransactionWithItems?> getTransactionWithItemsById(String transactionId) async {
    final tx = await (select(transactions)..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (tx == null) return null;

    final itemList = await (select(transactionItems)
          ..where((ti) => ti.transactionId.equals(transactionId)))
        .get();

    return TransactionWithItems(transaction: tx, items: itemList);
  }

  /// 4. AMBIL DAFTAR TRANSAKSI OFFLINE (Belum Disinkronisasi ke Server)
  Future<List<TransactionData>> getUnsyncedTransactions() {
    return (select(transactions)..where((t) => t.isSynced.equals(false))).get();
  }

  /// 5. UPDATE STATUS SYNC (Setelah Sukses Dikirim ke Cloud/Server)
  Future<void> markAsSynced(List<String> transactionIds) {
    return (update(transactions)..where((t) => t.id.inValues(transactionIds)))
        .write(const TransactionsCompanion(isSynced: Value(true)));
  }

  /// 6. VOID / BATALKAN TRANSAKSI (Otomatis Mengembalikan Stok Produk)
  Future<void> voidTransaction(String transactionId) async {
    return transaction(() async {
      // Ambil daftar barang di nota yang dibatalkan
      final items = await (select(transactionItems)
            ..where((ti) => ti.transactionId.equals(transactionId)))
          .get();

      // Kembalikan stok masing-masing barang
      for (final item in items) {
        final product = await (select(products)..where((p) => p.id.equals(item.productId))).getSingleOrNull();
        if (product != null) {
          final restoredStock = product.stock + item.quantity;
          await (update(products)..where((p) => p.id.equals(item.productId))).write(
            ProductsCompanion(stock: Value(restoredStock)),
          );
        }
      }

      // Ubah status nota menjadi 'void'
      await (update(transactions)..where((t) => t.id.equals(transactionId))).write(
        const TransactionsCompanion(
          status: Value(DebtStatus.voidStatus),
        ),
      );
    });
  }
}

/// Helper Class untuk Menggabungkan Header Nota & Detail Barang
class TransactionWithItems {
  final TransactionData transaction;
  final List<TransactionItemData> items;

  TransactionWithItems({
    required this.transaction,
    required this.items,
  });
}

/// Provider Riverpod
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(localDatabaseProvider));
});
