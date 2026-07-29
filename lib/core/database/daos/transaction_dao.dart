import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/constants/constant_debt_status.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package0:ud_putra_kasir/core/database/tables/product_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_tables.dart';
import 'package:ud_putra_kasir/core/database/daos/stock_mutation_dao.dart'; // Untuk StockMutationType

part 'transaction_dao.g.dart';

// ===========================================================================
// DATA TRANSFER OBJECT (DTO)
// ===========================================================================

class TransactionWithItems {
  final TransactionData transaction;
  final List<TransactionItemData> items;

  TransactionWithItems({
    required this.transaction,
    required this.items,
  });
}

// ===========================================================================
// TRANSACTION DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [
  Transactions,
  TransactionItems,
  Products,
  StockMutations,
])
class TransactionDao extends DatabaseAccessor<LocalDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. SIMPAN TRANSAKSI PENJUALAN ATOMIC (HEADER + ITEMS + STOK + MUTASI)
  // ===========================================================================

  /// Menyimpan transaksi penjualan kasir secara atomic.
  /// Memotong stok produk & mencatat riwayat mutasi stok secara otomatis.
  Future<void> insertTransaction({
    required TransactionsCompanion transactionHeader,
    required List<TransactionItemsCompanion> items,
  }) async {
    return transaction(() async {
      final now = DateTime.now();

      // A. Simpan Header Transaksi
      await into(transactions).insert(transactionHeader);

      final invoiceNo = transactionHeader.invoiceNumber.value;
      final txId = transactionHeader.id.value;
      final userId = transactionHeader.userId.value;

      // B. Processing Setiap Detail Item Penjualan
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        // 1. Insert Detail Item Transaksi
        await into(transactionItems).insert(item);

        // 2. Ambil Data Produk Master Terbaru
        final pId = item.productId.value;
        final product = await (select(products)
              ..where((p) => p.id.equals(pId)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('Produk dengan ID "$pId" tidak ditemukan.');
        }

        // Hitung total kuantitas unit dasar (Kuantitas * Faktor Konversi)
        final conversion = item.conversionFactor.present ? item.conversionFactor.value : 1.0;
        final actualQtyDeducted = item.quantity.value * conversion;

        final stokSebelum = product.stock;
        final stokSesudah = stokSebelum - actualQtyDeducted;

        // Validasi Proteksi Stok Minus
        if (stokSesudah < 0 && !product.allowMinusStock) {
          throw Exception(
            'Stok produk "${product.name}" tidak mencukupi! (Sisa: $stokSebelum, Dibutuhkan: $actualQtyDeducted)',
          );
        }

        // 3. Update Master Stok Produk
        await (update(products)..where((p) => p.id.equals(pId))).write(
          ProductsCompanion(
            stock: Value(stokSesudah),
            updatedAt: Value(now),
          ),
        );

        // 4. Catat Log Riwayat Mutasi Stok (Aturan Emas Mutasi)
        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: 'MUT-SLS-${now.microsecondsSinceEpoch}-$i',
            productId: pId,
            type: StockMutationType.penjualan, // 'PENJUALAN'
            quantity: -actualQtyDeducted, // Nilai minus untuk pengurangan stok
            stockBefore: stokSebelum,
            stockAfter: stokSesudah,
            hppSnapshot: item.buyPriceAtTransaction.value,
            referenceNo: txId,
            date: Value(transactionHeader.createdAt.present 
                ? transactionHeader.createdAt.value 
                : now),
            userId: Value(userId),
            notes: Value('Penjualan Kasir Nota #$invoiceNo'),
            createdAt: Value(now),
            isSynced: const Value(false),
          ),
        );
      }
    });
  }

  // ===========================================================================
  // 2. VOID / BATALKAN TRANSAKSI (PEMULIHAN STOK & CATAT REVERSAL MUTASI)
  // ===========================================================================

  /// Membatalkan Nota Transaksi, Mengembalikan Stok Produk, & Mencatat Mutasi Reversal.
  Future<void> voidTransaction({
    required String transactionId,
    required String voidByUserId,
    required String reason,
  }) async {
    return transaction(() async {
      final now = DateTime.now();

      // 1. Ambil Header Transaksi
      final tx = await (select(transactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();

      if (tx == null) {
        throw Exception('Transaksi tidak ditemukan.');
      }

      // Proteksi Double-Void
      if (tx.status == DebtStatus.voidStatus || tx.status == 'CANCELLED' || tx.status == 'VOID') {
        throw Exception('Transaksi ini sudah pernah dibatalkan sebelumnya.');
      }

      // 2. Ambil Item Transaksi
      final items = await (select(transactionItems)
            ..where((ti) => ti.transactionId.equals(transactionId)))
          .get();

      // 3. Mengembalikan Stok Produk & Mencatat Mutasi Pemulihan
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final product = await (select(products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingleOrNull();

        if (product != null) {
          final actualQtyRestored = item.quantity * item.conversionFactor;
          final stokSebelum = product.stock;
          final stokSesudah = stokSebelum + actualQtyRestored;

          // Update Stok Master Produk
          await (update(products)..where((p) => p.id.equals(item.productId))).write(
            ProductsCompanion(
              stock: Value(stokSesudah),
              updatedAt: Value(now),
            ),
          );

          // Catat Mutasi Pengembalian Stok
          await into(stockMutations).insert(
            StockMutationsCompanion.insert(
              id: 'MUT-REV-${now.microsecondsSinceEpoch}-$i',
              productId: item.productId,
              type: StockMutationType.itemMasuk, // 'ITEM_MASUK' Reversal Void
              quantity: actualQtyRestored, // Nilai positif untuk pemulihan stok
              stockBefore: stokSebelum,
              stockAfter: stokSesudah,
              hppSnapshot: item.buyPriceAtTransaction,
              referenceNo: tx.invoiceNumber,
              date: Value(now),
              userId: Value(voidByUserId),
              notes: Value('Pengembalian Stok (Void Nota #${tx.invoiceNumber}): $reason'),
              createdAt: Value(now),
              isSynced: const Value(false),
            ),
          );
        }
      }

      // 4. Ubah Status Header Nota menjadi 'VOID'
      await (update(transactions)..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(
          status: const Value(DebtStatus.voidStatus),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
    });
  }

  // ===========================================================================
  // 3. READ / QUERY TRANSAKSI
  // ===========================================================================

  /// Stream Transaksi Hari Ini (Order dari yang Terbaru)
  Stream<List<TransactionData>> watchTodayTransactions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(transactions)
          ..where((t) =>
              t.createdAt.isBetweenValues(startOfDay, endOfDay) &
              t.status.isNotIn(['CANCELLED', 'VOID', 'Batal']))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Ambil Transaksi Beserta List Items Lengkap (Untuk Print Struk / Struk PDF)
  Future<TransactionWithItems?> getTransactionWithItemsById(String transactionId) async {
    final tx = await (select(transactions)..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (tx == null) return null;

    final itemList = await (select(transactionItems)
          ..where((ti) => ti.transactionId.equals(transactionId)))
        .get();

    return TransactionWithItems(transaction: tx, items: itemList);
  }

  /// Ambil Daftar Transaksi Offline yang Belum Disinkronkan
  Future<List<TransactionData>> getUnsyncedTransactions() {
    return (select(transactions)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Update Status Sinkronisasi Server
  Future<void> markAsSynced(List<String> transactionIds) {
    return (update(transactions)..where((t) => t.id.inValues(transactionIds)))
        .write(const TransactionsCompanion(isSynced: Value(true)));
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return TransactionDao(db);
});

/// StreamProvider untuk Daftar Transaksi Hari Ini
final todayTransactionsProvider = StreamProvider<List<TransactionData>>((ref) {
  final dao = ref.watch(transactionDaoProvider);
  return dao.watchTodayTransactions();
});
