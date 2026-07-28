import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<LocalDatabase> with _$ProductDaoMixin {
  ProductDao(LocalDatabase db) : super(db);

  /// Stream seluruh produk aktif untuk halaman Kasir / POS
  Stream<List<ProductData>> watchActiveProducts() {
    return (select(products)
          ..where((tbl) => tbl.statusActive.equals('aktif'))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Tambah atau Edit Produk
  Future<void> saveProduct(ProductsCompanion product) {
    return into(products).insertOnConflictUpdate(product);
  }

  /// Update stok secara parsial saat transaksi / penambahan barang
  Future<void> updateStock(String productId, int deltaQuantity) async {
    final product = await (select(products)..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
    if (product != null) {
      final newStock = product.stock + deltaQuantity;
      await (update(products)..where((tbl) => tbl.id.equals(productId)))
          .write(ProductsCompanion(stock: Value(newStock < 0 ? 0.0 : newStock))); // <--- 0.0 double
    }
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final productDaoProvider = Provider<ProductDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ProductDao(db);
});

/// Stream provider yang di-watch oleh pos_page.dart
final productsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  final dao = ref.watch(productDaoProvider);
  return dao.watchActiveProducts();
});
