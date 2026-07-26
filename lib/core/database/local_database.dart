import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import DAOs
import 'daos/dashboard_dao.dart';
import 'daos/payables_dao.dart';
import 'daos/receivables_dao.dart';

// Import Tables
import 'tables/finance_table.dart';

part 'local_database.g.dart';

// ==========================================
// 1. TABEL PENGGUNA & POS KASIR
// ==========================================

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()(); // owner, admin, salesman, kasir
  TextColumn get status => text().withDefault(const Constant('aktif'))(); 
  BoolColumn get canEditPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ShiftKasirData')
class ShiftKasir extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get initialCash => real().withDefault(const Constant(0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0))();
  RealColumn get actualCash => real().nullable()();
  RealColumn get cashDifference => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))(); // open / closed
  @override Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. TABEL INVENTORY & PRODUK
// ==========================================

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

// ==========================================
// 3. TABEL PELANGGAN & TRANSAKSI
// ==========================================

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get totalDebt => real().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()();
  TextColumn get salesId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get discountTotal => real().withDefault(const Constant(0))();
  RealColumn get taxTotal => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); 
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text().references(Transactions, #id)(); 
  TextColumn get productId => text().references(Products, #id)(); 
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  RealColumn get buyPriceAtTransaction => real().withDefault(const Constant(0))(); // SNAPSHOT HPP
  TextColumn get unit => text()();
  @override Set<Column> get primaryKey => {id};
}

// ==========================================
// 4. KONFIGURASI DATABASE UTAMA & MIGRATION
// ==========================================

@DriftDatabase(
  tables: [
    Users, ShiftKasir, Products, ProductAssets, ProductUnits, ProductVariants, 
    ProductPromos, Suppliers, StockMutations, Transactions, TransactionItems,
    Customers,
    // TABEL KEUANGAN & HUTANG PIUTANG
    Payables, Receivables, DebtPayments, Expenses
  ],
  daos: [
    DashboardDao, ReceivablesDao, PayablesDao
  ],
)
class LocalDatabase extends _$LocalDatabase { 
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v7'));

  @override
  int get schemaVersion => 7; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => await m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 7) {
        await m.createTable(shiftKasir);
        await m.createTable(payables);
        await m.createTable(receivables);
        await m.createTable(debtPayments);
        await m.createTable(expenses);
      }
    },
  );

  // ===========================================================================
  // HELPER METODE MUTASI HPP & TRANSAKSI POS
  // ===========================================================================

  // HPP Moving Average Internal Helper
  Future<void> _mutasiDalamTransaksi({
    required String productId, 
    required String type, 
    required double qty,
    required double hargaMasuk, 
    required String refNo,
  }) async {
    final prod = await (select(products)..where((t) => t.id.equals(productId))).getSingle();
    double stokLama = prod.stock;
    double hppLama = prod.buyPrice;
    double stokBaru = (type == 'masuk' || type == 'retur') ? stokLama + qty : stokLama - qty;
    double hppBaru = hppLama;

    if (type == 'masuk' && (stokLama + qty) > 0) {
      hppBaru = ((stokLama * hppLama) + (qty * hargaMasuk)) / (stokLama + qty);
    }

    await (update(products)..where((t) => t.id.equals(productId))).write(
      ProductsCompanion(stock: Value(stokBaru), buyPrice: Value(hppBaru)),
    );

    await into(stockMutations).insert(
      StockMutationsCompanion.insert(
        id: 'MUT-${DateTime.now().millisecondsSinceEpoch}-$productId',
        productId: productId, 
        variantId: const Value(null), 
        type: type, 
        quantity: qty,
        hppSnapshot: hppBaru, 
        currentStockSnapshot: stokBaru, 
        referenceNo: refNo,
        notes: Value('POS $refNo'), 
        date: Value(DateTime.now()),
      ),
    );
  }

  /// Alur Transaksi Kasir POS (Atomic Transaction)
  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      // 1. Simpan Header Transaksi
      await into(transactions).insert(dataTransaksi);

      // 2. Simpan Rincian Item Transaksi & Potong Stok
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await _mutasiDalamTransaksi(
          productId: item.productId.value, 
          type: 'keluar', 
          qty: item.quantity.value,
          hargaMasuk: 0, 
          refNo: dataTransaksi.invoiceNo.value,
        );
      }

      // 3. Sinkronisasi Piutang ke Receivables & Update Total Debt Customer
      if (dataTransaksi.debt.value > 0 && dataTransaksi.customerId.value != null) {
        final totalHarga = dataTransaksi.total.value;
        final dp = dataTransaksi.paid.value;
        final sisaPiutang = dataTransaksi.debt.value;
        final custId = dataTransaksi.customerId.value!;
        final receivableId = 'RC-${dataTransaksi.id.value}';

        // 3a. Masukkan Data Piutang Baru
        await into(receivables).insert(
          ReceivablesCompanion.insert(
            id: receivableId,
            transactionId: dataTransaksi.id.value,
            customerId: custId,
            totalAmount: totalHarga,
            paidAmount: Value(dp),
            remainingAmount: sisaPiutang,
            dueDate: DateTime.now().add(const Duration(days: 14)),
            status: Value(dp > 0 ? 'partial' : 'unpaid'),
          ),
        );

        // 3b. Tambahkan Total Piutang Pelanggan di Tabel Customers
        final customer = await (select(customers)..where((t) => t.id.equals(custId))).getSingleOrNull();
        if (customer != null) {
          final newTotalDebt = customer.totalDebt + sisaPiutang;
          await (update(customers)..where((t) => t.id.equals(custId))).write(
            CustomersCompanion(totalDebt: Value(newTotalDebt)),
          );
        }

        // 3c. Jika ada DP saat transaksi tempo, catat ke DebtPayments
        if (dp > 0) {
          await into(debtPayments).insert(
            DebtPaymentsCompanion.insert(
              id: 'PAY-AR-${DateTime.now().millisecondsSinceEpoch}',
              refId: receivableId,
              type: 'receivable_collect',
              amount: dp,
              paymentMethod: dataTransaksi.paymentMethod.value,
              notes: const Value('Uang Muka / DP Penjualan Tempo Kasir'),
            ),
          );
        }
      }
    });
  }

  Future<List<ProductData>> getAllProducts() => select(products).get();

  /// Pencatatan Mutasi Stok & Penyesuaian HPP Manual
  Future<void> catatMutasiStok({
    required String productId,
    required String type, 
    required double qty,
    required double hargaBeliMasuk,
    required String refNo,
    String? variantId,
    String? catatan,
  }) async {
    await transaction(() async {
      final prod = await (select(products)..where((t) => t.id.equals(productId))).getSingle();
      double stokLama = prod.stock;
      double hppLama = prod.buyPrice;

      double stokBaru;
      double hppBaru = hppLama;

      if (type == 'opname') {
        stokBaru = qty; 
      } else if (type == 'masuk' || type == 'retur') {
        stokBaru = stokLama + qty;
        if (stokLama + qty > 0) {
          hppBaru = ((stokLama * hppLama) + (qty * hargaBeliMasuk)) / (stokLama + qty);
        }
      } else {
        stokBaru = stokLama - qty; 
      }

      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(stock: Value(stokBaru), buyPrice: Value(hppBaru)),
      );

      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
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
        ),
      );
    });
  }
}

// Provider Global Riverpod
final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());
