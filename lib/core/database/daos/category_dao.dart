import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<LocalDatabase> with _$CategoryDaoMixin {
  CategoryDao(LocalDatabase db) : super(db);

  Future<String> createCategory({
    required String name,
    required String type,
    String? description,
    String? iconName,
    String? colorHex,
    bool isFavorite = false,
    bool isSystem = true,
    int sortOrder = 0,
  }) async {
    final id = 'CAT-${DateTime.now().millisecondsSinceEpoch}-${sortOrder}';
    final code = 'PRK-${(1000 + sortOrder).toString()}';
    final slug = name.toLowerCase().replaceAll(' & ', '-').replaceAll(' ', '-').replaceAll('/', '-');

    await into(categories).insert(
      CategoriesCompanion.insert(
        id: id,
        code: Value(code),
        name: name,
        slug: Value(slug),
        type: type,
        description: Value(description?? name),
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        sortOrder: Value(sortOrder),
        status: const Value(CategoryStatus.aktif),
        isSynced: const Value(false),
        isFavorite: Value(isFavorite),
        isSystem: Value(isSystem),
      ),
    );
    return id;
  }

  Future<void> upsertCategory(CategoriesCompanion category) {
    return into(categories).insertOnConflictUpdate(
      category.copyWith(isSynced: const Value(false), updatedAt: Value(DateTime.now())),
    );
  }

  Stream<List<CategoryData>> watchByType(String type, {String sort = CategorySort.manual, String keyword = ''}) {
    var query = select(categories)..where((t) => t.type.equals(type) & t.status.equals(CategoryStatus.aktif));
    if (keyword.isNotEmpty) {
      query.where((t) => t.name.like('%$keyword%'));
    }
    switch (sort) {
      case CategorySort.az:
        query.orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
        break;
      case CategorySort.za:
        query.orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.desc)]);
        break;
      case CategorySort.mostUsed:
        query.orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc)]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm(expression: t.sortOrder), OrderingTerm(expression: t.name)]);
    }
    return query.watch();
  }

  Future<CategoryData?> getCategoryById(String id) => (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  Stream<List<CategoryData>> watchProductCategories() => watchByType(CategoryType.product);

  Future<void> softDeleteCategory(String id) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(status: const Value(CategoryStatus.nonaktif), isSynced: const Value(false), updatedAt: Value(DateTime.now())),
    );
  }

  // SEED 24 KATEGORI PERKAKAS SESUAI REQUEST KAMU
  Future<void> seedDefaults() async {
    final existing = await (select(categories)..where((t) => t.type.equals(CategoryType.product))).get();
    if (existing.isNotEmpty) return; // sudah ada, skip

    final List<Map<String, String>> productSeeds = [
      {'name': 'Perkakas Tangan', 'icon': 'handyman', 'color': '#FF9800'},
      {'name': 'Perkakas Listrik & Mesin', 'icon': 'power', 'color': '#FFC107'},
      {'name': 'Alat Ukur, Waterpass & Marking', 'icon': 'straighten', 'color': '#03A9F4'},
      {'name': 'Alat Pengaman & Safety Industri', 'icon': 'health_and_safety', 'color': '#F44336'},
      {'name': 'Perlengkapan Pendukung Kerja', 'icon': 'construction', 'color': '#795548'},
      {'name': 'Aksesoris Perkakas', 'icon': 'settings', 'color': '#607D8B'},
      {'name': 'Alat Instalasi Umum', 'icon': 'build', 'color': '#9C27B0'},
      {'name': 'Alat Las & Perlengkapan Las', 'icon': 'welding', 'color': '#FF5722'},
      {'name': 'Alat Angkat & Angkut', 'icon': 'forklift', 'color': '#424242'},
      {'name': 'Troli & Gerobak Industri', 'icon': 'shopping_cart', 'color': '#8D6E63'},
      {'name': 'Genset & Generator', 'icon': 'bolt', 'color': '#FFEB3B'},
      {'name': 'Kompresor & Air Tools', 'icon': 'air', 'color': '#00BCD4'},
      {'name': 'Alat Hidrolik & Pneumatik', 'icon': 'compress', 'color': '#009688'},
      {'name': 'Mesin Konstruksi Ringan', 'icon': 'engineering', 'color': '#FF9800'},
      {'name': 'Peralatan Bengkel & Otomotif', 'icon': 'car_repair', 'color': '#212121'},
      {'name': 'Peralatan Pertukangan Kayu', 'icon': 'carpenter', 'color': '#795548'},
      {'name': 'Alat Pertamanan & Kehutanan', 'icon': 'yard', 'color': '#4CAF50'},
      {'name': 'Tangga & Perancah', 'icon': 'stairs', 'color': '#9E9E9E'},
      {'name': 'Alat Kebersihan & Sanitasi Proyek', 'icon': 'cleaning_services', 'color': '#03A9F4'},
      {'name': 'Alat Penyimpanan & Organizer Perkakas', 'icon': 'inventory_2', 'color': '#607D8B'},
      {'name': 'Alat Perekat & Sealant Applicator', 'icon': 'format_paint', 'color': '#E91E63'},
      {'name': 'Alat Semprot Cat & Coating', 'icon': 'spray', 'color': '#FF5722'},
      {'name': 'Alat Instalasi Listrik & Tes', 'icon': 'electrical_services', 'color': '#FFC107'},
      {'name': 'Alat Plumbing & Sanitasi', 'icon': 'plumbing', 'color': '#2196F3'},
    ];

    for (int i = 0; i < productSeeds.length; i++) {
      final d = productSeeds[i];
      await createCategory(
        name: d['name']!,
        type: CategoryType.product,
        iconName: d['icon'],
        colorHex: d['color'],
        sortOrder: i,
        isFavorite: i < 5, // 5 pertama jadi favorit
      );
    }
  }
}

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return CategoryDao(db);
});