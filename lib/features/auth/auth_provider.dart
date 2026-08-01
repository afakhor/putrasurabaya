// lib/features/auth/auth_provider.dart - FINAL FIX
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart'; // <-- INI YANG KURANG
import 'auth_repository.dart';

// ============================================================
// 1. ROLE DEFINISI (iPOS 5 Style)
// ============================================================
enum AppRole { superuser, admin, salesman, kasir }

extension UserRoleExt on UserData {
  AppRole get appRole {
    final r = role.toLowerCase();
    if (r == 'superuser' || r == 'owner') return AppRole.superuser;
    if (r == 'admin') return AppRole.admin;
    if (r == 'salesman') return AppRole.salesman;
    return AppRole.kasir;
  }
  bool get isSuperuser => appRole == AppRole.superuser;
}

// ============================================================
// 2. PROVIDER DASAR - FIX DI SINI
// ============================================================
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // FIX: ambil dao dari localDatabaseProvider.userDao
  final dao = ref.watch(localDatabaseProvider).userDao;
  return AuthRepository(dao);
});

final currentUserProvider = StateProvider<UserData?>((ref) => null);

// StateNotifier dengan AuthState custom biar gampang di main.dart
class AuthState {
  final bool isLoading;
  final String? error;
  const AuthState({this.isLoading = false, this.error});
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserData?>>((ref) {
  return AuthNotifier(ref);
});

// ============================================================
// 3. CEK HAK AKSES CEPAT
// ============================================================
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  if (user.isSuperuser) return true;

  switch (permission) {
    case 'canOverridePrice':
      return user.canOverridePrice;
    case 'canGiveDiscount':
      return user.canGiveDiscount;
    case 'canVoidTransaction':
      return user.canVoidTransaction;
    case 'canManageStock':
      return user.canManageStock;
    case 'canCreateCustomer':
      return user.canCreateCustomer;
    case 'canCollectPayment':
      return user.canCollectPayment;
    case 'canProcessReturn':
      return user.canProcessReturn;
    default:
      return false;
  }
});

// ============================================================
// 4. NOTIFIER / OTAK LOGIN
// ============================================================
class AuthNotifier extends StateNotifier<AsyncValue<UserData?>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> loginByPassword(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginByPassword(username, password);
      if (user == null) throw Exception('Username / Password salah');
      ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginByPin(String pin) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginByPin(pin);
      if (user == null) throw Exception('PIN salah / User tidak aktif');
      ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginByApiKey(String apiKey) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginByApiKey(apiKey);
      if (user == null) throw Exception('API Key tidak valid');
      ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void logout() {
    ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}