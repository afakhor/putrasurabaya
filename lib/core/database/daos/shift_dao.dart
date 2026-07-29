import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_tables.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_tables.dart';

part 'shift_dao.g.dart';

// ===========================================================================
// DATA TRANSFER OBJECT (DTO) UNTUK RINGKASAN SHIFT / STRUK TUTUP KASIR
// ===========================================================================

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

// ===========================================================================
// SHIFT DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [ShiftKasir, Transactions])
class ShiftDao extends DatabaseAccessor<LocalDatabase> with _$ShiftDaoMixin {
  ShiftDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM STATUS SHIFT
  // ===========================================================================

  /// Stream Shift Aktif Kasir saat ini (Status 'open')
  Stream<ShiftKasirData?> watchActiveShift(String userId) {
    return (select(shiftKasir)
          ..where((s) => s.userId.equals(userId) & s.status.equals('open'))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Memeriksa Shift Aktif Kasir saat ini (Future)
  Future<ShiftKasirData?> getActiveShift(String userId) {
    return (select(shiftKasir)
          ..where((s) => s.userId.equals(userId) & s.status.equals('open'))
          ..limit(1))
        .getSingleOrNull();
  }

  // ===========================================================================
  // 2. BUKA KASIR (OPEN SHIFT)
  // ===========================================================================

  /// Membuka Shift Kasir Baru dengan Modal Awal
  Future<String> bukaKasir(String userId, double modalAwal) async {
    // Proteksi: Cek apakah masih ada shift aktif yang belum ditutup
    final activeShift = await getActiveShift(userId);
    if (activeShift != null) {
      throw Exception(
        'Gagal membuka shift baru. Anda masih memiliki shift aktif yang belum ditutup.',
      );
    }

    final now = DateTime.now();
    final shiftId = 'SFT-${now.microsecondsSinceEpoch}';

    await into(shiftKasir).insert(
      ShiftKasirCompanion.insert(
        id: shiftId,
        userId: userId,
        startTime: Value(now),
        initialCash: Value(modalAwal),
        status: const Value('open'),
        isSynced: const Value(false),
      ),
    );

    return shiftId;
  }

  // ===========================================================================
  // 3. REKAPITULASI & HITUNG SHIFT SUMMARY
  // ===========================================================================

  /// Menghitung Ringkasan Transaksi & Perkiraan Uang Kas di Laci
  Future<ShiftSummaryData> getShiftSummary(String shiftId) async {
    final shift = await (select(shiftKasir)
          ..where((s) => s.id.equals(shiftId)))
        .getSingleOrNull();

    if (shift == null) {
      throw Exception('Data shift tidak ditemukan.');
    }

    // Ambil transaksi sah pada shift ini (Abaikan CANCELLED/VOID/Batal)
    final validTx = await (select(transactions)
          ..where((t) =>
              t.shiftId.equals(shiftId) &
              t.status.isNotIn(['CANCELLED', 'VOID', 'Batal'])))
        .get();

    double cashSales = 0.0;
    double nonCashSales = 0.0;
    double creditSales = 0.0;

    for (final tx in validTx) {
      final method = tx.paymentMethod.toUpperCase();

      if (method == 'CASH' || method == 'TUNAI') {
        // Jika ada kembalian, uang cash masuk murni adalah grandTotal
        cashSales += (tx.paidAmount > tx.grandTotal ? tx.grandTotal : tx.paidAmount);
      } else if (method == 'CREDIT' || method == 'PIUTANG') {
        creditSales += tx.grandTotal;
        // Catat jika ada DP Tunai pada penjualan kredit
        if (tx.paidAmount > 0) {
          cashSales += tx.paidAmount;
        }
      } else {
        // QRIS, Transfer Bank, EDC, dll.
        nonCashSales += tx.grandTotal;
      }
    }

    final initialCash = shift.initialCash ?? 0.0;
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

  // ===========================================================================
  // 4. TUTUP KASIR (CLOSE SHIFT) & HITUNG SELISIH LACI
  // ===========================================================================

  /// Menutup Shift Kasir, Menyimpan Uang Fisik Hasil Perhitungan, & Menghitung Selisih
  Future<ShiftSummaryData> tutupKasir({
    required String shiftId,
    required double uangFisikLaci,
    String? notes,
  }) async {
    return transaction(() async {
      final summary = await getShiftSummary(shiftId);

      if (summary.shift.status == 'closed') {
        throw Exception('Shift ini sudah ditutup sebelumnya.');
      }

      final now = DateTime.now();
      final difference = uangFisikLaci - summary.expectedCash;

      await (update(shiftKasir)..where((s) => s.id.equals(shiftId))).write(
        ShiftKasirCompanion(
          endTime: Value(now),
          expectedCash: Value(summary.expectedCash),
          actualCash: Value(uangFisikLaci),
          cashDifference: Value(difference),
          notes: Value(notes),
          status: const Value('closed'),
          isSynced: const Value(false),
        ),
      );

      // Kembalikan summary terbaru setelah diupdate
      return getShiftSummary(shiftId);
    });
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final shiftDaoProvider = Provider<ShiftDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ShiftDao(db);
});

/// StreamProvider untuk mendeteksi apakah kasir tertentu sedang aktif/buka shift
final activeShiftStreamProvider =
    StreamProvider.family<ShiftKasirData?, String>((ref, userId) {
  final dao = ref.watch(shiftDaoProvider);
  return dao.watchActiveShift(userId);
});
