import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, ProductUnits, ProductVariants, ProductAssets, Categories])
class ProductDao extends DatabaseAccessor<LocalDatabase> with _$ProductDaoMixin {
  ProductDao(LocalDatabase db) : super(db);

  Stream<List<ProductData>> watchAll() => select(products).watch();
  Stream<List<ProductData>> watchActiveProducts() => (select(products)..where((t)=> t.statusActive.equals('aktif'))).watch();
  Future<ProductData?> getProductById(String id) => (select(products)..where((t)=> t.id.equals(id))).getSingleOrNull();
  Future<ProductData?> getByCode(String code) => (select(products)..where((t)=> t.code.equals(code))).getSingleOrNull();
  Stream<ProductData?> watchProductById(String id) => (select(products)..where((t)=> t.id.equals(id))).watchSingleOrNull();
  Future<List<ProductData>> getLowStockProducts() => (select(products)..where((t)=> t.stock.isSmallerThan(t.minStock))).get();

  Future<void> saveProduct(ProductsCompanion p) => into(products).insertOnConflictUpdate(p.copyWith(isSynced: const Value(false), updatedAt: Value(DateTime.now())));
}