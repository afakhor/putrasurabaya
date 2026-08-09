import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';

part 'user_dao.g.dart';

class UserRole {
  static const String owner = 'owner';
  static const String superuser = 'superuser';
  static const String admin = 'admin';
  static const String kasir = 'kasir';
  static const String salesman = 'salesman';
}

class UserStatus {
  static const String aktif = 'aktif';
  static const String nonAktif = 'non_aktif';
  static const String suspended = 'suspended';
}

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<LocalDatabase> with _$UserDaoMixin {
  UserDao(LocalDatabase db) : super(db);

  Future<UserData?> validatePin(String pinCode) async {
    return (select(users)..where((u) => u.pinCode.equals(pinCode) & u.status.equals(UserStatus.aktif))).getSingleOrNull();
  }
  Future<UserData?> validateUserPassword(String username, String passwordHash) async {
    return (select(users)..where((u) => u.username.equals(username) & u.passwordHash.equals(passwordHash) & u.status.equals(UserStatus.aktif))).getSingleOrNull();
  }
  Future<UserData?> validateApiKey(String apiKey) async {
    return (select(users)..where((u) => u.apiKey.equals(apiKey) & u.status.equals(UserStatus.aktif))).getSingleOrNull();
  }
  Future<UserData?> getUserById(String userId) => (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  Future<UserData?> getUserByRole(String role) => (select(users)..where((u) => u.role.equals(role) & u.status.equals(UserStatus.aktif))..limit(1)).getSingleOrNull();

  // FIX BUILD APK - TAMBAHAN INI SAJA
  Future<List<UserData>> getAllUsers() => select(users).get();
  Stream<List<UserData>> watchAllUsersList() => select(users).watch();

  String generateApiKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    String randomPart(int len) => List.generate(len, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'KEY-${randomPart(4)}-${randomPart(4)}-${randomPart(4)}';
  }
  Future<String> regenerateApiKey(String userId) async {
    final newKey = generateApiKey();
    await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(apiKey: Value(newKey), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
    return newKey;
  }
  Future<void> updateApiKey(String userId, String newKey) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(apiKey: Value(newKey), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  }

  Future<UserData> createSalesmanWithApiKey({required String name, required String pin, String? salesmanCode, String? phone, String? salesArea}) async {
    final now = DateTime.now();
    final newId = 'USR-${now.microsecondsSinceEpoch}';
    final apiKey = generateApiKey();
    await into(users).insert(UsersCompanion.insert(
      id: newId, name: name, role: UserRole.salesman, pinCode: Value(pin), apiKey: Value(apiKey), phone: Value(phone), salesArea: Value(salesArea),
      canOverridePrice: const Value(false), canGiveDiscount: const Value(false), maxDiscountPercent: const Value(10), canVoidTransaction: const Value(false),
      canManageStock: const Value(false), canCreateCustomer: const Value(true), canCollectPayment: const Value(true), canProcessReturn: const Value(false),
      status: const Value(UserStatus.aktif), createdAt: Value(now), isSynced: const Value(false),
    ));
    return (await getUserById(newId))!;
  }

  Future<String> createUser({required String name, required String role, String? username, String? passwordHash, String? pinCode, String? phone, String? salesArea, String? address, bool canOverridePrice=false, bool canGiveDiscount=false, bool canCreateCustomer=true, bool canCollectPayment=true, bool canProcessReturn=false, bool canVoidTransaction=false, bool canManageStock=false, double maxDiscountPercent=0.0, String? apiKey}) async {
    final now = DateTime.now();
    final newId = 'USR-${now.microsecondsSinceEpoch}';
    String? finalApiKey = apiKey?? (role == UserRole.salesman? generateApiKey() : null);
    await into(users).insert(UsersCompanion.insert(
      id: newId, name: name, role: role, username: Value(username), passwordHash: Value(passwordHash), pinCode: Value(pinCode), apiKey: Value(finalApiKey),
      phone: Value(phone), salesArea: Value(salesArea), address: Value(address),
      canOverridePrice: Value(canOverridePrice), canGiveDiscount: Value(canGiveDiscount), canCreateCustomer: Value(canCreateCustomer),
      canCollectPayment: Value(canCollectPayment), canProcessReturn: Value(canProcessReturn), canVoidTransaction: Value(canVoidTransaction),
      canManageStock: Value(canManageStock), maxDiscountPercent: Value(maxDiscountPercent),
      status: const Value(UserStatus.aktif), createdAt: Value(now), isSynced: const Value(false),
    ));
    return newId;
  }

  Future<void> updateUserFull(String userId, String name, String username, String password, String pin, String role, String status, bool canOverride, bool canDiscount, bool canVoid, bool canStock, bool canCreateCust, bool canCollect, bool canReturn, double maxDisc) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(
      name: Value(name), username: Value(username), passwordHash: Value(password), pinCode: Value(pin), role: Value(role), status: Value(status),
      canOverridePrice: Value(canOverride), canGiveDiscount: Value(canDiscount), canVoidTransaction: Value(canVoid), canManageStock: Value(canStock),
      canCreateCustomer: Value(canCreateCust), canCollectPayment: Value(canCollect), canProcessReturn: Value(canReturn),
      maxDiscountPercent: Value(maxDisc), updatedAt: Value(DateTime.now()), isSynced: const Value(false),
    ));
  }

  Future<void> updateUserProfile({required String userId, required String name, String? username, String? phone, String? address, String? salesArea}) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(name: Value(name), username: Value(username), phone: Value(phone), address: Value(address), salesArea: Value(salesArea), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  }
  Future<void> updateUserPermissions({required String userId, required bool canOverridePrice, required bool canGiveDiscount, required bool canCreateCustomer, required bool canCollectPayment, required bool canProcessReturn, required bool canVoidTransaction, required bool canManageStock, required double maxDiscountPercent}) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(canOverridePrice: Value(canOverridePrice), canGiveDiscount: Value(canGiveDiscount), canCreateCustomer: Value(canCreateCustomer), canCollectPayment: Value(canCollectPayment), canProcessReturn: Value(canProcessReturn), canVoidTransaction: Value(canVoidTransaction), canManageStock: Value(canManageStock), maxDiscountPercent: Value(maxDiscountPercent), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  }
  Future<void> updateUserPin(String userId, String newPin) async => await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(pinCode: Value(newPin), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  Future<void> updateUserPassword(String userId, String newPasswordHash) async => await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(passwordHash: Value(newPasswordHash), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  Future<void> setUserStatus(String userId, String status) async => await (update(users)..where((u) => u.id.equals(userId))).write(UsersCompanion(status: Value(status), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  Future<void> deleteUser(String userId) async => await (delete(users)..where((u) => u.id.equals(userId))).go();

  Stream<List<UserData>> watchAllActiveUsers() => (select(users)..where((u) => u.status.equals(UserStatus.aktif))..orderBy([(u) => OrderingTerm(expression: u.name)])).watch();
  Stream<List<UserData>> watchAllUsers() => (select(users)..orderBy([(u) => OrderingTerm(expression: u.name)])).watch();
  Stream<List<UserData>> watchAllSalesmen() => (select(users)..where((u) => u.role.equals(UserRole.salesman))..orderBy([(u) => OrderingTerm(expression: u.name)])).watch();
  Stream<List<UserData>> watchAllCashiers() => (select(users)..where((u) => u.role.equals(UserRole.kasir))..orderBy([(u) => OrderingTerm(expression: u.name)])).watch();
}

final userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return UserDao(db);
});
final activeUsersStreamProvider = StreamProvider<List<UserData>>((ref) => ref.watch(userDaoProvider).watchAllActiveUsers());
final salesmenStreamProvider = StreamProvider<List<UserData>>((ref) => ref.watch(userDaoProvider).watchAllSalesmen());