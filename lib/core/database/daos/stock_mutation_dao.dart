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

  static bool isPenambah(String type) => [pembelian, itemMasuk, prosesJadi].contains(type);
  static bool isPengurang(String type) => [penjualan, itemKeluar, perakitanBahan].contains(type);
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

  // ================= CORE ENGINE IPOS 5 =================
  Future<void> _executeMutation({
    required String productId,
    required String type,
    required double qtyPerubahan, // + masuk, - keluar
    required double hargaBeliMasuk, // 0 jika keluar
    required String refNo,
    required String userId,
    String? notes,
    DateTime? customDate,
    String? newRack,
    String? variantId,
  }) async {
    await transaction(() async {
      final now = DateTime.now();
      final date = customDate?? now;
      final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (prod == null) throw Exception('Produk tidak ditemukan');

      final sebelum = prod.stock;
      final hppLama = prod.buyPrice;
      final sesudah = sebelum + qtyPerubahan;

      // ATURAN EMAS: Validasi minus
      if (sesudah < 0 &&!prod.allowMinusStock) {
        throw Exception('STOK MINUS! Stok ${prod.name} sisa $sebelum. Lakukan Opname tgl ${date.subtract(const Duration(hours: 1))} jam 09:00 terlebih dahulu.');
      }

      // HPP MOVING AVERAGE - RUMUS IPOS 5
      double hppBaru = hppLama;
      if (qtyPerubahan > 0) {
        if (hargaBeliMasuk > 0) {
          if (sebelum <= 0) {
            hppBaru = hargaBeliMasuk;
          } else {
            hppBaru = ((sebelum * hppLama) + (qtyPerubahan * hargaBeliMasuk)) / (sebelum + qtyPerubahan);
          }
        }
      }
      // Jika qty keluar / opname, HPP tidak berubah

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(sesudah),
          buyPrice: Value(hppBaru),
          rackLocation: newRack!= null? Value(newRack) : const Value.absent(),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-${now.microsecondsSinceEpoch}-${productId.substring(0, 4)}',
        productId: productId,
        variantId: Value(variantId),
        type: type,
        quantity: qtyPerubahan,
        stockBefore: Value(sebelum),
        stockAfter: Value(sesudah),
        hppSnapshot: Value(hppBaru),
        currentStockSnapshot: Value(sesudah),
        referenceNo: refNo,
        date: Value(date),
        userId: Value(userId),
        notes: Value(notes),
        createdAt: Value(now),
        isSynced: const Value(false),
      ));
    });
  }

  // ================= 5 SUMBER MUTASI - SESUAI SPEC.MD =================
  Future<void> catatPembelian({required String productId, required double qty, required double hargaBeli, required String refNo, required String userId}) {
    return _executeMutation(productId: productId, type: StockMutationType.pembelian, qtyPerubahan: qty.abs(), hargaBeliMasuk: hargaBeli, refNo: refNo, userId: userId, notes: 'Pembelian Supplier');
  }

  Future<void> itemMasuk({required String productId, required double qty, required double hargaBeli, required String userId, String? notes, String? rack, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.itemMasuk, qtyPerubahan: qty.abs(), hargaBeliMasuk: hargaBeli, refNo: 'IN-${DateTime.now().millisecondsSinceEpoch}', userId: userId, notes: notes?? 'Item Masuk', newRack: rack, variantId: variantId);
  }

  Future<void> itemKeluar({required String productId, required double qty, required String userId, String? notes, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.itemKeluar, qtyPerubahan: -qty.abs(), hargaBeliMasuk: 0, refNo: 'OUT-${DateTime.now().millisecondsSinceEpoch}', userId: userId, notes: notes?? 'Item Keluar', variantId: variantId);
  }

  Future<void> catatPenjualan({required String productId, required double qty, required String refNo, required String userId, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.penjualan, qtyPerubahan: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: 'Penjualan Kasir', variantId: variantId);
  }

  // OPNAME - SOP REAL-TIME
  Future<void> eksekusiStokOpname({required String productId, required double stokFisik, required String userId, required String keterangan, String? newRackLocation, DateTime? customDate, String? variantId}) async {
    final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
    if (prod == null) return;
    final selisih = stokFisik - prod.stock;
    if (selisih == 0) {
      if (newRackLocation!= null) await updateLokasiRak(productId, newRackLocation);
      return;
    }
    return _executeMutation(
      productId: productId,
      type: StockMutationType.opname,
      qtyPerubahan: selisih,
      hargaBeliMasuk: prod.buyPrice,
      refNo: 'OPN-${(customDate?? DateTime.now()).millisecondsSinceEpoch}',
      userId: userId,
      notes: keterangan,
      customDate: customDate,
      newRack: newRackLocation,
      variantId: variantId,
    );
  }

  Future<void> eksekusiPerakitanProduk({required String finishedProductId, required double finishedQtyToProduce, required List<AssemblyMaterialItem> materials, required String userId, String? notes}) async {
    await transaction(() async {
      final now = DateTime.now();
      final refNo = 'ASM-${now.microsecondsSinceEpoch}';
      for (final mat in materials) {
        final raw = await (select(products)..where((p) => p.id.equals(mat.rawProductId))).getSingleOrNull();
        if (raw == null) continue;
        final need = mat.quantityRequiredPerUnit * finishedQtyToProduce;
        await _executeMutation(productId: raw.id, type: StockMutationType.perakitanBahan, qtyPerubahan: -need, hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: 'Bahan Rakitan $refNo');
      }
      // Hitung HPP baru produk jadi dari total HPP bahan
      double totalHppBahan = 0;
      for (final mat in materials) {
        final raw = await (select(products)..where((p) => p.id.equals(mat.rawProductId))).getSingleOrNull();
        if (raw!= null) totalHppBahan += raw.buyPrice * mat.quantityRequiredPerUnit;
      }
      await _executeMutation(productId: finishedProductId, type: StockMutationType.prosesJadi, qtyPerubahan: finishedQtyToProduce, hargaBeliMasuk: totalHppBahan, refNo: refNo, userId: userId, notes: notes?? 'Hasil Rakitan');
    });
  }

  // ================= REPORTING =================
  Stream<List<StockCardItemData>> watchKartuStok(String productId, {DateTime? startDate, DateTime? endDate}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    q.where(stockMutations.productId.equals(productId));
    if (startDate!= null && endDate!= null) {
      q.where(stockMutations.date.isBetweenValues(DateTime(startDate.year, startDate.month, startDate.day), DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)));
    }
    q.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.asc)]); // ASC biar urut kartu stok
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code?? r.readTable(products).id, rackLocation: r.readTable(products).rackLocation)).toList());
  }

  Stream<List<StockCardItemData>> watchAllStockMutations({DateTime? startDate, DateTime? endDate, String? mutationTypeFilter, String? keyword}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if (startDate!= null && endDate!= null) q.where(stockMutations.date.isBetweenValues(DateTime(startDate.year, startDate.month, startDate.day), DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)));
    if (mutationTypeFilter!= null && mutationTypeFilter.isNotEmpty) q.where(stockMutations.type.equals(mutationTypeFilter));
    if (keyword!= null && keyword.isNotEmpty) q.where(products.name.like('%$keyword%') | products.code.like('%$keyword%'));
    q.orderBy([OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc)]);
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code?? '', rackLocation: r.readTable(products).rackLocation)).toList());
  }

  Future<void> updateLokasiRak(String productId, String newRackLocation) async {
    await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRackLocation), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  }

  Future<void> prosesPerbaikanSaldo(String productId) async {
    await transaction(() async {
      final list = await (select(stockMutations)..where((m) => m.productId.equals(productId))..orderBy([(m) => OrderingTerm(expression: m.date, mode: OrderingMode.asc)])).get();
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
}

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) => StockMutationDao(ref.watch(localDatabaseProvider)));
final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, id) => ref.watch(stockMutationDaoProvider).watchKartuStok(id));
final allStockMutationsStreamProvider = StreamProvider.family<List<StockCardItemData>, ({DateTime? start, DateTime? end, String? type, String? keyword})>((ref, f) => ref.watch(stockMutationDaoProvider).watchAllStockMutations(startDate: f.start, endDate: f.end, mutationTypeFilter: f.type, keyword: f.keyword));
final mutationFilterProvider = StateProvider<String?>((ref) => null);