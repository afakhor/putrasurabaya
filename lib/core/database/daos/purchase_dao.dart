import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/purchase_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'purchase_dao.g.dart';

@DriftAccessor(tables: [Purchases, PurchaseItems, Products, StockMutations, Payables, DebtPayments])
class PurchaseDao extends DatabaseAccessor<LocalDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(LocalDatabase db) : super(db);

  /// BARANG MASUK / PEMBELIAN DARI SUPPLIER (Aturan Emas Mutasi & Moving Average HPP)
  Future<void> simpanPembelianSupplier({
    required PurchasesCompanion purchaseHeader,
    required List<PurchaseItemsCompanion> items,
    required String userId,
    DateTime? dueDate,
  }) async {
    await transaction(() async {
      // 1. Simpan Header Pembelian
      await into(purchases).insert(purchaseHeader);

      double totalPurchaseAmount = 0.0;

      // 2. Loop Setiap Item Pembelian
      for (final item in items) {
        await into(purchaseItems).insert(item);

        final pId = item.productId.value;
        final qtyBeli = item.quantity.value;
        final hargaBeliSatuan = item.buyPrice.value;
        totalPurchaseAmount += item.subtotal.value;

        // Fetch Data Produk Saat Ini
        final product = await (select(products)..where((p) => p.id.equals(pId))).getSingle();
        final stokLama = product.stock;
        final hppLama = product.buyPrice;

        final stokBaru = stokLama + qtyBeli;

        // Hitung Moving Average HPP
        double hppBaru = hppLama;
        if (stokBaru > 0) {
          hppBaru = ((stokLama * hppLama) + (qtyBeli * hargaBeliSatuan)) / stokBaru;
        }

        // Update Master Produk
        await (update(products)..where((p) => p.id.equals(pId))).write(
          ProductsCompanion(
            stock: Value(stokBaru),
            buyPrice: Value(hppBaru),
          ),
        );

        // Catat Mutasi Stok PEMBELIAN
        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: 'MUT-${DateTime.now().millisecondsSinceEpoch}-$pId',
            productId: pId,
            type: 'PEMBELIAN',
            quantity: qtyBeli,
            stockBefore: stokLama,
            stockAfter: stokBaru,
            hppSnapshot: hppBaru,
            referenceNo: purchaseHeader.invoiceNo.value,
            userId: Value(userId),
            notes: Value('Pembelian Nota: ${purchaseHeader.invoiceNo.value}'),
          ),
        );
      }

      // 3. Jika Pembelian Tempo / Ada Hutang Ke Supplier (AP)
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
            dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
            status: Value(status),
          ),
        );

        if (paidAmount > 0) {
          await into(debtPayments).insert(
            DebtPaymentsCompanion.insert(
              id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
              refId: payableId,
              type: 'payable_pay',
              amount: paidAmount,
              paymentMethod: purchaseHeader.paymentMethod.value,
              notes: const Value('DP Pembelian Stok Supplier'),
            ),
          );
        }
      }
    });
  }
}

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  return PurchaseDao(ref.watch(localDatabaseProvider));
});
