import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<LocalDatabase> with _$CategoryDaoMixin {
  CategoryDao(LocalDatabase db) : super(db);

  /// 1. Tambah atau Update Kategori
  Future<void> upsertCategory(CategoriesCompanion category) {
    return into(categories).insertOnConflictUpdate(category);
  }

  /// 2. Stream Kategori Berdasarkan Tipe Spesifik
  Stream<List<CategoryData>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((t) => t.type.equals(type) & t.status.equals('aktif'))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// 3. Ambil Kategori Produk
  Future<List<CategoryData>> getProductCategories() {
    return (select(categories)
          ..where((t) => t.type.equals(CategoryType.product) & t.status.equals('aktif')))
        .get();
  }

  /// 4. Ambil Kategori Pengeluaran (Expense / Kas Out)
  Future<List<CategoryData>> getExpenseCategories() {
    return (select(categories)
          ..where((t) => t.type.equals(CategoryType.expense) & t.status.equals('aktif')))
        .get();
  }

  /// 5. Ambil Kategori Pemasukan (Cash In Non-Penjualan) <-- TAMBAHAN
  Future<List<CategoryData>> getCashInCategories() {
    return (select(categories)
          ..where((t) => t.type.equals(CategoryType.cashIn) & t.status.equals('aktif')))
        .get();
  }

  /// 6. Ambil Kategori Pelanggan / Tier
  Future<List<CategoryData>> getCustomerCategories() {
    return (select(categories)
          ..where((t) => t.type.equals(CategoryType.customer) & t.status.equals('aktif')))
        .get();
  }

  /// 7. Nonaktifkan Kategori (Soft Delete)
  Future<void> softDeleteCategory(String id) {
    return (update(categories)..where((t) => t.id.equals(id)))
        .write(const CategoriesCompanion(status: Value('nonaktif')));
  }
}

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return CategoryDao(ref.watch(localDatabaseProvider));
});
