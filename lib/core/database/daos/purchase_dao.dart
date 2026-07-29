import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/purchase_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_tables.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'purchase_dao.g.dart';

@DriftAccessor(tables: [
  Purchases,
  PurchaseItems,
  Products,
  StockMutations,
  Payables,
  DebtPayments,
])
class PurchaseDao extends DatabaseAccessor<LocalDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. PROSES PEMBELIAN STOK & PERHITUNGAN MOVING AVERAGE HPP
  // ===========================================================================

  /// BARANG MASUK / PEMBELIAN DARI SUPPLIER
  /// (Aturan Emas Mutasi, Auto-Update Stok, Moving Average HPP, & Pencatatan Hutang AP)
  Future<void> simpanPembelianSupplier({
    required PurchasesCompanion purchaseHeader,
    required List<PurchaseItemsCompanion> items,
    required String userId,
    DateTime? dueDate,
  }) async {
    await transaction(() async {
      final now = DateTime.now();

      // 1. Simpan Header Pembelian (Set flag sync)
      final headerWithSync = purchaseHeader.copyWith(
        isSynced: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await into(purchases).insert(headerWithSync);

      double totalPurchaseAmount = 0.0;
      int itemIndex = 0;

      // 2. Loop Setiap Item Pembelian
      for (final rawItem in items) {
        itemIndex++;

        // Simpan Item Pembelian
        final itemWithSync = rawItem.copyWith(
          isSynced: const Value(false),
        );
        await into(purchaseItems).insert(itemWithSync);

        final pId = rawItem.productId.value;
        final qtyBeliInput = rawItem.quantity.value;
        
        // Memperhitungkan konversi satuan jika beli per Dus/Bal ke Pcs
        final conversion = rawItem.conversionFactor.present
            ? rawItem.conversionFactor.value
            : 1.0;
        final qtyBeliBaseUnit = qtyBeliInput * conversion;

        final subtotalItem = rawItem.subtotal.value;
        totalPurchaseAmount += subtotalItem;

        // Harga Beli Efektif Per Satuan Dasar (Base Unit)
        final hargaBeliPerBaseUnit = qtyBeliBaseUnit > 0
            ? subtotalItem / qtyBeliBaseUnit
            : rawItem.buyPrice.value;

        // Fetch Data Produk Saat Ini
        final product = await (select(products)..where((p) => p.id.equals(pId)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('Produk dengan ID $pId tidak ditemukan');
        }

        final stokLama = product.stock;
        final hppLama = product.buyPrice;

        final stokBaru = stokLama + qtyBeliBaseUnit;

        // Hitung Moving Average HPP (Harga Pokok Penjualan Rata-Rata Tertimbang)
        double hppBaru = hppLama;
        if (stokBaru > 0) {
          hppBaru =
              ((stokLama * hppLama) + (qtyBeliBaseUnit * hargaBeliPerBaseUnit)) /
                  stokBaru;
        }

        // Update Master Produk (Stok, HPP, Timestamp, Flag Sync)
        await (update(products)..where((p) => p.id.equals(pId))).write(
          ProductsCompanion(
            stock: Value(stokBaru),
            buyPrice: Value(hppBaru),
            isSynced: const Value(false),
            updatedAt: Value(now),
          ),
        );

        // Catat Mutasi Stok PEMBELIAN (ID unik menggunakan microseconds + index)
        final mutationId =
            'MUT-${now.microsecondsSinceEpoch}-$itemIndex-$pId';

        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: mutationId,
            productId: pId,
            type: 'PEMBELIAN',
            quantity: qtyBeliBaseUnit,
            stockBefore: stokLama,
            stockAfter: stokBaru,
            hppSnapshot: hppBaru,
            referenceNo: purchaseHeader.invoiceNo.value,
            userId: Value(userId),
            notes: Value('Pembelian Nota: ${purchaseHeader.invoiceNo.value}'),
            isSynced: const Value(false),
            createdAt: Value(now),
          ),
        );
      }

      // 3. Jika Pembelian Tempo / Ada Hutang Ke Supplier (AP - Account Payable)
      final debtAmount = purchaseHeader.debtAmount.value;
      final paidAmount = purchaseHeader.paidAmount.value;

      if (debtAmount > 0) {
        final payableId = 'AP-${purchaseHeader.id.value}';
        final status = DebtStatus.tentukanStatus(debtAmount, paidAmount);

        await into(payables).insert(
          PayablesCompanion.insert(
            id: payableId,
            purchaseRef: purchaseHeader.invoiceNo.value,
            supplierId: purchaseHeader.supplierId.value,
            totalAmount: totalPurchaseAmount,
            paidAmount: Value(paidAmount),
            remainingAmount: debtAmount,
            dueDate: dueDate ?? now.add(const Duration(days: 30)),
            status: Value(status),
            isSynced: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        // Catat DP jika ada pembayaran di awal
        if (paidAmount > 0) {
          await into(debtPayments).insert(
            DebtPaymentsCompanion.insert(
              id: 'PAY-AP-${now.microsecondsSinceEpoch}',
              refId: payableId,
              type: 'payable_pay',
              amount: paidAmount,
              paymentMethod: purchaseHeader.paymentMethod.value,
              notes: const Value('DP Pembelian Stok Supplier'),
              isSynced: const Value(false),
              paymentDate: Value(now),
            ),
          );
        }
      }
    });
  }

  // ===========================================================================
  // 2. QUERY & STREAM RIWAYAT PEMBELIAN
  // ===========================================================================

  /// Stream Riwayat Pembelian Terbaru (Untuk Dashboard / Laporan Pembelian)
  Stream<List<PurchaseData>> watchRecentPurchases({int limit = 50}) {
    return (select(purchases)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.purchaseDate, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  /// Stream Riwayat Pembelian Berdasarkan Supplier
  Stream<List<PurchaseData>> watchPurchasesBySupplier(String supplierId) {
    return (select(purchases)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.purchaseDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Ambil Detail Header Pembelian berdasarkan ID Nota/Invoice
  Future<PurchaseData?> getPurchaseById(String id) {
    return (select(purchases)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Ambil Rincian Barang (Item) dari 1 Nota Pembelian
  Future<List<PurchaseItemData>> getPurchaseItems(String purchaseId) {
    return (select(purchaseItems)
          ..where((tbl) => tbl.purchaseId.equals(purchaseId)))
        .get();
  }

  /// Get Pembelian Lengkap beserta Daftar Barang (DTO Result)
  Future<PurchaseWithItemsDetail?> getPurchaseWithDetails(
      String purchaseId) async {
    final header = await getPurchaseById(purchaseId);
    if (header == null) return null;

    final items = await getPurchaseItems(purchaseId);

    return PurchaseWithItemsDetail(
      purchase: header,
      items: items,
    );
  }
}

// ===========================================================================
// DTO HELPER CLASS
// ===========================================================================

class PurchaseWithItemsDetail {
  final PurchaseData purchase;
  final List<PurchaseItemData> items;

  PurchaseWithItemsDetail({
    required this.purchase,
    required this.items,
  });
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return PurchaseDao(db);
});
