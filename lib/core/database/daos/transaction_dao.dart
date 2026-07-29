import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Products, StockMutations, Receivables, DebtPayments])
class TransactionDao extends DatabaseAccessor<LocalDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(LocalDatabase db) : super(db);

  /// POS: SIMPAN TRANSAKSI PENJUALAN (ACID Transaction + Validasi Anti-Minus)
  Future<void> simpanTransaksiPOS({
    required TransactionsCompanion transactionHeader,
    required List<TransactionItemsCompanion> items,
    required String userId,
    DateTime? dueDate,
  }) async {
    await transaction(() async {
      // 1. Simpan Header Transaksi Penjualan
      await into(transactions).insert(transactionHeader);

      // 2. Process Keranjang Item
      for (final item in items) {
        final pId = item.productId.value;
        final qtyJual = item.quantity.value;

        // Ambil Stok Terbaru Master Produk
        final product = await (select(products)..where((p) => p.id.equals(pId))).getSingle();
        final stokSebelum = product.stock;
        final stokSesudah = stokSebelum - qtyJual;

        // VALIDASI EMAS: Cek Jika Stok Minus & System Diset Tidak Boleh Minus
        if (stokSesudah < 0 && !product.allowMinusStock) {
          throw Exception('Transaksi Ditolak: Stok "${product.name}" habis/tidak mencukupi (Sisa: ${stokSebelum.toInt()}).');
        }

        // Insert Item Transaksi (Simpan HPP Snapshot saat transaksi)
        await into(transactionItems).insert(item.copyWith(
          buyPriceAtTransaction: Value(product.buyPrice),
        ));

        // Update Stok Produk
        await (update(products)..where((p) => p.id.equals(pId))).write(
          ProductsCompanion(stock: Value(stokSesudah)),
        );

        // Catat Log Mutasi Stok PENJUALAN
        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: 'MUT-${DateTime.now().millisecondsSinceEpoch}-$pId',
            productId: pId,
            type: 'PENJUALAN',
            quantity: -qtyJual, // Nilai minus untuk pengurangan
            stockBefore: stokSebelum,
            stockAfter: stokSesudah,
            hppSnapshot: product.buyPrice,
            referenceNo: transactionHeader.invoiceNo.value,
            userId: Value(userId),
            notes: Value('Penjualan Kasir INV: ${transactionHeader.invoiceNo.value}'),
          ),
        );
      }

      // 3. Handle Piutang Customer (AR)
      final debtAmount = transactionHeader.debt.value;
      final paidAmount = transactionHeader.paid.value;
      final customerId = transactionHeader.customerId.value;

      if (debtAmount > 0 && customerId != null) {
        final receivableId = 'RC-${transactionHeader.id.value}';
        final status = DebtStatus.tentukanStatus(debtAmount, paidAmount);

        await into(receivables).insert(
          ReceivablesCompanion.insert(
            id: receivableId,
            transactionId: transactionHeader.id.value,
            customerId: customerId,
            totalAmount: transactionHeader.total.value,
            paidAmount: Value(paidAmount),
            remainingAmount: debtAmount,
            dueDate: dueDate ?? DateTime.now().add(const Duration(days: 14)),
            status: Value(status),
          ),
        );
      }
    });
  }

  /// RETUR PENJUALAN
  Future<void> prosesReturPenjualan({
    required String transactionId,
    required String productId,
    required double qtyRetur,
    required String userId,
    required String alasan,
  }) async {
    await transaction(() async {
      final product = await (select(products)..where((p) => p.id.equals(productId))).getSingle();
      final stokSebelum = product.stock;
      final stokSesudah = stokSebelum + qtyRetur;

      // Update Kembalikan Stok
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(stock: Value(stokSesudah)),
      );

      // Log Mutasi Retur
      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          type: 'RETUR_PENJUALAN',
          quantity: qtyRetur,
          stockBefore: stokSebelum,
          stockAfter: stokSesudah,
          hppSnapshot: product.buyPrice,
          referenceNo: transactionId,
          userId: Value(userId),
          notes: Value('Retur Penjualan: $alasan'),
        ),
      );
    });
  }
}

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(localDatabaseProvider));
});
