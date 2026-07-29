import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';

part 'shift_dao.g.dart';

@DriftAccessor(tables: [ShiftKasir, Transactions])
class ShiftDao extends DatabaseAccessor<LocalDatabase> with _$ShiftDaoMixin {
  ShiftDao(LocalDatabase db) : super(db);

  /// 1. BUKA KASIR
  Future<String> bukaKasir(String userId, double modalAwal) async {
    final shiftId = 'SFT-${DateTime.now().millisecondsSinceEpoch}';
    await into(shiftKasir).insert(
      ShiftKasirCompanion.insert(
        id: shiftId,
        userId: userId,
        initialCash: Value(modalAwal),
        status: const Value('open'),
      ),
    );
    return shiftId;
  }

  /// 2. TUTUP KASIR & HITUNG SELISIH LACI
  Future<void> tutupKasir({
    required String shiftId,
    required double uangFisikLaci,
    String? notes,
  }) async {
    final shift = await (select(shiftKasir)..where((s) => s.id.equals(shiftId))).getSingle();

    // Hitung Penjualan Cash Selama Shift Ini
    final cashSalesQuery = selectOnly(transactions)
      ..addColumns([transactions.total.sum()])
      ..where(transactions.shiftId.equals(shiftId) & transactions.paymentMethod.equals('cash'));

    final row = await cashSalesQuery.getSingle();
    final totalCashSales = row.read(transactions.total.sum()) ?? 0.0;

    final expectedCash = shift.initialCash + totalCashSales;
    final difference = uangFisikLaci - expectedCash;

    await (update(shiftKasir)..where((s) => s.id.equals(shiftId))).write(
      ShiftKasirCompanion(
        endTime: Value(DateTime.now()),
        expectedCash: Value(expectedCash),
        actualCash: Value(uangFisikLaci),
        cashDifference: Value(difference),
        notes: Value(notes),
        status: const Value('closed'),
      ),
    );
  }
}

final shiftDaoProvider = Provider<ShiftDao>((ref) {
  return ShiftDao(ref.watch(localDatabaseProvider));
});
