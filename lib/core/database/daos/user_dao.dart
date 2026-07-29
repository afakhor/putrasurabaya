import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<LocalDatabase> with _$UserDaoMixin {
  UserDao(LocalDatabase db) : super(db);

  /// Validasi Login Salesman via API Key
  Future<UserData?> validateApiKey(String apiKey) async {
    final user = await (select(users)
          ..where((u) => u.apiKey.equals(apiKey) & u.status.equals('aktif')))
        .getSingleOrNull();
    return user;
  }

  /// Generator API Key untuk Salesman baru (Hanya SuperUser)
  Future<String> generateApiKeyForSalesman({
    required String name,
    required String phone,
    required String salesArea,
    required String address,
  }) async {
    final newId = 'USR-${DateTime.now().millisecondsSinceEpoch}';
    final generatedApiKey = 'KEY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await into(users).insert(
      UsersCompanion.insert(
        id: newId,
        name: name,
        role: 'salesman',
        apiKey: Value(generatedApiKey),
        phone: Value(phone),
        salesArea: Value(salesArea),
        address: Value(address),
        status: const Value('aktif'),
      ),
    );

    return generatedApiKey;
  }

  /// Ubah Status Suspend User
  Future<void> setUserStatus(String userId, String status) {
    return (update(users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(status: Value(status)));
  }

  /// Ambil Semua User
  Stream<List<UserData>> watchAllUsers() => select(users).watch();
}

final userDaoProvider = Provider<UserDao>((ref) {
  return UserDao(ref.watch(localDatabaseProvider));
});
