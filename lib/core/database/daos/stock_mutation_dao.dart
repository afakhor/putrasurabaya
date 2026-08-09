import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';

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

// Pakai yang dari table biar gak duplikat, tapi kalau mau disini pakai ini:
abstract class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String penjualan = 'PENJUALAN';
  static const String masuk = 'ITEM_MASUK';
  static const String keluar = 'ITEM_KELUAR';
  static const String opname = 'OPNAME';
  static const String perakitan = 'PERAKITAN';
  static const String perbaikan = 'PERBAIKAN_SALDO';
}

@DriftAccessor(tables: [Products, StockMutations, AuditLogs, FraudAlerts])
class StockMutationDao extends DatabaseAccessor<LocalDatabase> with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

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
      hppBaru = sebelum <=0 ? hargaBeliMasuk : ((sebelum*hppLama)+(qty*hargaBeliMasuk))/sesudah;
    }
    await (update(products)..where((p)=> p.id.equals(productId))).write(
      ProductsCompanion(stock: Value(sesudah), buyPrice: Value(hppBaru), rackLocation: newRack!=null? Value(newRack): const Value.absent(), updatedAt: Value(DateTime.now()), isSynced: const Value(false))
    );
    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: 'MUT-${DateTime.now().microsecondsSinceEpoch}', productId: productId, variantId: Value(variantId),
      type: type, quantity: qty, stockBefore: Value(sebelum), stockAfter: Value(sesudah),
      currentStockSnapshot: Value(sesudah), // FIX: sekarang valid
      hppBefore: Value(hppLama), hppAfter: Value(hppBaru), hppSnapshot: Value(hppBaru), 
      buyPriceAtThatTime: Value(hargaBeliMasuk),
      referenceNo: Value(refNo), date: Value(customDate?? DateTime.now()), userId: Value(userId), notes: Value(notes), rackLocation: Value(newRack?? prod.rackLocation),
    ));
  }

  Future<void> catatMasuk({required String productId, required double qtyMasuk, required double hargaBeliPerPcs, required String refNo, required String userId, String? notes}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.pembelian, qty: qtyMasuk.abs(), hargaBeliMasuk: hargaBeliPerPcs, refNo: refNo, userId: userId, notes: notes));

  Future<void> catatPenjualan({required String productId, required double qty, required String refNo, required String userId}) =>
    transaction(()=> _coreMutation(productId: productId, type: StockMutationType.penjualan, qty: -qty.abs(), hargaBeliMasuk: 0, refNo: refNo, userId: userId));

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

  Future<void> prosesPerbaikanSaldo(String productId) async {
    final mutasi = await (select(stockMutations)..where((t)=> t.productId.equals(productId))..orderBy([(t)=> OrderingTerm.asc(t.date)])).get();
    double running = 0;
    for(final m in mutasi){
      running += m.quantity;
      await (update(stockMutations)..where((t)=> t.id.equals(m.id))).write(StockMutationsCompanion(currentStockSnapshot: Value(running), stockAfter: Value(running)));
    }
    await (update(products)..where((p)=> p.id.equals(productId))).write(ProductsCompanion(stock: Value(running)));
  }

  Stream<List<StockCardItemData>> watchAllStockMutations({String? mutationTypeFilter, String? keyword}) {
    var query = select(stockMutations).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    if(mutationTypeFilter!=null) query.where(stockMutations.type.equals(mutationTypeFilter));
    if(keyword!=null && keyword.isNotEmpty) query.where(products.name.like('%$keyword%') | stockMutations.referenceNo.like('%$keyword%'));
    query.orderBy([OrderingTerm.desc(stockMutations.date)]);
    return query.watch().map((rows) => rows.map((r) => StockCardItemData(r.readTable(stockMutations), r.readTable(products))).toList());
  }

  Stream<List<StockCardItemData>> watchKartuStok(String productId) {
    final query = (select(stockMutations)..where((t)=> t.productId.equals(productId))..orderBy([(t)=> OrderingTerm.desc(t.date)])).join([innerJoin(products, products.id.equalsExp(stockMutations.productId))]);
    return query.watch().map((rows) => rows.map((r) => StockCardItemData(r.readTable(stockMutations), r.readTable(products))).toList());
  }

  Stream<List<ProductData>> watchAllProducts() => select(products).watch();
  Stream<List<ProductData>> watchActiveProducts() => (select(products)..where((t)=> t.statusActive.equals('aktif'))).watch();
}