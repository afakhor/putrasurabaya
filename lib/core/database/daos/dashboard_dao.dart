import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../local_database.dart';
import '../tables/finance_table.dart'; // <--- TAMBAHKAN IMPORT INI
import '../../../features/dashboard/models/dashboard_finance_summary.dart';

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

    // 1. Stream Hutang
    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();
    final payablesStream = (selectOnly(payables)
          ..addColumns([payablesSum, payablesCount])
          ..where(payables.remainingAmount.isGreaterThan(0.0))) // Fix: isGreaterThan
        .watchSingle()
        .map((row) => {
              'total': row.read(payablesSum) ?? 0.0,
              'count': row.read(payablesCount) ?? 0,
            });

    // 2. Stream Piutang
    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();
    final receivablesStream = (selectOnly(receivables)
          ..addColumns([receivablesSum, receivablesCount])
          ..where(receivables.remainingAmount.isGreaterThan(0.0))) // Fix: isGreaterThan
        .watchSingle()
        .map((row) => {
              'total': row.read(receivablesSum) ?? 0.0,
              'count': row.read(receivablesCount) ?? 0,
            });

    // 3. Stream Omset
    final totalOmset = transactions.total.sum();
    final totalCount = transactions.id.count();
    final todaySalesStream = (selectOnly(transactions)
          ..addColumns([totalOmset, totalCount])
          ..where(transactions.date.isBetweenValues(startOfDay, endOfDay)))
        .watchSingle()
        .map((row) => {
              'omset': row.read(totalOmset) ?? 0.0,
              'jumlahTransaksi': row.read(totalCount) ?? 0,
            });

    // 4. Stream Estimasi Laba (Fix: Chaining yang benar)
    final todayProfitStream = (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)),
    ])
      ..where(transactions.date.isBetweenValues(startOfDay, endOfDay)))
      .watch()
      .map((rows) {
        double profit = 0.0;
        for (final row in rows) {
          final item = row.readTable(transactionItems);
          profit += ((item.price - item.buyPriceAtTransaction) * item.quantity);
        }
        return profit;
      });

    // 5. Stream Pengeluaran
    final totalExpense = expenses.amount.sum();
    final todayExpensesStream = (selectOnly(expenses)
          ..addColumns([totalExpense])
          ..where(expenses.date.isBetweenValues(startOfDay, endOfDay)))
        .watchSingle()
        .map((row) => row.read(totalExpense) ?? 0.0);

    // 6. Stream Stok Menipis
    final productCount = products.id.count();
    final lowStockCountStream = (selectOnly(products)
          ..addColumns([productCount])
          ..where(products.stock.isLessThanOrEqualTo(products.minStock) &
              products.statusActive.equals('aktif')))
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
      (pData, rData, sData, profit, expense, lowStock) => DashboardFinanceSummary(
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

  /// Get daftar produk yang stoknya menipis
  Future<List<ProductData>> getLowStockProducts() {
    return (select(products)
          ..where((tbl) =>
              tbl.stock.isLessThanOrEqualTo(tbl.minStock) &
              tbl.statusActive.equals('aktif'))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.stock, mode: OrderingMode.asc)
          ]))
        .get();
  }
}
