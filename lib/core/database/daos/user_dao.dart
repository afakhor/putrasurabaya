import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_tables.dart';

part 'user_dao.g.dart';

// ===========================================================================
// CONSTANTS ROLE & STATUS USER
// ===========================================================================

class UserRole {
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String kasir = 'kasir';
  static const String salesman = 'salesman';
}

class UserStatus {
  static const String aktif = 'aktif';
  static const String nonAktif = 'non_aktif';
  static const String suspended = 'suspended';
}

// ===========================================================================
// USER DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<LocalDatabase> with _$UserDaoMixin {
  UserDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. OTENTIKASI & VALIDASI LOGIN
  // ===========================================================================

  /// Validasi Login Kasir via PIN 6-Digit (Fast Switch User di POS)
  Future<UserData?> validatePin(String pinCode) async {
    return (select(users)
          ..where((u) => u.pinCode.equals(pinCode) & u.status.equals(UserStatus.aktif)))
        .getSingleOrNull();
  }

  /// Validasi Login via Username & Password Hash (Owner / Admin)
  Future<UserData?> validateUserPassword(
      String username, String passwordHash) async {
    return (select(users)
          ..where((u) =>
              u.username.equals(username) &
              u.passwordHash.equals(passwordHash) &
              u.status.equals(UserStatus.aktif)))
        .getSingleOrNull();
  }

  /// Validasi Login Salesman via API Key (Mobile Canvassing)
  Future<UserData?> validateApiKey(String apiKey) async {
    return (select(users)
          ..where((u) => u.apiKey.equals(apiKey) & u.status.equals(UserStatus.aktif)))
        .getSingleOrNull();
  }

  /// Ambil Data User Berdasarkan ID
  Future<UserData?> getUserById(String userId) {
    return (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  /// Ambil Data User Berdasarkan ID (Sudah ada di kode Anda)
  Future<UserData?> getUserById(String userId) {
    return (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  // ===========================================================================
  // TAMBAHAN UNTUK FITUR 3-PLAY WHATSAPP
  // ===========================================================================

  /// Ambil Satu User Berdasarkan Role (Contoh: 'owner' atau 'salesman')
  /// Berguna untuk mendapatkan nomor telepon Owner atau Salesman secara otomatis
  Future<UserData?> getUserByRole(String role) {
    return (select(users)
          ..where((u) => u.role.equals(role) & u.status.equals(UserStatus.aktif))
          ..limit(1)) // Ambil satu saja yang aktif
        .getSingleOrNull();
  }

  // ===========================================================================
  // 2. MANAJEMEN CRUD USER (CREATE, READ, UPDATE, DELETE)
  // ===========================================================================

  /// Tambah Pengguna Baru (Owner, Admin, Kasir, atau Salesman)
  Future<String> createUser({
    required String name,
    required String role, // 'owner', 'admin', 'kasir', 'salesman'
    String? username,
    String? passwordHash,
    String? pinCode,
    String? phone,
    String? salesArea,
    String? address,
    bool canOverridePrice = false,
    bool canGiveDiscount = false,
    bool canCreateCustomer = true,
    bool canCollectPayment = true,
    bool canProcessReturn = false,
    bool canVoidTransaction = false,
    bool canManageStock = false,
    double maxDiscountPercent = 0.0,
  }) async {
    final now = DateTime.now();
    final newId = 'USR-${now.microsecondsSinceEpoch}';
    
    // Auto-generate API Key jika rolenya Salesman
    String? apiKey;
    if (role == UserRole.salesman) {
      apiKey = 'KEY-${now.microsecondsSinceEpoch.toString().substring(6)}';
    }

    await into(users).insert(
      UsersCompanion.insert(
        id: newId,
        name: name,
        role: role,
        username: Value(username),
        passwordHash: Value(passwordHash),
        pinCode: Value(pinCode),
        apiKey: Value(apiKey),
        phone: Value(phone),
        salesArea: Value(salesArea),
        address: Value(address),
        canOverridePrice: Value(canOverridePrice),
        canGiveDiscount: Value(canGiveDiscount),
        canCreateCustomer: Value(canCreateCustomer),
        canCollectPayment: Value(canCollectPayment),
        canProcessReturn: Value(canProcessReturn),
        canVoidTransaction: Value(canVoidTransaction),
        canManageStock: Value(canManageStock),
        maxDiscountPercent: Value(maxDiscountPercent),
        status: const Value(UserStatus.aktif),
        createdAt: Value(now),
        isSynced: const Value(false),
      ),
    );

    return newId;
  }

  /// Update Profil / Data Dasar User
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? username,
    String? phone,
    String? address,
    String? salesArea,
  }) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        name: Value(name),
        username: Value(username),
        phone: Value(phone),
        address: Value(address),
        salesArea: Value(salesArea),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Update Hak Akses Granular (Bisa untuk Salesman maupun Kasir)
  Future<void> updateUserPermissions({
    required String userId,
    required bool canOverridePrice,
    required bool canGiveDiscount,
    required bool canCreateCustomer,
    required bool canCollectPayment,
    required bool canProcessReturn,
    required bool canVoidTransaction,
    required bool canManageStock,
    required double maxDiscountPercent,
  }) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        canOverridePrice: Value(canOverridePrice),
        canGiveDiscount: Value(canGiveDiscount),
        canCreateCustomer: Value(canCreateCustomer),
        canCollectPayment: Value(canCollectPayment),
        canProcessReturn: Value(canProcessReturn),
        canVoidTransaction: Value(canVoidTransaction),
        canManageStock: Value(canManageStock),
        maxDiscountPercent: Value(maxDiscountPercent),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Ubah PIN Login 6-Digit User
  Future<void> updateUserPin(String userId, String newPin) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        pinCode: Value(newPin),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Ubah Password User
  Future<void> updateUserPassword(String userId, String newPasswordHash) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(newPasswordHash),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Ubah Status User (Aktif / Non-Aktif / Suspended)
  Future<void> setUserStatus(String userId, String status) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Soft Delete / Hapus User
  Future<void> deleteUser(String userId) async {
    await (delete(users)..where((u) => u.id.equals(userId))).go();
  }

  // ===========================================================================
  // 3. STREAMS & QUERIES UNTUK UI MANAGEMENT
  // ===========================================================================

  /// Stream Semua Pengguna Aktif
  Stream<List<UserData>> watchAllActiveUsers() {
    return (select(users)
          ..where((u) => u.status.equals(UserStatus.aktif))
          ..orderBy([(u) => OrderingTerm(expression: u.name)]))
        .watch();
  }

  /// Stream Khusus Daftar Salesman
  Stream<List<UserData>> watchAllSalesmen() {
    return (select(users)
          ..where((u) => u.role.equals(UserRole.salesman))
          ..orderBy([(u) => OrderingTerm(expression: u.name)]))
        .watch();
  }

  /// Stream Khusus Daftar Kasir
  Stream<List<UserData>> watchAllCashiers() {
    return (select(users)
          ..where((u) => u.role.equals(UserRole.kasir))
          ..orderBy([(u) => OrderingTerm(expression: u.name)]))
        .watch();
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return UserDao(db);
});

/// StreamProvider untuk Daftar User Aktif di UI
final activeUsersStreamProvider = StreamProvider<List<UserData>>((ref) {
  final dao = ref.watch(userDaoProvider);
  return dao.watchAllActiveUsers();
});

/// StreamProvider untuk Daftar Salesman
final salesmenStreamProvider = StreamProvider<List<UserData>>((ref) {
  final dao = ref.watch(userDaoProvider);
  return dao.watchAllSalesmen();
});
