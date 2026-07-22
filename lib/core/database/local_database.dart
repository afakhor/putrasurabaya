import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_database.g.dart';

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get status => text()(); 
  BoolColumn get canEditPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shortName => text().withLength(max: 25).nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().withDefault(const Constant('Umum'))();
  TextColumn get subCategory => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get warehouseLocation => text().nullable()();
  TextColumn get tags => text().nullable()();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPriceGeneral => real().withDefault(const Constant(0))();
  RealColumn get sellPriceTier1 => real().withDefault(const Constant(0))();
  RealColumn get sellPriceTier2 => real().withDefault(const Constant(0))();
  RealColumn get sellPriceTier3 => real().withDefault(const Constant(0))();
  RealColumn get maxDiscountSales => real().withDefault(const Constant(0))();
  BoolColumn get isPriceLocked => boolean().withDefault(const Constant(true))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(5))();
  RealColumn get maxStock => real().withDefault(const Constant(100))();
  BoolColumn get allowMinusStock => boolean().withDefault(const Constant(false))();
  RealColumn get weight => real().withDefault(const Constant(0))();
  TextColumn get dimensions => text().nullable()();
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get statusActive => text().withDefault(const Constant('aktif'))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ProductAssetData')
class ProductAssets extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get imagePath => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ProductUnitData')
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)(); 
  TextColumn get unitName => text()();
  IntColumn get conversion => integer()();
  RealColumn get buyPriceUnit => real()(); 
  RealColumn get sellPriceUnit => real()();
  TextColumn get barcode => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ProductVariantData')
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get skuVariant => text()();
  TextColumn get variantName => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ProductPromoData')
class ProductPromos extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get discountNominal => real().withDefault(const Constant(0))();
  TextColumn get promoType => text().withDefault(const Constant('regular'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('SupplierData')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get leadTimeDays => integer().withDefault(const Constant(3))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get hppSnapshot => real()();
  RealColumn get currentStockSnapshot => real()();
  TextColumn get referenceNo => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()();
  RealColumn get subtotal => real()();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get customerId => text().nullable()(); // <-- TAMBAHAN UNTUK PIUTANG
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); 
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text()(); 
  TextColumn get productId => text()(); 
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get totalDebt => real().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerDebtData')
class CustomerDebts extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get customerId => text().references(Customers, #id)();
  RealColumn get amount => real()();
  TextColumn get status => text().withDefault(const Constant('belum_lunas'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  @override Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Users, Products, ProductAssets, ProductUnits, ProductVariants, 
  ProductPromos, Suppliers, StockMutations, Transactions, TransactionItems,
  Customers, CustomerDebts
])
class LocalDatabase extends _$LocalDatabase { 
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v5'));

  @override
  int get schemaVersion => 5; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => await m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 5) {
        await m.createTable(customers);
        await m.createTable(customerDebts);
        await m.addColumn(transactions, transactions.customerId);
      }
    },
  );

  // HPP Moving Average tanpa nested transaction
  Future<void> _mutasiDalamTransaksi({
    required String productId, required String type, required double qty,
    required double hargaMasuk, required String refNo,
  }) async {
    final prod = await (select(products)..where((t) => t.id.equals(productId))).getSingle();
    double stokLama = prod.stock;
    double hppLama = prod.buyPrice;
    double stokBaru = (type == 'masuk' || type == 'retur') ? stokLama + qty : stokLama - qty;
    double hppBaru = hppLama;
    if (type == 'masuk' && (stokLama + qty) > 0) {
      hppBaru = ((stokLama * hppLama) + (qty * hargaMasuk)) / (stokLama + qty);
    }
    await (update(products)..where((t) => t.id.equals(productId))).write(ProductsCompanion(stock: Value(stokBaru), buyPrice: Value(hppBaru)));
    await into(stockMutations).insert(StockMutationsCompanion.insert(
      id: 'MUT-${DateTime.now().millisecondsSinceEpoch}-${productId}',
      productId: productId, variantId: const Value(null), type: type, quantity: qty,
      hppSnapshot: hppBaru, currentStockSnapshot: stokBaru, referenceNo: refNo,
      notes: Value('POS $refNo'), date: Value(DateTime.now()),
    ));
  }

  // DIPAKAI POS - OFFLINE FIRST + PIUTANG
  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await _mutasiDalamTransaksi(
          productId: item.productId.value, type: 'keluar', qty: item.quantity.value,
          hargaMasuk: 0, refNo: dataTransaksi.invoiceNo.value,
        );
      }
      // Jika ada hutang -> catat piutang
      if (dataTransaksi.debt.value > 0 && dataTransaksi.customerId.value != null) {
        final custId = dataTransaksi.customerId.value!;
        await into(customerDebts).insert(CustomerDebtsCompanion.insert(
          id: 'DEBT-${dataTransaksi.id.value}', transactionId: dataTransaksi.id.value,
          customerId: custId, amount: dataTransaksi.debt.value,
          status: const Value('belum_lunas'), dueDate: Value(DateTime.now().add(const Duration(days: 7))),
        ));
      }
    });
  }
  // PUBLIC WRAPPER BIAR DIPANGGIL DARI LUAR - AUTO SYNC HPP + STOK
  Future<List<ProductData>> getAllProducts() => select(products).get();

  Future<void> catatMutasiStok({
    required String productId,
    required String type, // masuk, keluar, opname, retur
    required double qty,
    required double hargaBeliMasuk,
    required String refNo,
    String? variantId,
    String? catatan,
  }) async {
    await transaction(() async {
      // ambil stok & HPP sekarang
      final prod = await (select(products)..where((t) => t.id.equals(productId))).getSingle();
      double stokLama = prod.stock;
      double hppLama = prod.buyPrice;
      
      double stokBaru;
      double hppBaru = hppLama;

      if (type == 'opname') {
        stokBaru = qty; // opname = timpa langsung jumlah fisik
      } else if (type == 'masuk' || type == 'retur') {
        stokBaru = stokLama + qty;
        // RUMUS HPP MOVING AVERAGE - AUTO SYNC
        if (stokLama + qty > 0) {
          hppBaru = ((stokLama * hppLama) + (qty * hargaBeliMasuk)) / (stokLama + qty);
        }
      } else {
        stokBaru = stokLama - qty; // keluar
      }

      // UPDATE 2 arah: Products.stock + Products.buyPrice (HPP) langsung update
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(stock: Value(stokBaru), buyPrice: Value(hppBaru))
      );

      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        variantId: Value(variantId),
        type: type,
        quantity: qty,
        hppSnapshot: hppBaru,
        currentStockSnapshot: stokBaru,
        referenceNo: refNo,
        notes: Value(catatan),
        date: Value(DateTime.now()),
      ));
    });
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());