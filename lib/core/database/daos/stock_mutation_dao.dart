import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

part 'stock_mutation_dao.g.dart';

@DriftAccessor(tables: [Products, StockMutations])
class StockMutationDao extends DatabaseAccessor<LocalDatabase>
    with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

  /// 1. KARTU STOK: History lengkap mutasi per produk secara kronologis
  Stream<List<StockMutationData>> watchKartuStok(String productId) {
    return (select(stockMutations)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// 2. STOK OPNAME REAL-TIME (Audit Stok Fisik vs Program)
  Future<void> eksekusiStokOpname({
    required String productId,
    required double stokFisik,
    required String userId,
    required String keterangan,
    DateTime? customDate,
  }) async {
    await transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId)))
          .getSingle();

      final stokSebelum = product.stock;
      final selisih = stokFisik - stokSebelum;

      if (selisih == 0) return; // Tidak ada perubahan

      // Update Stok Master Produk
      await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(stock: Value(stokFisik)));

      // Catat Log Mutasi Opname
      final opnameDate = customDate ?? DateTime.now();
      final refNo = 'OPN-${opnameDate.millisecondsSinceEpoch}';

      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          type: 'OPNAME',
          quantity: selisih,
          stockBefore: stokSebelum,
          stockAfter: stokFisik,
          hppSnapshot: product.buyPrice,
          referenceNo: refNo,
          date: Value(opnameDate),
          userId: Value(userId),
          notes: Value(keterangan),
        ),
      );
    });
  }

  /// 3. ITEM MASUK / KELUAR MANUAL (Non-Penjualan / Non-Pembelian)
  Future<void> catatMutasiManual({
    required String productId,
    required double qty,
    required String type, // 'ITEM_MASUK' / 'ITEM_KELUAR'
    required String refNo,
    required String userId,
    String? notes,
  }) async {
    await transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId)))
          .getSingle();

      final stokSebelum = product.stock;
      final qtyPerubahan = type == 'ITEM_MASUK' ? qty.abs() : -qty.abs();
      final stokSesudah = stokSebelum + qtyPerubahan;

      if (stokSesudah < 0 && !product.allowMinusStock) {
        throw Exception('Stok tidak mencukupi untuk dikeluarkan.');
      }

      await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(stock: Value(stokSesudah)));

      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          type: type,
          quantity: qtyPerubahan,
          stockBefore: stokSebelum,
          stockAfter: stokSesudah,
          hppSnapshot: product.buyPrice,
          referenceNo: refNo,
          userId: Value(userId),
          notes: Value(notes),
        ),
      );
    });
  }
}

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) {
  return StockMutationDao(ref.watch(localDatabaseProvider));
});
