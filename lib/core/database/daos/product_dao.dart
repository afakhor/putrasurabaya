import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<LocalDatabase>
    with _$ProductDaoMixin {
  ProductDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. QUERY & STREAM PRODUK UNTUK POS / KASIR
  // ===========================================================================

  /// Stream seluruh produk aktif untuk halaman Kasir / POS (Urut Nama)
  Stream<List<ProductData>> watchActiveProducts() {
    return (select(products)
          ..where((tbl) => tbl.statusActive.equals('aktif'))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Stream Pencarian Produk Real-time (Berdasarkan Barcode, Kode, atau Nama)
  Stream<List<ProductData>> searchProducts(String query) {
    if (query.trim().isEmpty) return watchActiveProducts();
    
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    return (select(products)
          ..where((tbl) =>
              tbl.statusActive.equals('aktif') &
              (tbl.name.lower().like(cleanQuery) |
               tbl.barcode.like(cleanQuery) |
               tbl.code.like(cleanQuery)))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Stream Filter Produk Berdasarkan Kategori
  Stream<List<ProductData>> watchProductsByCategory(String categoryId) {
    return (select(products)
          ..where((tbl) =>
              tbl.categoryId.equals(categoryId) &
              tbl.statusActive.equals('aktif'))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Scan Barcode Cepat (Satu Produk)
  Future<ProductData?> getProductByBarcode(String barcode) {
    return (select(products)
          ..where((tbl) =>
              tbl.barcode.equals(barcode) & tbl.statusActive.equals('aktif')))
        .getSingleOrNull();
  }

  /// Ambil Detail 1 Produk Berdasarkan ID
  Future<ProductData?> getProductById(String id) {
    return (select(products)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Stream Detail 1 Produk Berdasarkan ID
  Stream<ProductData?> watchProductById(String id) {
    return (select(products)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  // ===========================================================================
  // 2. TRANSAKSI, EDIT, & MANAJEMEN STOK
  // ===========================================================================

  /// Tambah atau Edit Produk (Otomatis Update Timestamp & Flag Sync)
  Future<void> saveProduct(ProductsCompanion product) {
    final updatedCompanion = product.copyWith(
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    );
    return into(products).insertOnConflictUpdate(updatedCompanion);
  }

  /// Update stok secara parsial saat transaksi / penambahan barang / retur
  /// [deltaQuantity] berbentuk double (+ untuk Tambah Stok, - untuk Kurangi Stok)
  Future<void> updateStock(String productId, double deltaQuantity) async {
    final product = await getProductById(productId);
    if (product != null) {
      final newStock = product.stock + deltaQuantity;
      await (update(products)..where((tbl) => tbl.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(newStock < 0 ? 0.0 : newStock),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Soft Delete Produk (Nonaktifkan Produk tanpa Menghapus Riwayat Transaksi)
  Future<void> softDeleteProduct(String id) {
    return (update(products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(
        statusActive: const Value('nonaktif'),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final productDaoProvider = Provider<ProductDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ProductDao(db);
});

/// Stream provider utama yang di-watch oleh pos_page.dart untuk menampilkan katalog produk
final productsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  final dao = ref.watch(productDaoProvider);
  return dao.watchActiveProducts();
});

/// StateProvider untuk menampung teks pencarian kasir di POS
final posSearchQueryProvider = StateProvider<String>((ref) => '');

/// Stream provider pencarian dinamis yang di-watch oleh POS Search Bar
final filteredProductsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  final dao = ref.watch(productDaoProvider);
  final searchQuery = ref.watch(posSearchQueryProvider);
  return dao.searchProducts(searchQuery);
});
