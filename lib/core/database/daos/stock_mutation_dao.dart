import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';
import 'package:uuid/uuid.dart';

part 'stock_mutation_dao.g.dart';

@DriftAccessor(tables: [Products, StockMutations, AuditLogs, FraudAlerts])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);
  final _uuid = const Uuid();

  // CORE HPP WEIGHTED AVERAGE
  Future<void> _coreMutation({
    required String productId, required String type, required double qty,
    required double hargaBeliMasuk, required String refNo, required String userId,
    String? notes, DateTime? customDate, String? newRack, String? variantId, bool skipMinus=false,
  }) async {
    final prod = await (select(products)..where((p)=> p.id.equals(productId))).getSingleOrNull();
    if(prod==null) throw Exception('Produk tidak ada');
    final sebelum = prod.stock;
    final hppLama = prod.buyPrice;
    final sesudah = sebelum + qty;
    if(!skipMinus &&!prod.allowMinusStock && sesudah < 0) throw Exception('Stok minus ${prod.name} sisa $sebelum');

    double hppBaru = hppLama;
    if(qty>0 && hargaBeliMasuk>0){
      hppBaru = sebelum <=0? hargaBeliMasuk : ((sebelum*hppLama)+(qty*hargaBeliMasuk))/sesudah;
    }

    await (update(products)..where((p)=> p.id.equals(productId))).write(
      ProductsCompanion(stock: Value(sesudah), buyPrice: Value(hppBaru), rackLocation: newRack!=null? Value(newRack): const Value.absent(), updatedAt: Value(DateTime.now()), isSynced: const Value(false))
    );

    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: 'MUT-${DateTime.now().microsecondsSinceEpoch}', productId: productId, variantId: Value(variantId),
      type: type, quantity: qty, stockBefore: Value(sebelum), stockAfter: Value(sesudah),
      hppBefore: Value(hppLama), hppAfter: Value(hppBaru), hppSnapshot: Value(hppBaru), currentStockSnapshot: Value(sesudah),
      referenceNo: Value(refNo), date: customDate?? DateTime.now(), userId: Value(userId), notes: Value(notes), rackLocation: Value(newRack?? prod.rackLocation),
    ));
  }

  Future<void> catatMasuk({required String productId, required double qtyMasuk, required double hargaBeliPerPcs, required String refNo, required String userId, String? notes}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.pembelian, qty: qtyMasuk.abs(), hargaBeliMasuk: hargaBeliPerPcs, refNo: refNo, userId: userId, notes: notes));

  Future<void> catatPenjualan({required String productId, required double qty, required String refNo, required String userId}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.penjualan, qty: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId));

  Future<void> catatOpname({required String productId, required double stokFisik, required String refNo, required String userId, String? notes, String? newRack}) async {
    final prod = await (select(products)..where((p)=> p.id.equals(productId))).getSingleOrNull(); if(prod==null) return;
    final selisih = stokFisik - prod.stock;
    if(selisih==0 && newRack!=null){ await (update(products)..where((p)=> p.id.equals(productId))).write(ProductsCompanion(rackLocation: Value(newRack))); return; }
    if(selisih==0) return;
    return transaction(()=> _coreMutation(productId: productId, type: StockMutationType.opname, qty: selisih, hargaBeliMasuk: prod.buyPrice, refNo: refNo, userId: userId, notes: notes, newRack: newRack, skipMinus: true));
  }

  // WATCH UNTUK PILIH BARANG - ANTI LOADING
  Stream<List<ProductData>> watchAllProducts() => select(products).watch();
  Stream<List<ProductData>> watchActiveProducts() => (select(products)..where((t)=> t.statusActive.equals('aktif'))).watch();
}