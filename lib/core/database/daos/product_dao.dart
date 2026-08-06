import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, ProductUnits, ProductVariants, ProductAssets, Categories])
class ProductDao extends DatabaseAccessor<LocalDatabase> with _$ProductDaoMixin {
  ProductDao(LocalDatabase db) : super(db);

  Stream<List<ProductData>> watchActiveProducts() {
    return (select(products)..where((tbl) => tbl.statusActive.equals('aktif'))..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).watch();
  }
  Stream<List<ProductData>> searchProducts(String query) {
    if (query.trim().isEmpty) return watchActiveProducts();
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    return (select(products)..where((tbl) => tbl.statusActive.equals('aktif') & (tbl.name.lower().like(cleanQuery) | tbl.barcode.like(cleanQuery) | (tbl.code.isNotNull() & tbl.code.like(cleanQuery))))..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).watch();
  }
  Stream<List<ProductData>> watchProductsByCategory(String categoryId) {
    return (select(products)..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.statusActive.equals('aktif'))..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).watch();
  }
  Future<ProductData?> getProductByBarcode(String barcode) => (select(products)..where((tbl) => tbl.barcode.equals(barcode) & tbl.statusActive.equals('aktif'))).getSingleOrNull();
  Future<ProductData?> getProductById(String id) => (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<ProductData?> watchProductById(String id) => (select(products)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  Future<ProductData?> getByCode(String code) => (select(products)..where((tbl) => tbl.code.equals(code))).getSingleOrNull();
  Future<List<ProductData>> getLowStockProducts() => (select(products)..where((tbl) => tbl.stock.isSmallerThan(tbl.minStock) & tbl.statusActive.equals('aktif'))).get();

  Future<void> saveProduct(ProductsCompanion product) async {
    await transaction(() async {
      await into(products).insertOnConflictUpdate(product.copyWith(isSynced: const Value(false), updatedAt: Value(DateTime.now())));
      final catId = product.categoryId.value;
      if (catId.isNotEmpty) {
        final cat = await (select(categories)..where((t) => t.name.equals(catId) | t.id.equals(catId))).getSingleOrNull();
        if (cat != null) {
          await (update(categories)..where((t) => t.id.equals(cat.id))).write(CategoriesCompanion(usageCount: Value(cat.usageCount + 1), updatedAt: Value(DateTime.now())));
        }
      }
    });
  }
  Future<void> saveFullProduct({required ProductsCompanion product, List<ProductUnitsCompanion> units = const [], List<ProductVariantsCompanion> variants = const []}) async {
    await transaction(() async {
      final pid = product.id.value;
      await into(products).insertOnConflictUpdate(product.copyWith(isSynced: const Value(false), updatedAt: Value(DateTime.now())));
      if (units.isNotEmpty) {
        await (delete(productUnits)..where((t) => t.productId.equals(pid))).go();
        for (final u in units) { await into(productUnits).insert(u); }
      }
      if (variants.isNotEmpty) {
        await (delete(productVariants)..where((t) => t.productId.equals(pid))).go();
        for (final v in variants) { await into(productVariants).insert(v); }
      }
    });
  }

  // updateStock DIHAPUS - LANGGAR 1 PINTU!

  Future<void> softDeleteProduct(String id) => (update(products)..where((tbl) => tbl.id.equals(id))).write(ProductsCompanion(statusActive: const Value('nonaktif'), isSynced: const Value(false), updatedAt: Value(DateTime.now())));
  Future<void> hardDeleteProduct(String id) async {
    await transaction(() async {
      await (delete(productAssets)..where((t) => t.productId.equals(id))).go();
      await (delete(productUnits)..where((t) => t.productId.equals(id))).go();
      await (delete(productVariants)..where((t) => t.productId.equals(id))).go();
      // JANGAN HAPUS stockMutations - itu buku besar audit
      await (delete(products)..where((t) => t.id.equals(id))).go();
    });
  }
  Future<List<ProductData>> getAllProducts() => select(products).get();
  Stream<List<ProductData>> watchAll() => select(products).watch();
}

final productDaoProvider = Provider<ProductDao>((ref) { final db = ref.watch(localDatabaseProvider); return ProductDao(db); });
final productsStreamProvider = StreamProvider<List<ProductData>>((ref) => ref.watch(productDaoProvider).watchActiveProducts());
final posSearchQueryProvider = StateProvider<String>((ref) => '');
final filteredProductsStreamProvider = StreamProvider<List<ProductData>>((ref) { final dao = ref.watch(productDaoProvider); final q = ref.watch(posSearchQueryProvider); return dao.searchProducts(q); });
final lowStockProductsProvider = FutureProvider<List<ProductData>>((ref) async => ref.watch(productDaoProvider).getLowStockProducts());