import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';
import 'package0:ud_putra_kasir/core/database/tables/finance_table.dart';

part 'report_dao.g.dart';

class LaporanLabaRugiData {
  final double totalOmset;
  final double totalHpp;
  final double labaKotor;
  final double totalPengeluaran;
  final double labaBersih;

  LaporanLabaRugiData({
    required this.totalOmset,
    required this.totalHpp,
    required this.labaKotor,
    required this.totalPengeluaran,
    required this.labaBersih,
  });
}

@DriftAccessor(tables: [Transactions, TransactionItems, Expenses])
class ReportDao extends DatabaseAccessor<LocalDatabase> with _$ReportDaoMixin {
  ReportDao(LocalDatabase db) : super(db);

  /// LAPORAN LABA RUGI REAL-TIME PER PERIODE
  Future<LaporanLabaRugiData> getLaporanLabaRugi(DateTime startDate, DateTime endDate) async {
    // 1. Ambil Semua Item Transaksi pada Periode
    final rows = await (select(transactionItems).join([
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))
    ])..where(transactions.date.isBetweenValues(startDate, endDate))).get();

    double omset = 0.0;
    double hpp = 0.0;

    for (final row in rows) {
      final item = row.readTable(transactionItems);
      omset += (item.price * item.quantity);
      hpp += (item.buyPriceAtTransaction * item.quantity); // Menggunakan HPP Snapshot akurat
    }

    final labaKotor = omset - hpp;

    // 2. Hitung Pengeluaran (Expenses)
    final expenseSum = expenses.amount.sum();
    final expRow = await (selectOnly(expenses)
          ..addColumns([expenseSum])
          ..where(expenses.date.isBetweenValues(startDate, endDate)))
        .getSingle();

    final totalExpenses = expRow.read(expenseSum) ?? 0.0;
    final labaBersih = labaKotor - totalExpenses;

    return LaporanLabaRugiData(
      totalOmset: omset,
      totalHpp: hpp,
      labaKotor: labaKotor,
      totalPengeluaran: totalExpenses,
      labaBersih: labaBersih,
    );
  }
}

final reportDaoProvider = Provider<ReportDao>((ref) {
  return ReportDao(ref.watch(localDatabaseProvider));
});
