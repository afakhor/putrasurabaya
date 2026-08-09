import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/category_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, ProductUnits, ProductVariants, ProductAssets, Categories, StockMutations])
class ProductDao extends DatabaseAccessor<LocalDatabase> with _$ProductDaoMixin {
  ProductDao(LocalDatabase db) : super(db);

  Stream<List<ProductData>> watchAll() => select(products).watch();

  // FIX ANTI BLANK: tampilkan yang status null juga (data lama)
  Stream<List<ProductData>> watchActiveProducts() {
    return (select(products)
     ..where((t) => t.statusActive.equals('aktif') | t.statusActive.isNull() | t.statusActive.equals('') )
     ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
    ).watch();
  }

  Future<ProductData?> getProductById(String id) => (select(products)..where((t)=> t.id.equals(id))).getSingleOrNull();
  Future<ProductData?> getByCode(String code) => (select(products)..where((t)=> t.code.equals(code))).getSingleOrNull();
  Stream<ProductData?> watchProductById(String id) => (select(products)..where((t)=> t.id.equals(id))).watchSingleOrNull();
  Future<List<ProductData>> getLowStockProducts() => (select(products)..where((t)=> t.stock.isSmallerThan(t.minStock) & (t.statusActive.equals('aktif') | t.statusActive.isNull()))).get();
  Future<void> saveProduct(ProductsCompanion p) => into(products).insertOnConflictUpdate(p.copyWith(isSynced: const Value(false), updatedAt: Value(DateTime.now())));

  Future<String> createProductQuick({
    required String name,
    String? code,
    double stock = 0,
    double buyPrice = 0,
    String? rackLocation,
    String? categoryId,
    String? brand,
  }) async {
    final id = 'PRD-${DateTime.now().millisecondsSinceEpoch}';
    await into(products).insert(ProductsCompanion.insert(
      id: id,
      name: name,
      code: Value(code?? 'SKU-${id.substring(4,9)}'),
      shortName: Value(name),
      brand: Value(brand),
      stock: Value(stock),
      buyPrice: Value(buyPrice),
      sellPriceGeneral: const Value(0),
      sellPriceTier1: const Value(0),
      sellPriceTier2: const Value(0),
      sellPriceTier3: const Value(0),
      minStock: const Value(5),
      maxStock: const Value(100),
      rackLocation: Value(rackLocation),
      categoryId: Value(categoryId?? 'Perkakas Tangan'),
      unit: const Value('pcs'),
      statusActive: const Value('aktif'),
      allowMinusStock: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
    return id;
  }

  Future<void> softDeleteProduct(String id) async {
    await (update(products)..where((t)=> t.id.equals(id))).write(ProductsCompanion(
      statusActive: const Value('nonaktif'),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
  }

  Future<Map<String, double>> getTurnover30Days() async {
    final thirty = DateTime.now().subtract(const Duration(days: 30));
    final q = await (select(stockMutations)..where((t)=> t.type.equals('penjualan') & t.date.isBiggerOrEqualValue(thirty))).get();
    final map = <String, double>{};
    for(final m in q){
      map[m.productId] = (map[m.productId]??0) + m.quantity.abs();
    }
    return map;
  }
}