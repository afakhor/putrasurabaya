import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

part 'stock_mutation_dao.g.dart';

// ===========================================================================
// CONSTANTS & ENUMS UNTUK MUTASI STOK (5 SUMBER ATURAN EMAS)
// ===========================================================================
class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String itemMasuk = 'ITEM_MASUK';
  static const String prosesJadi = 'PROSES_JADI';
  static const String penjualan = 'PENJUALAN';
  static const String itemKeluar = 'ITEM_KELUAR';
  static const String perakitanBahan = 'PERAKITAN_BAHAN';
  static const String opname = 'OPNAME';
  // compat lama biar FAB baru tetap jalan
  static const String PEMBELIAN = pembelian;
  static const String PENJUALAN = penjualan;
  static const String OPNAME = opname;
}

// DTO
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

// ===========================================================================
// DAO - LOGIC LAMA KAMU UTUH, CUMA DITAMBAH COMPAT
// ===========================================================================
@DriftAccessor(tables: [Products, StockMutations])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

  // 1. KARTU STOK
  Stream<List<StockCardItemData>> watchKartuStok(String productId, {DateTime? startDate, DateTime? endDate}) {
    final query = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))])..where(stockMutations.productId.equals(productId));
    if (startDate!= null && endDate!= null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query.where(stockMutations.date.isBetweenValues(start, end));
    }
    query.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc), OrderingTerm(expression: stockMutations.createdAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map((row) => StockCardItemData(mutation: row.readTable(stockMutations), productName: row.readTable(products).name, productCode: row.readTable(products).code?? row.readTable(products).id, rackLocation: row.readTable(products).rackLocation)).toList());
  }

  Stream<List<StockCardItemData>> watchAllStockMutations({DateTime? startDate, DateTime? endDate, String? mutationTypeFilter}) {
    final query = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if (startDate!= null && endDate!= null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query.where(stockMutations.date.isBetweenValues(start, end));
    }
    if (mutationTypeFilter!= null && mutationTypeFilter.isNotEmpty) query.where(stockMutations.type.equals(mutationTypeFilter));
    query.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map((row) => StockCardItemData(mutation: row.readTable(stockMutations), productName: row.readTable(products).name, productCode: row.readTable(products).code?? '', rackLocation: row.readTable(products).rackLocation)).toList());
  }

  // 2. OPNAME REAL-TIME (LOGIC LAMA UTUH)
  Future<void> eksekusiStokOpname({required String productId, required double stokFisik, required String userId, required String keterangan, String? newRackLocation, DateTime? customDate}) async {
    await transaction(() async {
      final now = DateTime.now();
      final opnameDate = customDate?? now;
      final product = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (product == null) throw Exception('Produk tidak ditemukan.');
      final stokSebelum = product.stock;
      final selisih = stokFisik - stokSebelum;
      if (selisih == 0 && (newRackLocation == null || newRackLocation == product.rackLocation)) return;
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(stokFisik), rackLocation: Value(newRackLocation?? product.rackLocation), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(id: 'MUT-${now.microsecondsSinceEpoch}', productId: productId, type: StockMutationType.opname, quantity: selisih, stockBefore: stokSebelum, stockAfter: stokFisik, hppSnapshot: product.buyPrice, currentStockSnapshot: Value(stokFisik), referenceNo: 'OPN-${opnameDate.microsecondsSinceEpoch}', date: Value(opnameDate), userId: Value(userId), notes: Value('Opname Real-time: $keterangan (Selisih: ${selisih > 0? "+$selisih" : selisih})'), createdAt: Value(now), isSynced: const Value(false)));
      // increment usage kategori
      if(product.categoryId.isNotEmpty){
        final cat = await (select(categories)..where((t)=> t.name.equals(product.categoryId))).getSingleOrNull();
        if(cat!=null) await (update(categories)..where((t)=> t.id.equals(cat.id))).write(CategoriesCompanion(usageCount: Value(cat.usageCount+1)));
      }
    });
  }

  // 3. MANUAL IN/OUT (LOGIC LAMA UTUH)
  Future<void> catatMutasiManual({required String productId, required double qty, required String type, required String refNo, required String userId, String? notes, String? rackLocation}) async {
    if (type!= StockMutationType.itemMasuk && type!= StockMutationType.itemKeluar) throw Exception('Tipe mutasi manual tidak valid.');
    await transaction(() async {
      final now = DateTime.now();
      final product = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (product == null) throw Exception('Produk tidak ditemukan.');
      final stokSebelum = product.stock;
      final qtyPerubahan = type == StockMutationType.itemMasuk? qty.abs() : -qty.abs();
      final stokSesudah = stokSebelum + qtyPerubahan;
      if (stokSesudah < 0 &&!product.allowMinusStock) throw Exception('Stok "${product.name}" tidak cukup (Sisa: $stokSebelum).');
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(stokSesudah), rackLocation: Value(rackLocation?? product.rackLocation), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(id: 'MUT-${now.microsecondsSinceEpoch}', productId: productId, type: type, quantity: qtyPerubahan, stockBefore: stokSebelum, stockAfter: stokSesudah, hppSnapshot: product.buyPrice, currentStockSnapshot: Value(stokSesudah), referenceNo: refNo, date: Value(now), userId: Value(userId), notes: Value(notes?? (type == StockMutationType.itemMasuk? 'Input Barang Masuk Manual' : 'Barang Keluar Non-Penjualan')), createdAt: Value(now), isSynced: const Value(false)));
    });
  }

  // 4. PERAKITAN (LOGIC LAMA UTUH)
  Future<void> eksekusiPerakitanProduk({required String finishedProductId, required double finishedQtyToProduce, required List<AssemblyMaterialItem> materials, required String userId, String? notes}) async {
    if (finishedQtyToProduce <= 0) throw Exception('Jumlah produksi harus >0.');
    await transaction(() async {
      final now = DateTime.now();
      final refNo = 'ASM-${now.microsecondsSinceEpoch}';
      for (final mat in materials) {
        final rawProduct = await (select(products)..where((p) => p.id.equals(mat.rawProductId))).getSingleOrNull();
        if (rawProduct == null) throw Exception('Bahan baku ${mat.rawProductId} tidak ditemukan.');
        final totalNeeded = mat.quantityRequiredPerUnit * finishedQtyToProduce;
        final rawSebelum = rawProduct.stock;
        final rawSesudah = rawSebelum - totalNeeded;
        if (rawSesudah < 0 &&!rawProduct.allowMinusStock) throw Exception('Stok bahan baku "${rawProduct.name}" tidak cukup.');
        await (update(products)..where((p) => p.id.equals(mat.rawProductId))).write(ProductsCompanion(stock: Value(rawSesudah), updatedAt: Value(now)));
        await into(stockMutations).insert(StockMutationsCompanion.insert(id: 'MUT-RAW-${now.microsecondsSinceEpoch}-${mat.rawProductId}', productId: mat.rawProductId, type: StockMutationType.perakitanBahan, quantity: -totalNeeded, stockBefore: rawSebelum, stockAfter: rawSesudah, hppSnapshot: rawProduct.buyPrice, currentStockSnapshot: Value(rawSesudah), referenceNo: refNo, date: Value(now), userId: Value(userId), notes: Value('Penggunaan Bahan Baku Ref: $refNo'), createdAt: Value(now), isSynced: const Value(false)));
      }
      final finishedProduct = await (select(products)..where((p) => p.id.equals(finishedProductId))).getSingleOrNull();
      if (finishedProduct == null) throw Exception('Produk jadi tidak ditemukan.');
      final finSebelum = finishedProduct.stock;
      final finSesudah = finSebelum + finishedQtyToProduce;
      await (update(products)..where((p) => p.id.equals(finishedProductId))).write(ProductsCompanion(stock: Value(finSesudah), updatedAt: Value(now)));
      await into(stockMutations).insert(StockMutationsCompanion.insert(id: 'MUT-FIN-${now.microsecondsSinceEpoch}', productId: finishedProductId, type: StockMutationType.prosesJadi, quantity: finishedQtyToProduce, stockBefore: finSebelum, stockAfter: finSesudah, hppSnapshot: finishedProduct.buyPrice, currentStockSnapshot: Value(finSesudah), referenceNo: refNo, date: Value(now), userId: Value(userId), notes: Value(notes?? 'Hasil Perakitan'), createdAt: Value(now), isSynced: const Value(false)));
    });
  }

  Future<void> updateLokasiRak(String productId, String newRackLocation) async {
    await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRackLocation), updatedAt: Value(DateTime.now())));
  }

  Future<void> prosesPerbaikanSaldo(String productId) async {
    await transaction(() async {
      final history = await (select(stockMutations)..where((m) => m.productId.equals(productId))..orderBy([(m) => OrderingTerm(expression: m.date, mode: OrderingMode.asc)), (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.asc))]).get();
      if (history.isEmpty) return;
      double runningStock = 0.0;
      for (int i = 0; i < history.length; i++) {
        final mut = history[i];
        double stockBefore = runningStock;
        double stockAfter = stockBefore + mut.quantity;
        if (mut.type == StockMutationType.opname) stockAfter = stockBefore + mut.quantity;
        await (update(stockMutations)..where((m) => m.id.equals(mut.id))).write(StockMutationsCompanion(stockBefore: Value(stockBefore), stockAfter: Value(stockAfter), currentStockSnapshot: Value(stockAfter)));
        runningStock = stockAfter;
      }
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(runningStock), updatedAt: Value(DateTime.now())));
    });
  }

  // COMPAT UNTUK FAB BARU
  Future<void> addMutation({required String productId, required String type, required double quantity, required double stockAfter, required double hpp, String? variantId, String refNo='ADJUST', String? notes, String? userId}) async {
    final prod = await (select(products)..where((p)=> p.id.equals(productId))).getSingleOrNull();
    final before = prod?.stock?? (stockAfter - quantity);
    await into(stockMutations).insert(StockMutationsCompanion.insert(id:'MUT-${DateTime.now().microsecondsSinceEpoch}', productId:productId, variantId: Value(variantId), type:type, quantity:quantity, stockBefore: before, stockAfter: stockAfter, hppSnapshot: hpp, currentStockSnapshot: Value(stockAfter), referenceNo: refNo, date: Value(DateTime.now()), userId: Value(userId), notes: Value(notes), createdAt: Value(DateTime.now()), isSynced: const Value(false)));
  }
}

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return StockMutationDao(db);
});

final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  final dao = ref.watch(stockMutationDaoProvider);
  return dao.watchKartuStok(productId);
});

final allStockMutationsStreamProvider = StreamProvider<List<StockCardItemData>>((ref) {
  final dao = ref.watch(stockMutationDaoProvider);
  return dao.watchAllStockMutations();
});