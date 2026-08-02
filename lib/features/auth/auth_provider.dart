// lib/features/auth/auth_provider.dart - FINAL FIX PERSISTEN LOGIN
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';
import 'auth_repository.dart';

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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dao = ref.watch(localDatabaseProvider).userDao;
  return AuthRepository(dao);
});

final currentUserProvider = StateProvider<UserData?>((ref) => null);

final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  if (user.isSuperuser) return true;
  switch (permission) {
    case 'canOverridePrice': return user.canOverridePrice;
    case 'canGiveDiscount': return user.canGiveDiscount;
    case 'canVoidTransaction': return user.canVoidTransaction;
    case 'canManageStock': return user.canManageStock;
    case 'canCreateCustomer': return user.canCreateCustomer;
    case 'canCollectPayment': return user.canCollectPayment;
    case 'canProcessReturn': return user.canProcessReturn;
    default: return false;
  }
});

// PROVIDER BARU UNTUK CEK SESSION SAAT STARTUP
final authSessionProvider = FutureProvider<UserData?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('current_user_id');
  if (savedId == null) return null;
  
  final dao = ref.read(localDatabaseProvider).userDao;
  final user = await dao.getUserById(savedId);
  if (user != null && user.status == 'aktif') {
    ref.read(currentUserProvider.notifier).state = user;
    return user;
  } else {
    await prefs.remove('current_user_id');
    return null;
  }
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserData?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserData?>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  Future<void> loginByPassword(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginByPassword(username, password);
      if (user == null) throw Exception('Username / Password salah');
      await _saveSession(user.id);
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
      await _saveSession(user.id);
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
      await _saveSession(user.id);
      ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}