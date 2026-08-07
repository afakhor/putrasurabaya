import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../local_database.dart';
import '../tables/finance_table.dart';
import '../tables/transaction_table.dart';
import '../tables/product_table.dart';
import '../tables/audit_log_table.dart'; // <-- INI SUDAH INCLUDE AuditLogs + FraudAlerts
import 'dashboard_finance_summary.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(tables: [Payables, Receivables, Transactions, TransactionItems, Expenses, Products, AuditLogs, FraudAlerts])
class DashboardDao extends DatabaseAccessor<LocalDatabase> with _$DashboardDaoMixin {
  DashboardDao(LocalDatabase db) : super(db);

  Stream<DashboardFinanceSummary> watchFinanceSummary() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();
    final payablesStream = (selectOnly(payables)..addColumns([payablesSum, payablesCount])..where(payables.remainingAmount.isBiggerThanValue(0.0))).watchSingle().map((r) => {'total': r.read(payablesSum)?? 0.0, 'count': r.read(payablesCount)?? 0});
    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();
    final receivablesStream = (selectOnly(receivables)..addColumns([receivablesSum, receivablesCount])..where(receivables.remainingAmount.isBiggerThanValue(0.0))).watchSingle().map((r) => {'total': r.read(receivablesSum)?? 0.0, 'count': r.read(receivablesCount)?? 0});
    final totalOmset = transactions.grandTotal.sum();
    final totalCount = transactions.id.count();
    final salesStream = (selectOnly(transactions)..addColumns([totalOmset, totalCount])..where(transactions.date.isBetweenValues(start, end))).watchSingle().map((r) => {'omset': r.read(totalOmset)?? 0.0, 'jumlah': r.read(totalCount)?? 0});
    final profitStream = (select(transactionItems).join([innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))])..where(transactions.date.isBetweenValues(start, end))).watch().map((rows) { double profit = 0; for (final row in rows) { final i = row.readTable(transactionItems); profit += i.subtotal - (i.buyPriceAtTransaction * i.conversionFactor * i.quantity); } return profit; });
    final totalExpense = expenses.amount.sum();
    final expenseStream = (selectOnly(expenses)..addColumns([totalExpense])..where(expenses.date.isBetweenValues(start, end))).watchSingle().map((r) => r.read(totalExpense)?? 0.0);
    final productCount = products.id.count();
    final lowStockStream = (selectOnly(products)..addColumns([productCount])..where(products.stock.isSmallerThanValue(5))).watchSingle().map((r) => r.read(productCount)?? 0);
    return Rx.combineLatest6(payablesStream, receivablesStream, salesStream, profitStream, expenseStream, lowStockStream, (p, r, s, profit, expense, low) => DashboardFinanceSummary(totalSisaHutang: (p['total'] as num).toDouble(), jumlahHutangAktif: p['count'] as int, totalSisaPiutang: (r['total'] as num).toDouble(), jumlahPiutangAktif: r['count'] as int, omsetHariIni: (s['omset'] as num).toDouble(), jumlahTransaksiHariIni: s['jumlah'] as int, labaKotorHariIni: profit, pengeluaranHariIni: expense, stokMenipisCount: low));
  }

  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)..where((t) => t.isResolved.equals(false))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  }

  Stream<List<AuditLogData>> watchRecentAuditLogs(int limit) {
    return (select(auditLogs)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])..limit(limit)).watch();
  }

  Stream<String> watchOwnerRiskStatus() {
    return watchFinanceSummary().map((s) {
      if (s.totalSisaHutang > s.totalSisaPiutang * 2) return 'RISIKO TINGGI';
      if (s.stokMenipisCount > 10) return 'STOK KRITIS';
      return 'AMAN';
    });
  }

  Future<List<ProductData>> getLowStockProducts() {
    return (select(products)..where((t) => t.stock.isSmallerThanValue(5))).get();
  }
}

final dashboardDaoProvider = Provider<DashboardDao>((ref) => ref.watch(localDatabaseProvider).dashboardDao);