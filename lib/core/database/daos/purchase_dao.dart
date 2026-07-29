import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package0:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/constants/constant_debt_status.dart';

part 'purchase_dao.g.dart';

// ===========================================================================
// DATA TRANSFER OBJECT (DTO) UNTUK VIEW / PRINT NOTA BELI
// ===========================================================================

class PurchaseWithSupplier {
  final PayableData purchase;
  final SupplierData? supplier;

  PurchaseWithSupplier({
    required this.purchase,
    this.supplier,
  });
}

// ===========================================================================
// PURCHASE DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [
  Payables,
  DebtPayments,
  Products,
  StockMutations,
  Suppliers,
])
class PurchaseDao extends DatabaseAccessor<LocalDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. INPUT PEMBELIAN ATOMIC (TAMBAH STOK + HPP MOVING AVERAGE + HUTANG)
  // ===========================================================================

  /// Mencatat Pembelian dari Supplier.
  /// Secara otomatis:
  /// - Menambah stok produk master
  /// - Menghitung ulang HPP Moving Average: ((StokLama * HPP) + (QtyBeli * HargaBeliBaru)) / TotalStokBaru
  /// - Mencatat Log Mutasi Stok ('PEMBELIAN')
  /// - Mencatat Hutang Usaha (Payables) & Pembayaran Uang Muka/Tunai
  Future<String> insertPurchaseTransaction({
    required String purchaseInvoiceNo,
    required String supplierId,
    required List<PurchaseItemInput> items,
    required double totalAmount,
    required double paidAmount, // DP atau Pembayaran Tunai
    required DateTime invoiceDate,
    required DateTime dueDate,
    required String paymentMethod, // 'TUNAI', 'TRANSFER', 'TEMPO'
    required String userId,
    String? notes,
  }) async {
    return transaction(() async {
      final now = DateTime.now();
      final payableId = 'PAY-${now.microsecondsSinceEpoch}';
      final remainingAmount = totalAmount - paidAmount;

      // Tentukan Status Hutang (LUNAS, SEBAGIAN, UNPAID)
      final statusHutang = DebtStatus.tentukanStatus(remainingAmount, paidAmount);

      // A. Catat Header Hutang Usaha / Pembelian (Payables)
      await into(payables).insert(
        PayablesCompanion.insert(
          id: payableId,
          supplierId: supplierId,
          purchaseInvoiceNo: Value(purchaseInvoiceNo),
          totalAmount: totalAmount,
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remainingAmount < 0 ? 0.0 : remainingAmount),
          dueDate: Value(dueDate),
          status: Value(statusHutang),
          notes: Value(notes),
          createdAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      // B. Update Total Hutang Master Supplier (jika ada sisa hutang)
      if (remainingAmount > 0) {
        final supplier = await (select(suppliers)
              ..where((s) => s.id.equals(supplierId)))
            .getSingleOrNull();

        if (supplier != null) {
          final newTotalDebt = supplier.totalDebt + remainingAmount;
          await (update(suppliers)..where((s) => s.id.equals(supplierId))).write(
            SuppliersCompanion(
              totalDebt: Value(newTotalDebt),
              updatedAt: Value(now),
            ),
          );
        }
      }

      // C. Catat Uang Muka / Pelunasan Tunai Pertama
      if (paidAmount > 0) {
        await into(debtPayments).insert(
          DebtPaymentsCompanion.insert(
            id: 'PMT-${now.microsecondsSinceEpoch}',
            refId: payableId,
            type: 'payable_pay', // Pembayaran Hutang Ke Supplier
            amount: paidAmount,
            paymentMethod: Value(paymentMethod),
            notes: Value('Pembayaran Beli Nota #$purchaseInvoiceNo'),
            createdAt: Value(now),
            isSynced: const Value(false),
          ),
        );
      }

      // D. Processing Setiap Produk: Tambah Stok, Hitung Moving Average HPP, & Mutasi
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final product = await (select(products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('Produk dengan ID "${item.productId}" tidak ditemukan.');
        }

        final stokLama = product.stock;
        final hppLama = product.buyPrice;
        final totalQtyMasuk = item.quantity * item.conversionFactor;

        final stokBaru = stokLama + totalQtyMasuk;

        // Formula HPP Moving Average
        double hppBaru = hppLama;
        if (stokBaru > 0) {
          hppBaru = ((stokLama * hppLama) + (totalQtyMasuk * item.buyPricePerUnit)) / stokBaru;
        }

        // 1. Update Master Stok & HPP Produk
        await (update(products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            stock: Value(stokBaru),
            buyPrice: Value(hppBaru), // HPP Terupdate Otomatis
            updatedAt: Value(now),
          ),
        );

        // 2. Catat Log Mutasi Stok 'PEMBELIAN'
        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: 'MUT-BUY-${now.microsecondsSinceEpoch}-$i',
            productId: item.productId,
            type: 'PEMBELIAN',
            quantity: totalQtyMasuk, // Nilai positif (Stok Masuk)
            stockBefore: stokLama,
            stockAfter: stokBaru,
            hppSnapshot: hppBaru,
            referenceNo: purchaseInvoiceNo,
            date: Value(invoiceDate),
            userId: Value(userId),
            notes: Value('Pembelian Nota Supplier #${purchaseInvoiceNo}'),
            createdAt: Value(now),
            isSynced: const Value(false),
          ),
        );
      }

      return payableId;
    });
  }

  // ===========================================================================
  // 2. QUERY & STREAM UNTUK DAFTAR PEMBELIAN / HUTANG
  // ===========================================================================

  /// Stream Daftar Hutang Usaha Ke Supplier yang Belum Lunas
  Stream<List<PayableData>> watchUnpaidPayables() {
    return (select(payables)
          ..where((p) => p.remainingAmount.isGreaterThanValue(0.0))
          ..orderBy([(p) => OrderingTerm(expression: p.dueDate)]))
        .watch();
  }

  /// Stream Riwayat Seluruh Transaksi Pembelian (Terbaru Dulu)
  Stream<List<PayableData>> watchPurchaseHistory() {
    return (select(payables)
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Ambil Detail Pembelian Beserta Data Supplier
  Future<PurchaseWithSupplier?> getPurchaseById(String payableId) async {
    final purchase = await (select(payables)..where((p) => p.id.equals(payableId))).getSingleOrNull();
    if (purchase == null) return null;

    final supplier = await (select(suppliers)..where((s) => s.id.equals(purchase.supplierId))).getSingleOrNull();

    return PurchaseWithSupplier(
      purchase: purchase,
      supplier: supplier,
    );
  }
}

// ===========================================================================
// HELPER CLASS / INPUT MODEL
// ===========================================================================

class PurchaseItemInput {
  final String productId;
  final double quantity; // Kuantitas Kemasan (misal: 2 Dus)
  final double conversionFactor; // Faktor Konversi (1 Dus = 24 Pcs, maka factor = 24)
  final double buyPricePerUnit; // Harga Beli per Unit Dasar (Pcs)

  PurchaseItemInput({
    required this.productId,
    required this.quantity,
    this.conversionFactor = 1.0,
    required this.buyPricePerUnit,
  });
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return PurchaseDao(db);
});

/// StreamProvider untuk Hutang Supplier Jatuh Tempo
final unpaidPayablesStreamProvider = StreamProvider<List<PayableData>>((ref) {
  final dao = ref.watch(purchaseDaoProvider);
  return dao.watchUnpaidPayables();
});
