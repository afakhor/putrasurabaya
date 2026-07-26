import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../local_database.dart';
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

  // ===========================================================================
  // 1. STREAM RINGKASAN HUTANG & PIUTANG (PAYABLES & RECEIVABLES)
  // ===========================================================================

  /// Stream Ringkasan Hutang & Piutang Real-time
  Stream<DashboardFinanceSummary> watchFinanceSummary() {
    // 1. Agregasi Total Sisa Hutang (Payables)
    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();

    final payablesStream = (selectOnly(payables)
          ..addColumns([payablesSum, payablesCount])
          ..where(payables.remainingAmount.isGreaterThanValue(0.0)))
        .watchSingle()
        .map((row) {
      return {
        'total': row.read(payablesSum) ?? 0.0,
        'count': row.read(payablesCount) ?? 0,
      };
    });

    // 2. Agregasi Total Sisa Piutang (Receivables)
    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();

    final receivablesStream = (selectOnly(receivables)
          ..addColumns([receivablesSum, receivablesCount])
          ..where(receivables.remainingAmount.isGreaterThanValue(0.0)))
        .watchSingle()
        .map((row) {
      return {
        'total': row.read(receivablesSum) ?? 0.0,
        'count': row.read(receivablesCount) ?? 0,
      };
    });

    // 3. Gabungkan Kedua Stream Menggunakan Rx.combineLatest2
    return Rx.combineLatest2<Map<String, dynamic>, Map<String, dynamic>,
        DashboardFinanceSummary>(
      payablesStream,
      receivablesStream,
      (pData, rData) => DashboardFinanceSummary(
        totalSisaHutang: (pData['total'] as num).toDouble(),
        jumlahHutangAktif: pData['count'] as int,
        totalSisaPiutang: (rData['total'] as num).toDouble(),
        jumlahPiutangAktif: rData['count'] as int,
      ),
    );
  }

  // ===========================================================================
  // 2. STREAM RINGKASAN PENJUALAN HARI INI (TODAY'S SALES)
  // ===========================================================================

  /// Stream Total Omset dan Jumlah Transaksi Hari Ini
  Stream<Map<String, dynamic>> watchTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final totalOmset = transactions.total.sum();
    final totalCount = transactions.id.count();

    return (selectOnly(transactions)
          ..addColumns([totalOmset, totalCount])
          ..where(transactions.date.isBetweenValues(startOfDay, endOfDay)))
        .watchSingle()
        .map((row) {
      return {
        'omset': row.read(totalOmset) ?? 0.0,
        'jumlahTransaksi': row.read(totalCount) ?? 0,
      };
    });
  }

  // ===========================================================================
  // 3. STREAM ESTIMASI LABA KOTOR HARI INI (TODAY'S GROSS PROFIT)
  // ===========================================================================

  /// Stream Estimasi Laba Kotor Hari Ini (Omset - HPP Snapshot)
  Stream<double> watchTodayProfit() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Join Transactions & TransactionItems
    final query = select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
    ])
      ..where(transactions.date.isBetweenValues(startOfDay, endOfDay));

    return query.watch().map((rows) {
      double profit = 0.0;
      for (final row in rows) {
        final item = row.readTable(transactionItems);
        final hargaJualTotal = item.price * item.quantity;
        final hppTotal = item.buyPriceAtTransaction * item.quantity;
        profit += (hargaJualTotal - hppTotal);
      }
      return profit;
    });
  }

  // ===========================================================================
  // 4. STREAM PENGELUARAN OPERASIONAL HARI INI (TODAY'S EXPENSES)
  // ===========================================================================

  /// Stream Total Pengeluaran / Beban Hari Ini
  Stream<double> watchTodayExpenses() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final totalExpense = expenses.amount.sum();

    return (selectOnly(expenses)
          ..addColumns([totalExpense])
          ..where(expenses.date.isBetweenValues(startOfDay, endOfDay)))
        .watchSingle()
        .map((row) => row.read(totalExpense) ?? 0.0);
  }

  // ===========================================================================
  // 5. STREAM PERINGATAN STOK MENIPIS (LOW STOCK ALERT)
  // ===========================================================================

  /// Stream Jumlah Produk yang Stoknya <= MinStock
  Stream<int> watchLowStockCount() {
    final count = products.id.count();

    return (selectOnly(products)
          ..addColumns([count])
          ..where(products.stock.isLessThanOrEqualTo(products.minStock) &
              products.statusActive.equals('aktif')))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
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
