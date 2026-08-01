import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'dashboard_finance_summary.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(tables: [
  Payables, Receivables, Transactions, TransactionItems, Expenses, Products,
  AuditLogs, FraudAlerts
])
class DashboardDao extends DatabaseAccessor<LocalDatabase> with _$DashboardDaoMixin {
  DashboardDao(LocalDatabase db) : super(db);

  Stream<DashboardFinanceSummary> watchFinanceSummary() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();
    final payablesStream = (selectOnly(payables)
         ..addColumns([payablesSum, payablesCount])
         ..where(payables.remainingAmount.isBiggerThanValue(0.0)))
       .watchSingle()
       .map((row) => {'total': row.read(payablesSum)?? 0.0, 'count': row.read(payablesCount)?? 0});

    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();
    final receivablesStream = (selectOnly(receivables)
         ..addColumns([receivablesSum, receivablesCount])
         ..where(receivables.remainingAmount.isBiggerThanValue(0.0)))
       .watchSingle()
       .map((row) => {'total': row.read(receivablesSum)?? 0.0, 'count': row.read(receivablesCount)?? 0});

    final totalOmset = transactions.grandTotal.sum();
    final totalCount = transactions.id.count();
    final todaySalesStream = (selectOnly(transactions)
         ..addColumns([totalOmset, totalCount])
         ..where(transactions.date.isBetweenValues(startOfDay, endOfDay)))
       .watchSingle()
       .map((row) => {'omset': row.read(totalOmset)?? 0.0, 'jumlahTransaksi': row.read(totalCount)?? 0});

    final todayProfitStream = (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)),
    ])..where(transactions.date.isBetweenValues(startOfDay, endOfDay)))
       .watch()
       .map((rows) {
      double profit = 0.0;
      for (final row in rows) {
        final item = row.readTable(transactionItems);
        final totalHpp = (item.buyPriceAtTransaction * item.conversionFactor) * item.quantity;
        profit += (item.subtotal - totalHpp);
      }
      return profit;
    });

    final totalExpense = expenses.amount.sum();
    final todayExpensesStream = (selectOnly(expenses)
         ..addColumns([totalExpense])
         ..where(expenses.date.isBetweenValues(startOfDay, endOfDay)))
       .watchSingle()
       .map((row) => row.read(totalExpense)?? 0.0);

    // FIX: Products gak ada minStock & status, pakai stock < 5
    final productCount = products.id.count();
    final lowStockCountStream = (selectOnly(products)
         ..addColumns([productCount])
         ..where(products.stock.isSmallerThanValue(5)))
       .watchSingle()
       .map((row) => row.read(productCount)?? 0);

    return Rx.combineLatest6(payablesStream, receivablesStream, todaySalesStream,
        todayProfitStream, todayExpensesStream, lowStockCountStream,
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
              // alias biar dashboard_owner_page lama tetap jalan
              todaySales: (sData['omset'] as num).toDouble(),
              totalReceivable: (rData['total'] as num).toDouble(),
            ));
  }

  Future<List<ProductData>> getLowStockProducts() {
    return (select(products)..where((tbl) => tbl.stock.isSmallerThanValue(5))).get();
  }

  // TAMBAHAN BIAR audit_fraud_page & dashboard_owner_page GAK ERROR LAGI
  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)..orderBy([(t) => OrderingTerm.desc(t.createdAt))]).watch();
  }

  Stream<List<AuditLogData>> watchRecentAuditLogs(int limit) {
    return (select(auditLogs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])..limit(limit)).watch();
  }

  Stream<String> watchOwnerRiskStatus() {
    return watchFinanceSummary().map((s) {
      if (s.totalSisaHutang > s.totalSisaPiutang * 2) return 'RISIKO TINGGI';
      if (s.stokMenipisCount > 10) return 'STOK KRITIS';
      return 'AMAN';
    });
  }
}

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.dashboardDao;
});