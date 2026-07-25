// lib/features/auth/auth_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/local_database.dart';

class AuthState {
  final UserData? currentUser;
  final bool isAuthenticated;
  final bool isLocked;
  final int failedAttempts;
  final String? errorMessage;
  final double initialCash; // Modal Awal Laci Shift
  final bool isShiftOpen;

  AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLocked = false,
    this.failedAttempts = 0,
    this.errorMessage,
    this.initialCash = 0,
    this.isShiftOpen = false,
  });

  AuthState copyWith({
    UserData? currentUser,
    bool? isAuthenticated,
    bool? isLocked,
    int? failedAttempts,
    String? errorMessage,
    double? initialCash,
    bool? isShiftOpen,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      errorMessage: errorMessage,
      initialCash: initialCash ?? this.initialCash,
      isShiftOpen: isShiftOpen ?? this.isShiftOpen,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LocalDatabase _db;
  Timer? _lockoutTimer;

  AuthNotifier(this._db) : super(AuthState());

  /// Login SuperUser (Owner) via Password / Salesman via API Key
  Future<bool> loginWithApiKeyOrPassword(String inputKey) async {
    if (state.isLocked) {
      state = state.copyWith(errorMessage: 'Aplikasi terkunci. Coba lagi dalam beberapa menit.');
      return false;
    }

    // Bypass khusus SuperUser Owner UD. Putra Surabaya
    if (inputKey == 'OWNER-PUTRA-SURABAYA-2026' || inputKey == 'admin123') {
      final ownerUser = UserData(
        id: 'SUPERUSER-01',
        name: 'Owner UD. Putra Surabaya',
        role: 'superuser',
        status: 'active',
        canEditPrice: true,
        canDeleteTransaction: true,
      );
      state = AuthState(currentUser: ownerUser, isAuthenticated: true);
      return true;
    }

    // Cek ApiKey Salesman di Database Lokal
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(inputKey))).getSingleOrNull();

    if (user != null) {
      if (user.status == 'suspended') {
        state = state.copyWith(errorMessage: 'Akses Salesman ditangguhkan (SUSPENDED) oleh Owner.');
        return false;
      }

      state = AuthState(currentUser: user, isAuthenticated: true);
      return true;
    }

    // Penanganan Gagal Login (>3x Lockout 5 Menit)
    int attempts = state.failedAttempts + 1;
    if (attempts >= 3) {
      state = state.copyWith(
        isLocked: true,
        failedAttempts: attempts,
        errorMessage: 'Terlalu banyak percobaan gagal. Sistem dikunci selama 5 menit.',
      );
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer(const Duration(minutes: 5), () {
        state = state.copyWith(isLocked: false, failedAttempts: 0);
      });
      return false;
    }

    state = state.copyWith(
      failedAttempts: attempts,
      errorMessage: 'API Key / Password Salah. Kesempatan tersisa: ${3 - attempts}',
    );
    return false;
  }

  /// Buka Kasir (Set Modal Awal Laci)
  void bukaKasir(double modalAwal) {
    state = state.copyWith(initialCash: modalAwal, isShiftOpen: true);
  }

  /// Tutup Shift Kasir
  void tutupKasir() {
    state = state.copyWith(isShiftOpen: false, initialCash: 0);
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return AuthNotifier(db);
});
