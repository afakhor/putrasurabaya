import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';

part 'shift_dao.g.dart';

class ShiftSummaryData {
  final ShiftKasirData shift;
  final double initialCash;
  final double totalCashSales;
  final double totalNonCashSales;
  final double totalCreditSales;
  final double totalSales;
  final double expectedCash;
  final double? actualCash;
  final double? cashDifference;
  final int transactionCount;
  ShiftSummaryData({
    required this.shift,
    required this.initialCash,
    required this.totalCashSales,
    required this.totalNonCashSales,
    required this.totalCreditSales,
    required this.totalSales,
    required this.expectedCash,
    this.actualCash,
    this.cashDifference,
    required this.transactionCount,
  });
}

@DriftAccessor(tables: [ShiftKasir, Transactions])
class ShiftDao extends DatabaseAccessor<LocalDatabase> with _$ShiftDaoMixin {
  ShiftDao(LocalDatabase db) : super(db);

  Stream<ShiftKasirData?> watchActiveShift(String userId) {
    return (select(shiftKasir)..where((s) => s.userId.equals(userId) & s.status.equals('open'))..limit(1)).watchSingleOrNull();
  }

  Future<ShiftKasirData?> getActiveShift(String userId) {
    return (select(shiftKasir)..where((s) => s.userId.equals(userId) & s.status.equals('open'))..limit(1)).getSingleOrNull();
  }

  Future<String> bukaKasir(String userId, double modalAwal) async {
    final activeShift = await getActiveShift(userId);
    if (activeShift!= null) {
      throw Exception('Masih ada shift aktif yang belum ditutup.');
    }
    final now = DateTime.now();
    final shiftId = 'SFT-${now.microsecondsSinceEpoch}';
    await into(shiftKasir).insert(ShiftKasirCompanion.insert(
      id: shiftId,
      userId: userId,
      startTime: Value(now),
      initialCash: Value(modalAwal),
      status: const Value('open'),
      isSynced: const Value(false),
    ));
    return shiftId;
  }

  Future<ShiftSummaryData> getShiftSummary(String shiftId) async {
    final shift = await (select(shiftKasir)..where((s) => s.id.equals(shiftId))).getSingleOrNull();
    if (shift == null) throw Exception('Data shift tidak ditemukan.');

    final validTx = await (select(transactions)..where((t) => t.shiftId.equals(shiftId) & t.status.isNotIn(['CANCELLED', 'VOID', 'Batal', 'void']))).get();

    double cashSales = 0.0;
    double nonCashSales = 0.0;
    double creditSales = 0.0;

    for (final tx in validTx) {
      final method = tx.paymentMethod.toUpperCase();
      if (method == 'CASH' || method == 'TUNAI') {
        // FIX: paidAmount -> payAmount
        cashSales += (tx.payAmount > tx.grandTotal? tx.grandTotal : tx.payAmount);
      } else if (method == 'CREDIT' || method == 'PIUTANG') {
        creditSales += tx.grandTotal;
        if (tx.payAmount > 0) {
          cashSales += tx.payAmount;
        }
      } else {
        nonCashSales += tx.grandTotal;
      }
    }

    final initialCash = shift.initialCash?? 0.0;
    final expectedCash = initialCash + cashSales;
    final totalSales = cashSales + nonCashSales + creditSales;

    return ShiftSummaryData(
      shift: shift,
      initialCash: initialCash,
      totalCashSales: cashSales,
      totalNonCashSales: nonCashSales,
      totalCreditSales: creditSales,
      totalSales: totalSales,
      expectedCash: expectedCash,
      actualCash: shift.actualCash,
      cashDifference: shift.cashDifference,
      transactionCount: validTx.length,
    );
  }

  Future<ShiftSummaryData> tutupKasir({required String shiftId, required double uangFisikLaci, String? notes}) async {
    return transaction(() async {
      final summary = await getShiftSummary(shiftId);
      if (summary.shift.status == 'closed') throw Exception('Shift sudah ditutup.');
      final now = DateTime.now();
      final difference = uangFisikLaci - summary.expectedCash;
      await (update(shiftKasir)..where((s) => s.id.equals(shiftId))).write(ShiftKasirCompanion(
        endTime: Value(now),
        expectedCash: Value(summary.expectedCash),
        actualCash: Value(uangFisikLaci),
        cashDifference: Value(difference),
        notes: Value(notes),
        status: const Value('closed'),
        isSynced: const Value(false),
      ));
      return getShiftSummary(shiftId);
    });
  }
}

final shiftDaoProvider = Provider<ShiftDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ShiftDao(db);
});

final activeShiftStreamProvider = StreamProvider.family<ShiftKasirData?, String>((ref, userId) {
  final dao = ref.watch(shiftDaoProvider);
  return dao.watchActiveShift(userId);
});