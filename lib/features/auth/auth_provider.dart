import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

/// Enum Peran Pengguna (3 Role Utama)
enum UserRole {
  owner,
  admin,
  salesman;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'superuser':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'salesman':
      case 'kasir':
      default:
        return UserRole.salesman;
    }
  }

  String toFormattedString() {
    switch (this) {
      case UserRole.owner:
        return 'Owner (SuperUser)';
      case UserRole.admin:
        return 'Admin';
      case UserRole.salesman:
        return 'Salesman / Kasir';
    }
  }
}

/// State Otentikasi & Hak Akses
class AuthState {
  final UserData? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final String? generatedApiKey; // Disimpan sementara saat Owner membuatkan API Key baru

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.generatedApiKey,
  });

  bool get isAuthenticated => currentUser != null;

  UserRole get role => currentUser != null
      ? UserRole.fromString(currentUser!.role)
      : UserRole.salesman;

  // Checker Role Sederhana
  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;
  bool get isSalesman => role == UserRole.salesman;

  // ===========================================================================
  // MATRIKS HAK AKSES PERAN (ROLE PERMISSIONS)
  // ===========================================================================

  /// 1. Hak Akses Khas OWNER
  bool get canGenerateApiKeys => isOwner; // Hanya Owner yang bisa buat API Key Admin & Salesman
  bool get canViewGrossProfit => isOwner; // Laba kotor/HPP murni rahasia Owner
  bool get canDeleteTransaction => isOwner; // Void / Hapus nota kasir

  /// 2. Hak Akses ADMIN (& Owner)
  bool get canManageSalesmanKpi => isOwner || isAdmin; // Buat & pantau KPI Salesman
  bool get canReviewOmsetAndSales => isOwner || isAdmin; // Review omset & laporan penjualan
  bool get canReviewCustomerReceivables => isOwner || isAdmin; // Cek piutang customer
  bool get canManageMasterData => isOwner || isAdmin; // Edit stok/produk/supplier

  /// 3. Hak Akses SALESMAN / KASIR (& Admin & Owner)
  bool get canAccessPos => isOwner || isAdmin || isSalesman; // Transaksi Kasir
  bool get canCollectReceivables => isOwner || isAdmin || isSalesman; // Terima cicilan piutang di kasir

  AuthState copyWith({
    UserData? currentUser,
    bool? isLoading,
    String? errorMessage,
    String? generatedApiKey,
    bool clearUser = false,
    bool clearApiKey = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      generatedApiKey: clearApiKey ? null : (generatedApiKey ?? this.generatedApiKey),
    );
  }
}

/// Notifier Pengelola Sesi & API Key
class AuthNotifier extends StateNotifier<AuthState> {
  final LocalDatabase _db;

  AuthNotifier(this._db) : super(const AuthState()) {
    _initSession();
  }

  Future<void> _initSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _db.select(_db.users).get();
      if (users.isNotEmpty) {
        final ownerUser = users.firstWhere(
          (u) => u.role.toLowerCase() == 'owner',
          orElse: () => users.first,
        );
        state = state.copyWith(currentUser: ownerUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat sesi pengguna: $e',
      );
    }
  }

  /// Login Pengguna
  Future<bool> loginWithUser(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await (_db.select(_db.users)
            ..where((t) => t.id.equals(userId)))
          .getSingleOrNull();

      if (user != null) {
        if (user.status.toLowerCase() != 'aktif') {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Akun ini sedang tidak aktif.',
          );
          return false;
        }
        state = state.copyWith(currentUser: user, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'User tidak ditemukan.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error login: $e');
      return false;
    }
  }

  // ===========================================================================
  // FUNGSI GENERATE API KEY (KHUSUS OWNER)
  // ===========================================================================

  /// Owner membuat API Key baru untuk Admin atau Salesman
  Future<String?> generateApiKeyForRole({
    required String targetUserId,
    required UserRole targetRole,
  }) async {
    if (!state.canGenerateApiKeys) {
      state = state.copyWith(
          errorMessage: 'Akses ditolak! Hanya Owner yang dapat mengenerate API Key.');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Buat String API Key acak unik (Contoh: PK-ADM-8F92A1B4)
      final prefix = targetRole == UserRole.admin ? 'PK-ADM' : 'PK-SLS';
      final randomBytes = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      final randomHex = base64Url.encode(randomBytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final newApiKey = '$prefix-$randomHex';

      // 2. Simpan API Key & Update Role Target User ke Database
      await (_db.update(_db.users)..where((tbl) => tbl.id.equals(targetUserId)))
          .write(
        UsersCompanion(
          role: Value(targetRole.name),
          apiKey: Value(newApiKey),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        generatedApiKey: newApiKey,
      );

      return newApiKey;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengenerate API Key: $e',
      );
      return null;
    }
  }

  void clearGeneratedApiKey() {
    state = state.copyWith(clearApiKey: true);
  }

  void logout() {
    state = state.copyWith(clearUser: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return AuthNotifier(db);
});
