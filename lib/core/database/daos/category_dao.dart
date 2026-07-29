import 'package:drift/drift.dart'; // Note: sesuaikan dengan package name project
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<LocalDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. MANAJEMEN PENAMBAHAN & PERUBAHAN (UPSERT)
  // ===========================================================================

  /// Tambah atau Update Kategori (Otomatis set status Sync = false)
  Future<void> upsertCategory(CategoriesCompanion category) {
    final updatedCompanion = category.copyWith(
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    );
    return into(categories).insertOnConflictUpdate(updatedCompanion);
  }

  /// Tambah Kategori Baru Secara Langsung
  Future<String> createCategory({
    required String name,
    required String type,
    String? description,
  }) async {
    final id = 'CAT-${DateTime.now().millisecondsSinceEpoch}';

    await into(categories).insert(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        type: type,
        description: Value(description),
        status: const Value(CategoryStatus.aktif),
        isSynced: const Value(false),
      ),
    );

    return id;
  }

  // ===========================================================================
  // 2. QUERY BY ID & UMUM
  // ===========================================================================

  /// Ambil Kategori berdasarkan ID
  Future<CategoryData?> getCategoryById(String id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Stream Kategori berdasarkan ID (Real-time Listener)
  Stream<CategoryData?> watchCategoryById(String id) {
    return (select(categories)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Stream Semua Kategori Aktif
  Stream<List<CategoryData>> watchAllActiveCategories() {
    return (select(categories)
          ..where((t) => t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  // ===========================================================================
  // 3. QUERY BERDASARKAN TIPE SPESIFIK (STREAM & FUTURE)
  // ===========================================================================

  /// Stream Kategori Berdasarkan Tipe Spesifik
  Stream<List<CategoryData>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((t) =>
              t.type.equals(type) & t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// 3. Ambil Kategori Produk (Future & Stream)
  Future<List<CategoryData>> getProductCategories() {
    return (select(categories)
          ..where((t) =>
              t.type.equals(CategoryType.product) &
              t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Stream<List<CategoryData>> watchProductCategories() {
    return watchCategoriesByType(CategoryType.product);
  }

  /// 4. Ambil Kategori Pengeluaran (Expense / Kas Out)
  Future<List<CategoryData>> getExpenseCategories() {
    return (select(categories)
          ..where((t) =>
              t.type.equals(CategoryType.expense) &
              t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Stream<List<CategoryData>> watchExpenseCategories() {
    return watchCategoriesByType(CategoryType.expense);
  }

  /// 5. Ambil Kategori Pemasukan (Cash In Non-Penjualan)
  Future<List<CategoryData>> getCashInCategories() {
    return (select(categories)
          ..where((t) =>
              t.type.equals(CategoryType.cashIn) &
              t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Stream<List<CategoryData>> watchCashInCategories() {
    return watchCategoriesByType(CategoryType.cashIn);
  }

  /// 6. Ambil Kategori Pelanggan / Tier
  Future<List<CategoryData>> getCustomerCategories() {
    return (select(categories)
          ..where((t) =>
              t.type.equals(CategoryType.customer) &
              t.status.equals(CategoryStatus.aktif))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Stream<List<CategoryData>> watchCustomerCategories() {
    return watchCategoriesByType(CategoryType.customer);
  }

  // ===========================================================================
  // 4. HAPUS & SOFT DELETE
  // ===========================================================================

  /// 7. Nonaktifkan Kategori (Soft Delete)
  Future<void> softDeleteCategory(String id) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        status: const Value(CategoryStatus.nonaktif),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// ===========================================================================
// HELPER KONSTANTA TIPE & STATUS KATEGORI
// ===========================================================================

abstract class CategoryType {
  static const String product = 'product';
  static const String expense = 'expense';
  static const String cashIn = 'cash_in';
  static const String customer = 'customer';
  static const String supplier = 'supplier';
}

abstract class CategoryStatus {
  static const String aktif = 'aktif';
  static const String nonaktif = 'nonaktif';
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return CategoryDao(db);
});
