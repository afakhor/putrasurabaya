import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';
import 'package:ud_putra_kasir/core/database/constant/audit_constant.dart';

part 'stock_mutation_dao.g.dart';

class StockCardItemData {
  final StockMutationData mutation;
  final ProductData product;
  StockCardItemData(this.mutation, this.product);
  String get productName => product.name;
}

class AssemblyMaterialItem {
  final String rawProductId;
  final double quantityRequiredPerUnit;
  AssemblyMaterialItem({required this.rawProductId, required this.quantityRequiredPerUnit});
}

class StockMutationType {
  static const masuk = 'masuk'; static const keluar = 'keluar'; static const opname = 'opname';
  static const penjualan = 'penjualan'; static const pembelian = 'pembelian'; static const perakitan = 'perakitan';
  static const all = [masuk, keluar, opname, penjualan, pembelian, perakitan];
}

enum StockAlert { aman, minus, hppNol, adjustmentLiar, hppLonjak, stokMati }

@DriftAccessor(tables: [Products, StockMutations, AuditLogs, FraudAlerts])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

  Future<void> _coreMutation({
    required String productId, required String type, required double qty,
    required double hargaBeliMasuk, required String refNo, required String userId,
    String? notes, DateTime? customDate, String? newRack, String? variantId, bool skipMinus=false,
    String? customerName, String? paymentStatus, int? tierHarga, double? hargaJualDipakai, double? totalTransaksi,
  }) async {
    final prod = await (select(products)..where((p)=> p.id.equals(productId))).getSingleOrNull();
    if(prod==null) throw Exception('Produk $productId tidak ada');
    final sebelum = prod.stock; final hppLama = prod.buyPrice; final sesudah = sebelum + qty;
    if(!skipMinus && !prod.allowMinusStock && sesudah < 0) throw Exception('Stok minus ${prod.name} sisa $sebelum');
    double hppBaru = hppLama;
    if(qty>0 && hargaBeliMasuk>0){ hppBaru = sebelum <=0 ? hargaBeliMasuk : ((sebelum*hppLama)+(qty*hargaBeliMasuk))/sesudah; }

    await (update(products)..where((p)=> p.id.equals(productId))).write(
      ProductsCompanion(stock: Value(sesudah), buyPrice: Value(hppBaru), lastBuyPrice: qty>0? Value(hargaBeliMasuk): const Value.absent(), rackLocation: newRack!=null? Value(newRack): const Value.absent(), updatedAt: Value(DateTime.now()), isSynced: Value(false))
    );

    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: 'MUT-${DateTime.now().microsecondsSinceEpoch}',
      productId: productId,
      type: type,
      quantity: qty,
      stockBefore: Value(sebelum),
      stockAfter: Value(sesudah),
      hppBefore: Value(hppLama),
      hppAfter: Value(hppBaru),
      hppSnapshot: Value(hppBaru),
      currentStockSnapshot: Value(sesudah),
      buyPriceAtThatTime: Value(hargaBeliMasuk),
      referenceNo: Value(refNo),
      referenceId: Value(refNo),
      date: Value(customDate?? DateTime.now()),
      userId: Value(userId),
      notes: Value(notes),
    ));

    String actionCCTV = type.toUpperCase();
    if(type == StockMutationType.pembelian || type == StockMutationType.masuk) actionCCTV = AuditAction.kulakHppMa;
    if(type == StockMutationType.penjualan) actionCCTV = tierHarga != null ? 'JUAL_TIER_$tierHarga' : AuditAction.jualTier1;
    if(type == StockMutationType.keluar) actionCCTV = 'KELUAR_${notes?.toUpperCase() ?? "LAIN"}';
    if(type == StockMutationType.opname) actionCCTV = qty > 0 ? AuditAction.opnamePlus : AuditAction.opnameMinus;

    final oldVal = jsonEncode({'stock': sebelum, 'hpp_ma': hppLama, 'code': prod.code, 'name': prod.name});
    final newVal = jsonEncode({
      'stock': sesudah, 'hpp_ma': hppBaru, 'qty': qty, 'hpp_masuk': hargaBeliMasuk,
      'tier': tierHarga, 'harga_jual': hargaJualDipakai, 'customer': customerName,
      'payment': paymentStatus, 'total': totalTransaksi, 'ref': refNo, 'code': prod.code
    });

    final desc = '$actionCCTV ${prod.code} ${prod.name} | Stok $sebelum -> $sesudah (qty $qty) | HPP $hppLama -> $hppBaru | $customerName ${paymentStatus ?? ""} Tier:${tierHarga ?? "-"} Jual:${hargaJualDipakai ?? "-"} | $notes';
    final logId = 'LOG-${DateTime.now().microsecondsSinceEpoch}';

    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: logId,
      userId: userId,
      userRole: Value(userId.contains('owner') ? 'owner' : 'salesman'),
      actionType: actionCCTV,
      tblName: Value('products'),
      referenceId: Value(refNo),
      recordId: Value(productId),
      oldValue: Value(oldVal),
      newValue: Value(newVal),
      description: Value(desc),
    ));

    if(hargaJualDipakai != null && type == StockMutationType.penjualan && hargaJualDipakai < hppLama){
      await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
        id: 'ALT-${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        alertType: 'jual_rugi',
        title: Value('JUAL RUGI ${prod.code}'),
        description: Value('HPP $hppLama dijual $hargaJualDipakai rugi ${hppLama - hargaJualDipakai} ke $customerName tier $tierHarga ref $refNo'),
        detailAnalysis: Value('HPP $hppLama dijual $hargaJualDipakai rugi ${hppLama - hargaJualDipakai} ke $customerName tier $tierHarga ref $refNo'),
        fraudCategory: Value(FraudCategory.jualRugi),
        severity: Value(FraudSeverity.merah),
        auditLogId: Value(logId),
      ));
    }
    if(tierHarga == 3 && (customerName=='Umum' || customerName==null) && type == StockMutationType.penjualan){
      await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
        id: 'ALT-${DateTime.now().microsecondsSinceEpoch + 1}',
        userId: userId,
        alertType: 'tier_salah',
        title: Value('TIER 3 ke UMUM ${prod.code}'),
        description: Value('Tier 3 untuk langganan besar, dijual ke $customerName ref $refNo'),
        detailAnalysis: Value('Tier 3 untuk langganan besar, dijual ke $customerName ref $refNo'),
        fraudCategory: Value(FraudCategory.mainHarga),
        severity: Value(FraudSeverity.kuning),
        auditLogId: Value(logId),
      ));
    }
    if(type == StockMutationType.opname && qty < -5){
      await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
        id: 'ALT-${DateTime.now().microsecondsSinceEpoch + 2}',
        userId: userId,
        alertType: 'opname_janggal',
        title: Value('OPNAME MINUS BESAR ${prod.code}'),
        description: Value('Selisih minus $qty pcs, stok $sebelum -> $sesudah ref $refNo'),
        detailAnalysis: Value('Selisih minus $qty pcs, stok $sebelum -> $sesudah ref $refNo'),
        fraudCategory: Value(FraudCategory.manipulasiTagihan),
        severity: Value(FraudSeverity.merah),
        auditLogId: Value(logId),
      ));
    }
  }

  Future<void> catatMasuk({required String productId, required double qtyMasuk, required double hargaBeliPerPcs, required String refNo, required String userId, String? notes}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.pembelian, qty: qtyMasuk.abs(), hargaBeliMasuk: hargaBeliPerPcs, refNo: refNo, userId: userId, notes: notes));
  Future<void> catatPenjualan({required String productId, required double qty, required String refNo, required String userId, String? customerName, String? paymentStatus, int? tier, double? hargaJual, double? total}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.penjualan, qty: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, customerName: customerName, paymentStatus: paymentStatus, tierHarga: tier, hargaJualDipakai: hargaJual, totalTransaksi: total));
  Future<void> catatItemMasuk({required String productId, required double qty, double? hargaBeli, required String refNo, required String userId, String? notes, String? newRack}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.masuk, qty: qty.abs(), hargaBeliMasuk: hargaBeli??0, refNo: refNo, userId: userId, notes: notes, newRack: newRack));
  Future<void> catatItemKeluar({required String productId, required double qty, required String refNo, required String userId, String? notes}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.keluar, qty: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, notes: notes));
  Future<void> catatOpname({required String productId, required double stokFisik, required String refNo, required String userId, String? notes, String? newRack, DateTime? date}) async {
    final prod = await (select(products)..where((p)=> p.id.equals(productId))).getSingleOrNull(); if(prod==null) return;
    final selisih = stokFisik - prod.stock;
    if(selisih==0 && newRack!=null){ await (update(products)..where((p)=> p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRack))); return; }
    if(selisih==0) return;
    return transaction(()=> _coreMutation(productId: productId, type: StockMutationType.opname, qty: selisih, hargaBeliMasuk: prod.buyPrice, refNo: refNo, userId: userId, notes: notes, newRack: newRack, customDate: date, skipMinus: true));
  }

  Future<void> catatPenjualanDirect({required String productId, required double qty, required String refNo, required String userId, String? customerName, String? paymentStatus, int? tier, double? hargaJual, double? total}) =>
    _coreMutation(productId: productId, type: StockMutationType.penjualan, qty: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId, customerName: customerName, paymentStatus: paymentStatus, tierHarga: tier, hargaJualDipakai: hargaJual, totalTransaksi: total);

  Future<void> catatMasukDirect({required String productId, required double qtyMasuk, required double hargaBeliPerPcs, required String refNo, required String userId, String? notes}) =>
    _coreMutation(productId: productId, type: StockMutationType.pembelian, qty: qtyMasuk.abs(), hargaBeliMasuk: hargaBeliPerPcs, refNo: refNo, userId: userId, notes: notes);

  Future<void> eksekusiPerakitanProduk({required String finishedProductId, required double finishedQtyToProduce, required List<AssemblyMaterialItem> materials, required String userId, String? notes}) async {
    await transaction(() async {
      double totalHppBahan = 0;
      for(final m in materials){
        final raw = await (select(products)..where((p)=> p.id.equals(m.rawProductId))).getSingle();
        final need = m.quantityRequiredPerUnit * finishedQtyToProduce;
        totalHppBahan += raw.buyPrice * need;
        await _coreMutation(productId: m.rawProductId, type: StockMutationType.perakitan, qty: -need, hargaBeliMasuk: 0, refNo: 'RAKIT-BAHAN-$finishedProductId', userId: userId, notes: notes);
      }
      final hppPerJadi = finishedQtyToProduce>0? totalHppBahan / finishedQtyToProduce : 0;
      await _coreMutation(productId: finishedProductId, type: StockMutationType.perakitan, qty: finishedQtyToProduce, hargaBeliMasuk: hppPerJadi.toDouble(), refNo: 'RAKIT-JADI-$finishedProductId', userId: userId, notes: notes);
    });
  }

  Future<void> prosesPerbaikanSaldo(String productId) async {
    final mutasi = await (select(stockMutations)..where((t)=> t.productId.equals(productId))..orderBy([(t)=> OrderingTerm.asc(t.date)])).get();
    double running = 0;
    for(final m in mutasi){ running += m.quantity; await (update(stockMutations)..where((t)=> t.id.equals(m.id))).write(StockMutationsCompanion(currentStockSnapshot: Value(running), stockAfter: Value(running), stockBefore: Value(running - m.quantity))); }
    await (update(products)..where((p)=> p.id.equals(productId))).write(ProductsCompanion(stock: Value(running)));
  }

  Stream<List<StockCardItemData>> watchAllStockMutations({String? mutationTypeFilter, String? keyword}) {
    final k = keyword==null || keyword.isEmpty? null : '%$keyword%';
    var q = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if(mutationTypeFilter!=null && mutationTypeFilter.isNotEmpty) q.where(stockMutations.type.equals(mutationTypeFilter));
    if(k!=null) q.where(products.name.like(k) | (products.code.isNotNull() & products.code.like(k)) | stockMutations.referenceId.like(k) | stockMutations.referenceNo.like(k));
    q.orderBy([OrderingTerm.desc(stockMutations.date)]);
    return q.watch().map((rows)=> rows.map((r)=> StockCardItemData(r.readTable(stockMutations), r.readTable(products))).toList());
  }

  Stream<List<StockCardItemData>> watchKartuStok(String productId) {
    final query = (select(stockMutations)..where((t)=> t.productId.equals(productId))..orderBy([(t)=> OrderingTerm.desc(t.date)])).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    return query.watch().map((rows) => rows.map((r) => StockCardItemData(r.readTable(stockMutations), r.readTable(products))).toList());
  }

  // ==================== TAMBAHAN IPOS LOGIC - TIDAK UBAH METHOD LAMA ====================
  Future<Map<String, dynamic>> stockSummary() async {
    final allProducts = await select(products).get();
    final allMutasi = await select(stockMutations).get();
    final now = DateTime.now();
    final days90 = now.subtract(const Duration(days: 90));

    double totalNilai = 0;
    for(final p in allProducts){ totalNilai += p.stock * p.buyPrice; }

    final countMinus = allProducts.where((e)=> e.stock < 0).length;
    final listMinus = allProducts.where((e)=> e.stock < 0).toList();
    final selisihOpname = allMutasi.where((e)=> e.type == 'opname' && e.quantity.abs() >=1).toList();

    final recentOut = allMutasi.where((m)=> m.date.isAfter(days90) && (m.type == 'penjualan' || m.type == 'keluar')).map((e)=> e.productId).toSet();
    final stokMati90 = allProducts.where((p)=>!recentOut.contains(p.id) && p.stock >0).toList();

    final hppNol = allProducts.where((p)=> p.stock >0 && p.buyPrice ==0).toList();

    return {
      'totalNilaiPersediaan': totalNilai,
      'countStokMinus': countMinus,
      'listStokMinus': listMinus,
      'selisihOpname': selisihOpname,
      'stokMati90Hari': stokMati90,
      'hppNol': hppNol,
    };
  }

  Future<List<String>> getLevel1StockAlerts() async {
    final all = await select(products).get();
    final alerts = <String>[];
    for(final p in all){
      if(p.stock < 0) alerts.add('STOK MINUS: ${p.name} di Gudang = ${p.stock}');
      if(p.stock >0 && p.buyPrice ==0) alerts.add('HPP NOL: ${p.name} laba palsu');
    }
    final adjNoProof = await (select(stockMutations)..where((t)=> t.type.equals('opname'))).get();
    for(final m in adjNoProof.where((e)=> (e.notes==null || e.notes!.isEmpty))){
      alerts.add('PENYESUAIAN TANPA BUKTI: ${m.productId} oleh ${m.userId}');
    }
    return alerts;
  }

  StockAlert checkStockAnomaly(StockMutationData m, ProductData p) {
    if (m.stockAfter < 0) return StockAlert.minus;
    if (m.hppAfter == 0 && m.stockAfter > 0) return StockAlert.hppNol;
    if (m.type == 'opname' && m.quantity.abs() >=3 && m.userId != 'ADMIN_PUSAT' && m.userId != 'owner-01') return StockAlert.adjustmentLiar;
    if (m.stockAfter >0 && p.lastBuyPrice >0 && m.hppAfter > p.lastBuyPrice * 1.5) return StockAlert.hppLonjak;
    return StockAlert.aman;
  }
}