import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';

// --- IMPORT TABEL DATABASE ---
import 'package:ud_putra_kasir/core/database/tables/finance_tables.dart';     // Payables, Receivables, Expenses
import 'package:ud_putra_kasir/core/database/tables/transaction_tables.dart'; // Transactions, TransactionItems
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';     // Products
import 'package:ud_putra_kasir/features/dashboard/models/dashboard_finance_summary.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(tables: [
  Payables,
  Receivables,
  Transactions,
  TransactionItems,
  Expenses,
  Products,
])
class DashboardDao extends DatabaseAccessor<LocalDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(LocalDatabase db) : super(db);

  /// Stream Utama menggabungkan seluruh metrik Dashboard secara Real-time
  Stream<DashboardFinanceSummary> watchFinanceSummary() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. STREAM HUTANG SUPPLIER (AP)
    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();
    final payablesStream = (selectOnly(payables)
          ..addColumns([payablesSum, payablesCount])
          ..where(payables.remainingAmount.isBiggerThanValue(0.0)))
        .watchSingle()
        .map((row) => {
              'total': row.read(payablesSum) ?? 0.0,
              'count': row.read(payablesCount) ?? 0,
            });

    // 2. STREAM PIUTANG PELANGGAN (AR)
    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();
    final receivablesStream = (selectOnly(receivables)
          ..addColumns([receivablesSum, receivablesCount])
          ..where(receivables.remainingAmount.isBiggerThanValue(0.0)))
        .watchSingle()
        .map((row) => {
              'total': row.read(receivablesSum) ?? 0.0,
              'count': row.read(receivablesCount) ?? 0,
            });

    // 3. STREAM OMSET PENJUALAN HARI INI (Eksklusi Transaksi Void)
    final totalOmset = transactions.grandTotal.sum();
    final totalCount = transactions.id.count();
    final todaySalesStream = (selectOnly(transactions)
          ..addColumns([totalOmset, totalCount])
          ..where(
            transactions.date.isBetweenValues(startOfDay, endOfDay) &
                transactions.status.equals(TransactionStatus.voided).not(),
          ))
        .watchSingle()
        .map((row) => {
              'omset': row.read(totalOmset) ?? 0.0,
              'jumlahTransaksi': row.read(totalCount) ?? 0,
            });

    // 4. STREAM ESTIMASI LABA KOTOR HARI INI
    final todayProfitStream = (select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
    ])
          ..where(
            transactions.date.isBetweenValues(startOfDay, endOfDay) &
                transactions.status.equals(TransactionStatus.voided).not(),
          ))
        .watch()
        .map((rows) {
      double profit = 0.0;
      for (final row in rows) {
        final item = row.readTable(transactionItems);
        // Menghitung HPP berdasarkan unit konversi
        final totalHpp = (item.buyPriceAtTransaction * item.conversionFactor) * item.quantity;
        final revenue = item.subtotal; 
        profit += (revenue - totalHpp);
      }
      return profit;
    });

    // 5. STREAM PENGELUARAN OPERASIONAL HARI INI
    final totalExpense = expenses.amount.sum();
    final todayExpensesStream = (selectOnly(expenses)
          ..addColumns([totalExpense])
          ..where(expenses.date.isBetweenValues(startOfDay, endOfDay)))
        .watchSingle()
        .map((row) => row.read(totalExpense) ?? 0.0);

    // 6. STREAM STOK MENIPIS (< MIN STOK)
    final productCount = products.id.count();
    final lowStockCountStream = (selectOnly(products)
          ..addColumns([productCount])
          ..where(products.stock.isSmallerOrEqual(products.minStock) &
              products.status.equals('aktif')))
        .watchSingle()
        .map((row) => row.read(productCount) ?? 0);

    // Gabungkan ke-6 Stream dengan Rx.combineLatest6
    return Rx.combineLatest6<
        Map<String, dynamic>,
        Map<String, dynamic>,
        Map<String, dynamic>,
        double,
        double,
        int,
        DashboardFinanceSummary>(
      payablesStream,
      receivablesStream,
      todaySalesStream,
      todayProfitStream,
      todayExpensesStream,
      lowStockCountStream,
      (pData, rData, sData, profit, expense, lowStock) =>
          DashboardFinanceSummary(
        totalSisaHutang: (pData['total'] as num).toDouble(),
        jumlahHutangAktif: pData['count'] as int,
        totalSisaPiutang: (rData['total'] as num).toDouble(),
        jumlahPiutangAktif: rData['count'] as int,
        omsetHariIni: (sData['omset'] as num).toDouble(),
        jumlahTransaksiHariIni: sData['jumlahTransaksi'] as int,
        labaKotorHariIni: profit,
        pengeluaranHariIni: expense,
        stokMenipisCount: lowStock,
      ),
    );
  }

  /// Get daftar produk yang stoknya menipis untuk alert/list dashboard
  Future<List<ProductData>> getLowStockProducts() {
    return (select(products)
          ..where((tbl) =>
              tbl.stock.isSmallerOrEqual(tbl.minStock) &
              tbl.status.equals('aktif'))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.stock,
                  mode: OrderingMode.asc,
                )
          ]))
        .get();
  }
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return DashboardDao(db);
});
