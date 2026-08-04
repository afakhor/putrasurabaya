import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

part 'stock_mutation_dao.g.dart';

class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String itemMasuk = 'ITEM_MASUK';
  static const String prosesJadi = 'PROSES_JADI';
  static const String penjualan = 'PENJUALAN';
  static const String itemKeluar = 'ITEM_KELUAR';
  static const String perakitanBahan = 'PERAKITAN_BAHAN';
  static const String opname = 'OPNAME';
  static const String PEMBELIAN = pembelian;
  static const String PENJUALAN = penjualan;
  static const String OPNAME = opname;
}

class AssemblyMaterialItem {
  final String rawProductId;
  final double quantityRequiredPerUnit;
  AssemblyMaterialItem({required this.rawProductId, required this.quantityRequiredPerUnit});
}

class StockCardItemData {
  final StockMutationData mutation;
  final String productName;
  final String productCode;
  final String? rackLocation;
  StockCardItemData({required this.mutation, required this.productName, required this.productCode, this.rackLocation});
}

@DriftAccessor(tables: [Products, StockMutations])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

  Stream<List<StockCardItemData>> watchKartuStok(String productId, {DateTime? startDate, DateTime? endDate}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    q.where(stockMutations.productId.equals(productId));
    if (startDate != null && endDate != null) {
      final s = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      q.where(stockMutations.date.isBetweenValues(s, e));
    }
    q.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc)]);
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code ?? r.readTable(products).id, rackLocation: r.readTable(products).rackLocation)).toList());
  }

  Stream<List<StockCardItemData>> watchAllStockMutations({DateTime? startDate, DateTime? endDate, String? mutationTypeFilter}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if (startDate != null && endDate != null) {
      final s = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      q.where(stockMutations.date.isBetweenValues(s, e));
    }
    if (mutationTypeFilter != null && mutationTypeFilter.isNotEmpty) {
      q.where(stockMutations.type.equals(mutationTypeFilter));
    }
    q.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc)]);
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code ?? '', rackLocation: r.readTable(products).rackLocation)).toList());
  }

  Future<void> eksekusiStokOpname({required String productId, required double stokFisik, required String userId, required String keterangan, String? newRackLocation, DateTime? customDate}) async {
    await transaction(() async {
      final now = DateTime.now();
      final opDate = customDate ?? now;
      final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (prod == null) return;
      final sebelum = prod.stock;
      final selisih = stokFisik - sebelum;
      if (selisih == 0) return;
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(stokFisik), rackLocation: Value(newRackLocation ?? prod.rackLocation), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-${now.microsecondsSinceEpoch}',
        productId: productId,
        type: StockMutationType.opname,
        quantity: selisih,
        stockBefore: sebelum,
        stockAfter: stokFisik,
        hppSnapshot: prod.buyPrice,
        currentStockSnapshot: Value(stokFisik),
        referenceNo: 'OPN-${opDate.microsecondsSinceEpoch}',
        date: Value(opDate),
        userId: Value(userId),
        notes: Value(keterangan),
        createdAt: Value(now),
        isSynced: const Value(false),
      ));
    });
  }

  Future<void> catatMutasiManual({required String productId, required double qty, required String type, required String refNo, required String userId, String? notes, String? rackLocation}) async {
    await transaction(() async {
      final now = DateTime.now();
      final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (prod == null) return;
      final sebelum = prod.stock;
      final perubahan = type == StockMutationType.itemMasuk ? qty.abs() : -qty.abs();
      final sesudah = sebelum + perubahan;
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(sesudah), rackLocation: Value(rackLocation ?? prod.rackLocation), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-${now.microsecondsSinceEpoch}',
        productId: productId,
        type: type,
        quantity: perubahan,
        stockBefore: sebelum,
        stockAfter: sesudah,
        hppSnapshot: prod.buyPrice,
        currentStockSnapshot: Value(sesudah),
        referenceNo: refNo,
        date: Value(now),
        userId: Value(userId),
        notes: Value(notes ?? 'Manual'),
        createdAt: Value(now),
        isSynced: const Value(false),
      ));
    });
  }

  Future<void> eksekusiPerakitanProduk({required String finishedProductId, required double finishedQtyToProduce, required List<AssemblyMaterialItem> materials, required String userId, String? notes}) async {
    await transaction(() async {
      final now = DateTime.now();
      final refNo = 'ASM-${now.microsecondsSinceEpoch}';
      for (final mat in materials) {
        final raw = await (select(products)..where((p) => p.id.equals(mat.rawProductId))).getSingleOrNull();
        if (raw == null) continue;
        final need = mat.quantityRequiredPerUnit * finishedQtyToProduce;
        final sesudah = raw.stock - need;
        await (update(products)..where((p) => p.id.equals(raw.id))).write(ProductsCompanion(stock: Value(sesudah), updatedAt: Value(now)));
        await into(stockMutations).insert(StockMutationsCompanion.insert(
          id: 'MUT-RAW-${now.microsecondsSinceEpoch}-${raw.id}',
          productId: raw.id,
          type: StockMutationType.perakitanBahan,
          quantity: -need,
          stockBefore: raw.stock,
          stockAfter: sesudah,
          hppSnapshot: raw.buyPrice,
          currentStockSnapshot: Value(sesudah),
          referenceNo: refNo,
          date: Value(now),
          userId: Value(userId),
          notes: Value('Bahan $refNo'),
          createdAt: Value(now),
          isSynced: const Value(false),
        ));
      }
      final fin = await (select(products)..where((p) => p.id.equals(finishedProductId))).getSingleOrNull();
      if (fin == null) return;
      final sesudah = fin.stock + finishedQtyToProduce;
      await (update(products)..where((p) => p.id.equals(fin.id))).write(ProductsCompanion(stock: Value(sesudah), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-FIN-${now.microsecondsSinceEpoch}',
        productId: fin.id,
        type: StockMutationType.prosesJadi,
        quantity: finishedQtyToProduce,
        stockBefore: fin.stock,
        stockAfter: sesudah,
        hppSnapshot: fin.buyPrice,
        currentStockSnapshot: Value(sesudah),
        referenceNo: refNo,
        date: Value(now),
        userId: Value(userId),
        notes: Value(notes ?? 'Jadi'),
        createdAt: Value(now),
        isSynced: const Value(false),
      ));
    });
  }

  Future<void> updateLokasiRak(String productId, String newRackLocation) async {
    await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRackLocation), updatedAt: Value(DateTime.now())));
  }

  Future<void> prosesPerbaikanSaldo(String productId) async {
    await transaction(() async {
      final list = await (select(stockMutations)..where((m) => m.productId.equals(productId))..orderBy([(m) => OrderingTerm(expression: m.date)])).get();
      double run = 0;
      for (final mut in list) {
        final before = run;
        final after = before + mut.quantity;
        await (update(stockMutations)..where((m) => m.id.equals(mut.id))).write(StockMutationsCompanion(stockBefore: Value(before), stockAfter: Value(after), currentStockSnapshot: Value(after)));
        run = after;
      }
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(run), updatedAt: Value(DateTime.now())));
    });
  }

  Future<void> addMutation({required String productId, required String type, required double quantity, required double stockAfter, required double hpp, String? variantId, String refNo = 'ADJUST', String? notes, String? userId}) async {
    final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
    final before = prod != null ? prod.stock : stockAfter - quantity;
    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: 'MUT-${DateTime.now().microsecondsSinceEpoch}',
      productId: productId,
      variantId: Value(variantId),
      type: type,
      quantity: quantity,
      stockBefore: before,
      stockAfter: stockAfter,
      hppSnapshot: hpp,
      currentStockSnapshot: Value(stockAfter),
      referenceNo: refNo,
      date: Value(DateTime.now()),
      userId: Value(userId),
      notes: Value(notes),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
  }
}

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return StockMutationDao(db);
});

final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  return ref.watch(stockMutationDaoProvider).watchKartuStok(productId);
});

final allStockMutationsStreamProvider = StreamProvider<List<StockCardItemData>>((ref) {
  return ref.watch(stockMutationDaoProvider).watchAllStockMutations();
});