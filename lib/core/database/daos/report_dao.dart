import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

part 'report_dao.g.dart';

class LaporanLabaRugiData {
  final double totalOmset;
  final double totalHpp;
  final double labaKotor;
  final double totalPengeluaran;
  final double labaBersih;
  final int totalTransaksiCount;
  LaporanLabaRugiData({
    required this.totalOmset,
    required this.totalHpp,
    required this.labaKotor,
    required this.totalPengeluaran,
    required this.labaBersih,
    required this.totalTransaksiCount,
  });
}

class TopProductReportData {
  final String productId;
  final String productName;
  final String unitName;
  final double totalQuantity;
  final double totalOmset;
  final double totalProfit;
  TopProductReportData({
    required this.productId,
    required this.productName,
    required this.unitName,
    required this.totalQuantity,
    required this.totalOmset,
    required this.totalProfit,
  });
}

class DailyOmsetReportData {
  final DateTime date;
  final double totalOmset;
  final double totalProfit;
  final int transactionCount;
  DailyOmsetReportData({
    required this.date,
    required this.totalOmset,
    required this.totalProfit,
    required this.transactionCount,
  });
}

@DriftAccessor(tables: [
  Transactions,
  TransactionItems,
  Expenses,
  Products,
])
class ReportDao extends DatabaseAccessor<LocalDatabase> with _$ReportDaoMixin {
  ReportDao(LocalDatabase db) : super(db);

  Future<LaporanLabaRugiData> getLaporanLabaRugi(DateTime startDate, DateTime endDate) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final rows = await (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))
    ])
     ..where(transactions.date.isBetweenValues(start, end) & transactions.status.isNotIn(['CANCELLED', 'VOID', 'Batal', 'void'])))
       .get();

    double omset = 0.0;
    double totalHpp = 0.0;
    final Set<String> validTransactionIds = {};

    for (final row in rows) {
      final item = row.readTable(transactionItems);
      omset += item.subtotal;
      final qtyBase = item.quantity * item.conversionFactor;
      totalHpp += (item.buyPriceAtTransaction * qtyBase);
      validTransactionIds.add(item.transactionId);
    }

    final labaKotor = omset - totalHpp;

    // FIX: expenseDate -> date, amount.sum()
    final expenseSum = expenses.amount.sum();
    final expRow = await (selectOnly(expenses)
         ..addColumns([expenseSum])
         ..where(expenses.date.isBetweenValues(start, end)))
       .getSingle();

    final totalExpenses = expRow.read(expenseSum)?? 0.0;
    final labaBersih = labaKotor - totalExpenses;

    return LaporanLabaRugiData(
      totalOmset: omset,
      totalHpp: totalHpp,
      labaKotor: labaKotor,
      totalPengeluaran: totalExpenses,
      labaBersih: labaBersih,
      totalTransaksiCount: validTransactionIds.length,
    );
  }

  Stream<LaporanLabaRugiData> watchLaporanLabaRugi(DateTime startDate, DateTime endDate) {
    return Stream.fromFuture(getLaporanLabaRugi(startDate, endDate));
  }

  Future<List<TopProductReportData>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final rows = await (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)),
      innerJoin(products, products.id.equalsExp(transactionItems.productId)),
    ])
     ..where(transactions.date.isBetweenValues(start, end) & transactions.status.isNotIn(['CANCELLED', 'VOID', 'Batal', 'void'])))
       .get();

    final Map<String, TopProductReportData> grouped = {};

    for (final row in rows) {
      final item = row.readTable(transactionItems);
      final product = row.readTable(products);
      final pId = item.productId;
      final qty = item.quantity * item.conversionFactor;
      final omset = item.subtotal;
      final hpp = item.buyPriceAtTransaction * qty;
      final profit = omset - hpp;

      if (grouped.containsKey(pId)) {
        final existing = grouped[pId]!;
        grouped[pId] = TopProductReportData(
          productId: pId,
          productName: product.name,
          unitName: product.unit,
          totalQuantity: existing.totalQuantity + qty,
          totalOmset: existing.totalOmset + omset,
          totalProfit: existing.totalProfit + profit,
        );
      } else {
        grouped[pId] = TopProductReportData(
          productId: pId,
          productName: product.name,
          unitName: product.unit,
          totalQuantity: qty,
          totalOmset: omset,
          totalProfit: profit,
        );
      }
    }

    final list = grouped.values.toList();
    list.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return list.take(limit).toList();
  }

  Future<List<DailyOmsetReportData>> getDailyOmsetSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final validTransactions = await (select(transactions)
         ..where((tbl) => tbl.date.isBetweenValues(start, end) & tbl.status.isNotIn(['CANCELLED', 'VOID', 'Batal', 'void']))
         ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]))
       .get();

    // Ambil items untuk hitung profit harian
    final items = await (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))
    ])
     ..where(transactions.date.isBetweenValues(start, end)))
       .get();

    final Map<String, double> profitByTx = {};
    for (var r in items) {
      final it = r.readTable(transactionItems);
      final qtyBase = it.quantity * it.conversionFactor;
      final profit = it.subtotal - (it.buyPriceAtTransaction * qtyBase);
      profitByTx[it.transactionId] = (profitByTx[it.transactionId]?? 0) + profit;
    }

    final Map<String, DailyOmsetReportData> dailyMap = {};
    for (final tx in validTransactions) {
      final dateKey = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final omset = tx.grandTotal;
      final profit = profitByTx[tx.id]?? 0;

      if (dailyMap.containsKey(dateKey)) {
        final existing = dailyMap[dateKey]!;
        dailyMap[dateKey] = DailyOmsetReportData(
          date: txDate,
          totalOmset: existing.totalOmset + omset,
          totalProfit: existing.totalProfit + profit,
          transactionCount: existing.transactionCount + 1,
        );
      } else {
        dailyMap[dateKey] = DailyOmsetReportData(
          date: txDate,
          totalOmset: omset,
          totalProfit: profit,
          transactionCount: 1,
        );
      }
    }
    return dailyMap.values.toList();
  }
}

final reportDaoProvider = Provider<ReportDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ReportDao(db);
});

final monthlyLabaRugiProvider = StreamProvider<LaporanLabaRugiData>((ref) {
  final dao = ref.watch(reportDaoProvider);
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  return dao.watchLaporanLabaRugi(firstDayOfMonth, lastDayOfMonth);
});