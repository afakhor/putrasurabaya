import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:uuid/uuid.dart';

part 'stock_mutation_dao.g.dart';

class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String itemMasuk = 'ITEM_MASUK';
  static const String prosesJadi = 'PROSES_JADI';
  static const String penjualan = 'PENJUALAN';
  static const String itemKeluar = 'ITEM_KELUAR';
  static const String perakitanBahan = 'PERAKITAN_BAHAN';
  static const String opname = 'OPNAME';
  static const String perbaikan = 'PERBAIKAN_SALDO';
  static bool isPenambah(String type) => [pembelian, itemMasuk, prosesJadi].contains(type);
  static bool isPengurang(String type) => [penjualan, itemKeluar, perakitanBahan].contains(type);
}

class AssemblyMaterialItem {
  final String rawProductId; final double quantityRequiredPerUnit;
  AssemblyMaterialItem({required this.rawProductId, required this.quantityRequiredPerUnit});
}
class StockCardItemData {
  final StockMutationData mutation; final String productName; final String productCode; final String? rackLocation;
  StockCardItemData({required this.mutation, required this.productName, required this.productCode, this.rackLocation});
}

@DriftAccessor(tables: [Products, StockMutations, Users, AuditLogs, FraudAlerts])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);
  final _uuid = const Uuid();

  // ========== 1. CORE ATOM TANPA TRANSACTION ==========
  Future<void> _coreMutation({
    required String productId,
    required String type,
    required double qtyPerubahan,
    required double hargaBeliMasuk,
    required String refNo,
    required String userId,
    String? notes,
    DateTime? customDate,
    String? newRack,
    String? variantId,
    bool skipAntiMinus = false,
  }) async {
    final now = DateTime.now();
    final date = customDate ?? now;
    final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
    if (prod == null) throw Exception('Produk $productId tidak ditemukan');
    final user = await (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
    final userRole = user?.role ?? 'staff';
    final sebelum = prod.stock;
    final hppLama = prod.buyPrice;
    final sesudah = sebelum + qtyPerubahan;
    if (qtyPerubahan == 0) throw Exception('Qty tidak boleh 0');
    if (!skipAntiMinus && !prod.allowMinusStock && sesudah < -0.0001) {
      throw Exception('STOK MINUS! ${prod.name} sisa ${sebelum.toStringAsFixed(2)}, mau keluar ${qtyPerubahan.abs()}');
    }
    double hppBaru = hppLama;
    if (qtyPerubahan > 0 && hargaBeliMasuk > 0) {
      hppBaru = sebelum <= 0 ? hargaBeliMasuk : ((sebelum * hppLama) + (qtyPerubahan * hargaBeliMasuk)) / sesudah;
    }
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(stock: Value(sesudah), buyPrice: Value(hppBaru), rackLocation: newRack != null ? Value(newRack) : const Value.absent(), updatedAt: Value(now), isSynced: const Value(false)),
    );
    final mutationId = 'MUT-${now.microsecondsSinceEpoch}-${_uuid.v4().substring(0, 4)}';
    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: mutationId, productId: productId, variantId: Value(variantId), type: type, quantity: qtyPerubahan,
      stockBefore: Value(sebelum), stockAfter: Value(sesudah), hppSnapshot: Value(hppBaru),
      currentStockSnapshot: Value(sesudah), referenceNo: refNo, date: Value(date),
      userId: Value(userId), notes: Value(notes), rackLocation: Value(newRack ?? prod.rackLocation),
      createdAt: Value(now), isSynced: const Value(false),
    ));
    final auditId = _uuid.v4();
    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: auditId, userId: userId, userRole: userRole, actionType: type,
      description: '$type $productId qty $qtyPerubahan ref $refNo', referenceId: Value(productId),
      oldValue: Value(jsonEncode({'stock': sebelum, 'hpp': hppLama, 'rack': prod.rackLocation})),
      newValue: Value(jsonEncode({'stock': sesudah, 'hpp': hppBaru, 'qty': qtyPerubahan, 'rack': newRack ?? prod.rackLocation, 'ref': refNo})),
    ));
    if (type == StockMutationType.opname && qtyPerubahan.abs() >= 1) {
      final isMerah = qtyPerubahan.abs() >= 3;
      await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
        id: _uuid.v4(), userId: userId, auditLogId: Value(auditId),
        fraudCategory: 'MANIPULASI_STOK_OPNAME', severity: isMerah ? 'merah' : 'kuning',
        title: isMerah ? 'OPNAME SELISIH BESAR >=3' : 'OPNAME SELISIH KECIL',
        detailAnalysis: 'Produk ${prod.name} selisih ${qtyPerubahan.abs()} pcs. Sebelum $sebelum jadi $sesudah. Ref $refNo Notes: $notes',
      ));
    }
    if (sesudah < 0) {
      await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
        id: _uuid.v4(), userId: userId, auditLogId: Value(auditId),
        fraudCategory: 'MINUS_STOK', severity: 'merah', title: 'STOK MINUS TERDETEKSI',
        detailAnalysis: 'Produk ${prod.name} minus $sesudah setelah $type ref $refNo',
      ));
    }
  }

  // ========== 2. CORE WRAPPER UNTUK LocalDatabase - ANTI NESTED ==========
  Future<void> catatPenjualanCore({required String productId, required double qty, required String refNo, required String userId, String? notes, String? variantId}) {
    return _coreMutation(productId: productId, type: StockMutationType.penjualan, qtyPerubahan: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: notes, variantId: variantId);
  }
  Future<void> catatPembelianCore({required String productId, required double qty, required double hargaBeli, required String refNo, required String userId, String? notes}) {
    return _coreMutation(productId: productId, type: StockMutationType.pembelian, qtyPerubahan: qty.abs(), hargaBeliMasuk: hargaBeli, refNo: refNo, userId: userId, notes: notes);
  }

  // ========== 3. WRAPPER 1 PINTU DENGAN TRANSACTION UNTUK UI ==========
  Future<void> _executeMutation({
    required String productId, required String type, required double qtyPerubahan,
    required double hargaBeliMasuk, required String refNo, required String userId,
    String? notes, DateTime? customDate, String? newRack, String? variantId,
    bool skipAntiMinus = false,
  }) async {
    return transaction(() async {
      await _coreMutation(productId: productId, type: type, qtyPerubahan: qtyPerubahan, hargaBeliMasuk: hargaBeliMasuk, refNo: refNo, userId: userId, notes: notes, customDate: customDate, newRack: newRack, variantId: variantId, skipAntiMinus: skipAntiMinus);
    });
  }

  // ========== 4. PUBLIC API UI ==========
  Future<void> catatPembelian({required String productId, required double qty, required double hargaBeli, required String refNo, required String userId, String? notes, String? newRack, DateTime? date}) {
    return _executeMutation(productId: productId, type: StockMutationType.pembelian, qtyPerubahan: qty.abs(), hargaBeliMasuk: hargaBeli, refNo: refNo, userId: userId, notes: notes ?? 'Pembelian Supplier', newRack: newRack, customDate: date);
  }
  Future<void> catatItemMasuk({required String productId, required double qty, double? hargaBeli, required String refNo, required String userId, String? notes, DateTime? date, String? newRack, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.itemMasuk, qtyPerubahan: qty.abs(), hargaBeliMasuk: hargaBeli ?? 0, refNo: refNo, userId: userId, notes: notes ?? 'Item Masuk', newRack: newRack, customDate: date, variantId: variantId);
  }
  Future<void> catatPenjualan({required String productId, required double qty, required String refNo, required String userId, String? notes, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.penjualan, qtyPerubahan: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: notes ?? 'Penjualan Kasir', variantId: variantId);
  }
  Future<void> catatItemKeluar({required String productId, required double qty, required String refNo, required String userId, String? notes, DateTime? date, String? variantId}) {
    return _executeMutation(productId: productId, type: StockMutationType.itemKeluar, qtyPerubahan: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: notes ?? 'Item Keluar', customDate: date, variantId: variantId);
  }
  Future<void> catatOpname({required String productId, required double stokFisik, required String refNo, required String userId, String? notes, DateTime? date, String? newRack, String? variantId}) async {
    final prod = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull(); if (prod == null) return;
    final selisih = stokFisik - prod.stock;
    if (selisih == 0 && newRack != null) { await updateLokasiRak(productId, newRack); return; }
    if (selisih == 0) return;
    return _executeMutation(productId: productId, type: StockMutationType.opname, qtyPerubahan: selisih, hargaBeliMasuk: prod.buyPrice, refNo: refNo, userId: userId, notes: notes ?? 'Opname fisik $stokFisik', customDate: date, newRack: newRack, variantId: variantId, skipAntiMinus: true);
  }
  Future<void> catatPerakitan({required String productJadiId, required double qtyJadi, required List<Map<String, dynamic>> bahan, required String refNo, required String userId}) async {
    return transaction(() async {
      for (final b in bahan) {
        await _coreMutation(productId: b['productId'], type: StockMutationType.perakitanBahan, qtyPerubahan: -(b['qty'] as double), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: 'Bahan untuk $productJadiId');
      }
      await _coreMutation(productId: productJadiId, type: StockMutationType.prosesJadi, qtyPerubahan: qtyJadi, hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: 'Hasil rakit ${bahan.length} bahan');
    });
  }
  Future<void> eksekusiPerakitanProduk({required String finishedProductId, required double finishedQtyToProduce, required List<AssemblyMaterialItem> materials, required String userId, String? notes}) async {
    return transaction(() async {
      final refNo = 'ASM-${DateTime.now().microsecondsSinceEpoch}';
      double totalHppBahanPerUnit = 0;
      for (final mat in materials) {
        final raw = await (select(products)..where((p) => p.id.equals(mat.rawProductId))).getSingleOrNull(); if (raw == null) continue;
        final need = mat.quantityRequiredPerUnit * finishedQtyToProduce;
        totalHppBahanPerUnit += raw.buyPrice * mat.quantityRequiredPerUnit;
        await _coreMutation(productId: raw.id, type: StockMutationType.perakitanBahan, qtyPerubahan: -need, hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: 'Bahan Rakitan $refNo');
      }
      await _coreMutation(productId: finishedProductId, type: StockMutationType.prosesJadi, qtyPerubahan: finishedQtyToProduce, hargaBeliMasuk: totalHppBahanPerUnit, refNo: refNo, userId: userId, notes: notes ?? 'Hasil Rakitan');
    });
  }
  Future<void> itemMasuk({required String productId, required double qty, required double hargaBeli, required String userId, String? notes, String? rack, String? variantId}) => catatItemMasuk(productId: productId, qty: qty, hargaBeli: hargaBeli, refNo: 'IN-${DateTime.now().millisecondsSinceEpoch}', userId: userId, notes: notes, newRack: rack, variantId: variantId);
  Future<void> itemKeluar({required String productId, required double qty, required String userId, String? notes, String? variantId}) => catatItemKeluar(productId: productId, qty: qty, refNo: 'OUT-${DateTime.now().millisecondsSinceEpoch}', userId: userId, notes: notes, variantId: variantId);
  Future<void> eksekusiStokOpname({required String productId, required double stokFisik, required String userId, required String keterangan, String? newRackLocation, DateTime? customDate, String? variantId}) => catatOpname(productId: productId, stokFisik: stokFisik, refNo: 'OPN-${(customDate ?? DateTime.now()).millisecondsSinceEpoch}', userId: userId, notes: keterangan, date: customDate, newRack: newRackLocation, variantId: variantId);
  Future<void> updateLokasiRak(String productId, String newRackLocation) async { await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRackLocation), updatedAt: Value(DateTime.now()), isSynced: const Value(false))); }
  Future<void> prosesPerbaikanSaldo(String productId) async {
    await transaction(() async {
      final list = await (select(stockMutations)..where((m) => m.productId.equals(productId))..orderBy([(m) => OrderingTerm.asc(m.date), (m) => OrderingTerm.asc(m.createdAt)])).get();
      if (list.isEmpty) return;
      double run = 0;
      for (final mut in list) {
        if (mut.type == StockMutationType.perbaikan) continue;
        final before = run; final after = before + mut.quantity;
        await (update(stockMutations)..where((m) => m.id.equals(mut.id))).write(StockMutationsCompanion(stockBefore: Value(before), stockAfter: Value(after), currentStockSnapshot: Value(after)));
        run = after;
      }
      await (update(products)..where((p) => p.id.equals(productId))).write(ProductsCompanion(stock: Value(run), updatedAt: Value(DateTime.now())));
    });
  }
  Stream<List<StockCardItemData>> watchKartuStok(String productId, {DateTime? startDate, DateTime? endDate}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    q.where(stockMutations.productId.equals(productId));
    if (startDate != null && endDate != null) q.where(stockMutations.date.isBetweenValues(DateTime(startDate.year, startDate.month, startDate.day), DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)));
    q.orderBy([OrderingTerm.asc(stockMutations.date)]);
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code ?? r.readTable(products).id, rackLocation: r.readTable(stockMutations).rackLocation ?? r.readTable(products).rackLocation)).toList());
  }
  Stream<List<StockCardItemData>> watchAllStockMutations({DateTime? startDate, DateTime? endDate, String? mutationTypeFilter, String? keyword}) {
    final q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if (startDate != null && endDate != null) q.where(stockMutations.date.isBetweenValues(DateTime(startDate.year, startDate.month, startDate.day), DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)));
    if (mutationTypeFilter != null && mutationTypeFilter.isNotEmpty) q.where(stockMutations.type.equals(mutationTypeFilter));
    if (keyword != null && keyword.isNotEmpty) q.where(products.name.like('%$keyword%') | products.code.like('%$keyword%') | stockMutations.referenceNo.like('%$keyword%'));
    q.orderBy([OrderingTerm.desc(stockMutations.date)]);
    return q.watch().map((rows) => rows.map((r) => StockCardItemData(mutation: r.readTable(stockMutations), productName: r.readTable(products).name, productCode: r.readTable(products).code ?? '', rackLocation: r.readTable(products).rackLocation)).toList());
  }
  Future<List<FraudAlertData>> getFraudUnresolved() => (select(fraudAlerts)..where((f) => f.isResolved.equals(false))..orderBy([(f) => OrderingTerm.desc(f.createdAt)])).get();
  Future<List<StockMutationData>> getOpnameBermasalah({int minSelisih = 3}) => (select(stockMutations)..where((t) => t.type.equals(StockMutationType.opname) & t.quantity.abs().isBiggerOrEqualValue(minSelisih.toDouble()))).get();
}

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) => StockMutationDao(ref.watch(localDatabaseProvider)));
final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, id) => ref.watch(stockMutationDaoProvider).watchKartuStok(id));
final allStockMutationsStreamProvider = StreamProvider.family<List<StockCardItemData>, ({DateTime? start, DateTime? end, String? type, String? keyword})>((ref, f) => ref.watch(stockMutationDaoProvider).watchAllStockMutations(startDate: f.start, endDate: f.end, mutationTypeFilter: f.type, keyword: f.keyword));
final mutationFilterProvider = StateProvider<String?>((ref) => null);