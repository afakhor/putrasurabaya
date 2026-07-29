import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';

part 'report_dao.g.dart';

// ===========================================================================
// DATA TRANSFER OBJECTS (DTO) UNTUK LAPORAN
// ===========================================================================

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

// ===========================================================================
// REPORT DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [
  Transactions,
  TransactionItems,
  Expenses,
  Products,
])
class ReportDao extends DatabaseAccessor<LocalDatabase> with _$ReportDaoMixin {
  ReportDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. LAPORAN LABA RUGI (PROFIT & LOSS)
  // ===========================================================================

  /// Kalkulasi Laporan Laba Rugi Real-Time berdasarkan Rentang Tanggal
  Future<LaporanLabaRugiData> getLaporanLabaRugi(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Normalisasi waktu agar mencakup seluruh jam di hari terakhir
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // 1. Ambil Semua Item Transaksi yang Sah (Abaikan transaksi CANCELLED / VOID)
    final rows = await (select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      )
    ])
      ..where(
        transactions.createdAt.isBetweenValues(start, end) &
            transactions.status.isNotIn(['CANCELLED', 'VOID', 'Batal']),
      ))
        .get();

    double omset = 0.0;
    double totalHpp = 0.0;
    final Set<String> validTransactionIds = {};

    for (final row in rows) {
      final item = row.readTable(transactionItems);

      // Omset dihitung dari subtotal item (sudah dipotong diskon item jika ada)
      omset += item.subtotal;

      // HPP menggunakan Snapshot HPP Beli saat transaksi terjadi
      final qtyBase = item.quantity * item.conversionFactor;
      totalHpp += (item.buyPriceAtTransaction * qtyBase);

      validTransactionIds.add(item.transactionId);
    }

    final labaKotor = omset - totalHpp;

    // 2. Hitung Pengeluaran Operasional (Expenses)
    final expenseSum = expenses.amount.sum();
    final expRow = await (selectOnly(expenses)
          ..addColumns([expenseSum])
          ..where(expenses.expenseDate.isBetweenValues(start, end)))
        .getSingle();

    final totalExpenses = expRow.read(expenseSum) ?? 0.0;
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

  /// Stream Laporan Laba Rugi untuk Widget Dashboard/Laporan Real-time
  Stream<LaporanLabaRugiData> watchLaporanLabaRugi(
    DateTime startDate,
    DateTime endDate,
  ) {
    return Stream.fromFuture(getLaporanLabaRugi(startDate, endDate));
  }

  // ===========================================================================
  // 2. LAPORAN PRODUK TERLARIS (TOP SELLING PRODUCTS)
  // ===========================================================================

  /// Mengambil daftar produk terlaris berdasarkan kuantitas / omset
  Future<List<TopProductReportData>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final rows = await (select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
      innerJoin(
        products,
        products.id.equalsExp(transactionItems.productId),
      ),
    ])
      ..where(
        transactions.createdAt.isBetweenValues(start, end) &
            transactions.status.isNotIn(['CANCELLED', 'VOID', 'Batal']),
      ))
        .get();

    // Grouping Manual berdasarkan Product ID
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
    // Urutkan berdasarkan kuantitas terbanyak
    list.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return list.take(limit).toList();
  }

  // ===========================================================================
  // 3. RINGKASAN OMSET HARIAN (DAILY SALES GRAPH)
  // ===========================================================================

  /// Mengambil tren omset harian dalam rentang tanggal tertentu (untuk Grafik Penjualan)
  Future<List<DailyOmsetReportData>> getDailyOmsetSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final validTransactions = await (select(transactions)
          ..where(
            (tbl) =>
                tbl.createdAt.isBetweenValues(start, end) &
                tbl.status.isNotIn(['CANCELLED', 'VOID', 'Batal']),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();

    final Map<String, DailyOmsetReportData> dailyMap = {};

    for (final tx in validTransactions) {
      final dateKey =
          "${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}-${tx.createdAt.day.toString().padLeft(2, '0')}";
      final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);

      final omset = tx.grandTotal;
      // Perkiraan estimasi laba kotor transaksi dari header jika kolom profit disimpan di header
      final profit = tx.totalProfit; 

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

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final reportDaoProvider = Provider<ReportDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ReportDao(db);
});

/// StreamProvider Laporan Laba Rugi Bulan Ini
final monthlyLabaRugiProvider = StreamProvider<LaporanLabaRugiData>((ref) {
  final dao = ref.watch(reportDaoProvider);
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  return dao.watchLaporanLabaRugi(firstDayOfMonth, lastDayOfMonth);
});
