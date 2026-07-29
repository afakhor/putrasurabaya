import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_tables.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users, ShiftKasir])
class UserDao extends DatabaseAccessor<LocalDatabase> with _$UserDaoMixin {
  UserDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. OTENTIKASI & LOGGING USER
  // ===========================================================================

  /// Validasi Login Salesman via API Key
  Future<UserData?> validateApiKey(String apiKey) async {
    final user = await (select(users)
          ..where((u) => u.apiKey.equals(apiKey) & u.status.equals('aktif')))
        .getSingleOrNull();
    return user;
  }

  /// Validasi Login Kasir via PIN 6-Digit (Fast Switch User)
  Future<UserData?> validatePin(String pinCode) async {
    return (select(users)
          ..where((u) => u.pinCode.equals(pinCode) & u.status.equals('aktif')))
        .getSingleOrNull();
  }

  /// Validasi Login Pengguna via Username & Password Hash
  Future<UserData?> validateUserPassword(
      String username, String passwordHash) async {
    return (select(users)
          ..where((u) =>
              u.username.equals(username) &
              u.passwordHash.equals(passwordHash) &
              u.status.equals('aktif')))
        .getSingleOrNull();
  }

  /// Ambil Data User Berdasarkan ID
  Future<UserData?> getUserById(String userId) {
    return (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  /// Generator API Key untuk Salesman baru
  Future<String> generateApiKeyForSalesman({
    required String name,
    required String phone,
    required String salesArea,
    required String address,
  }) async {
    final newId = 'USR-${DateTime.now().millisecondsSinceEpoch}';
    final generatedApiKey =
        'KEY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await into(users).insert(
      UsersCompanion.insert(
        id: newId,
        name: name,
        role: UserRole.salesman,
        apiKey: Value(generatedApiKey),
        phone: Value(phone),
        salesArea: Value(salesArea),
        address: Value(address),
        status: const Value('aktif'),
        isSynced: const Value(false),
      ),
    );

    return generatedApiKey;
  }

  // ===========================================================================
  // 2. MANAJEMEN HAK AKSES GRANULAR & STATUS
  // ===========================================================================

  /// Owner mengubah izin hak akses Salesman / Kasir secara spesifik
  Future<void> updateSalesmanPermissions({
    required String salesmanUserId,
    required bool canOverridePrice,
    required bool canGiveDiscount,
    required bool canCreateCustomer,
    required bool canCollectPayment,
    required bool canProcessReturn,
    required bool canVoidTransaction,
    bool canManageStock = false,
    required double maxDiscountPercent,
  }) async {
    await (update(users)..where((u) => u.id.equals(salesmanUserId))).write(
      UsersCompanion(
        canOverridePrice: Value(canOverridePrice),
        canGiveDiscount: Value(canGiveDiscount),
        canCreateCustomer: Value(canCreateCustomer),
        canCollectPayment: Value(canCollectPayment),
        canProcessReturn: Value(canProcessReturn),
        canVoidTransaction: Value(canVoidTransaction),
        canManageStock: Value(canManageStock),
        maxDiscountPercent: Value(maxDiscountPercent),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Ubah PIN Login 6-Digit User
  Future<void> updateUserPin(String userId, String newPin) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        pinCode: Value(newPin),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Ubah Status Suspend / Aktif User
  Future<void> setUserStatus(String userId, String status) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        status: Value(status),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream Ambil Semua User
  Stream<List<UserData>> watchAllUsers() => select(users).watch();

  /// Stream khusus daftar Salesman untuk Pengaturan Hak Akses Owner
  Stream<List<UserData>> watchAllSalesmen() {
    return (select(users)..where((u) => u.role.equals(UserRole.salesman)))
        .watch();
  }

  // ===========================================================================
  // 3. SHIFT KASIR (MANAJEMEN ARUS KAS & TUTUP LACI)
  // ===========================================================================

  /// Stream Shift Kasir Aktif (Status 'open') Berdasarkan User ID
  Stream<ShiftKasirData?> watchActiveShift(String userId) {
    return (select(shiftKasir)
          ..where((s) =>
              s.userId.equals(userId) & s.status.equals(ShiftStatus.open)))
        .watchSingleOrNull();
  }

  /// Ambil Shift Aktif User (Non-Stream)
  Future<ShiftKasirData?> getActiveShift(String userId) {
    return (select(shiftKasir)
          ..where((s) =>
              s.userId.equals(userId) & s.status.equals(ShiftStatus.open)))
        .getSingleOrNull();
  }

  /// Buka Shift Kasir Baru (Pencatatan Modal Kas Awal)
  Future<String> openShift({
    required String userId,
    required double initialCash,
  }) async {
    // Pastikan tidak ada shift aktif berstatus 'open' yang tertinggal
    final activeShift = await getActiveShift(userId);
    if (activeShift != null) {
      return activeShift.id; // Kembalikan shift yang sedang berjalan
    }

    final shiftId = 'SFT-${DateTime.now().millisecondsSinceEpoch}';

    await into(shiftKasir).insert(
      ShiftKasirCompanion.insert(
        id: shiftId,
        userId: userId,
        initialCash: Value(initialCash),
        expectedCash: Value(initialCash),
        status: const Value(ShiftStatus.open),
        isSynced: const Value(false),
      ),
    );

    return shiftId;
  }

  /// Auto-Update Akumulasi Kas Shift (Dipanggil saat Transaksi Penjualan / Penagihan)
  Future<void> addShiftRevenue({
    required String shiftId,
    double cashSales = 0.0,
    double nonCashSales = 0.0,
    double receivableCollected = 0.0,
  }) async {
    final shift = await (select(shiftKasir)..where((s) => s.id.equals(shiftId)))
        .getSingleOrNull();

    if (shift == null || shift.status != ShiftStatus.open) return;

    final newCashSales = shift.totalCashSales + cashSales;
    final newNonCashSales = shift.totalNonCashSales + nonCashSales;
    final newReceivable = shift.totalReceivableCollected + receivableCollected;
    
    // Formula Uang Kas yang Harus Ada di Laci
    final newExpectedCash = shift.initialCash + newCashSales + newReceivable;

    await (update(shiftKasir)..where((s) => s.id.equals(shiftId))).write(
      ShiftKasirCompanion(
        totalCashSales: Value(newCashSales),
        totalNonCashSales: Value(newNonCashSales),
        totalReceivableCollected: Value(newReceivable),
        expectedCash: Value(newExpectedCash),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Tutup Shift Kasir (Hitung Fisik Uang Laci & Kalkulasi Selisih Kas)
  Future<bool> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
  }) async {
    final shift = await (select(shiftKasir)..where((s) => s.id.equals(shiftId)))
        .getSingleOrNull();

    if (shift == null) throw Exception('Data shift tidak ditemukan');

    // Kalkulasi Akhir
    final expectedCash =
        shift.initialCash + shift.totalCashSales + shift.totalReceivableCollected;
    final cashDifference = actualCash - expectedCash;

    final updatedRows =
        await (update(shiftKasir)..where((s) => s.id.equals(shiftId))).write(
      ShiftKasirCompanion(
        endTime: Value(DateTime.now()),
        expectedCash: Value(expectedCash),
        actualCash: Value(actualCash),
        cashDifference: Value(cashDifference),
        notes: Value(notes),
        status: const Value(ShiftStatus.closed),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return updatedRows > 0;
  }

  /// Ambil Riwayat Shift Kasir
  Future<List<ShiftKasirData>> getShiftHistory({int limit = 30}) {
    return (select(shiftKasir)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.startTime, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return UserDao(db);
});
