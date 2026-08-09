import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/user_table.dart';
import 'tables/product_table.dart';
import 'tables/stock_mutation_table.dart';
import 'tables/customer_table.dart';
import 'tables/transaction_table.dart';
import 'tables/finance_table.dart';
import 'tables/supplier_table.dart';
import 'tables/category_table.dart';
import 'tables/purchase_table.dart';
import 'tables/audit_log_table.dart';
import 'constant/constant_debt_status.dart';
import 'daos/user_dao.dart';
import 'daos/dashboard_dao.dart';
import 'daos/category_dao.dart';
import 'daos/product_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/supplier_dao.dart';
import 'daos/payables_dao.dart';
import 'daos/receivables_dao.dart';
import 'daos/stock_mutation_dao.dart';
import 'daos/audit_log_dao.dart';

part 'local_database.g.dart';

@DriftDatabase(tables: [
  Users, ShiftKasir, Categories, Products, ProductAssets, ProductUnits,
  ProductVariants, Suppliers, StockMutations, Purchases,
  PurchaseItems, Transactions, TransactionItems, Customers, Payables,
  Receivables, DebtPayments, Expenses, AuditLogs, FraudAlerts,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v21'));

  late final UserDao userDao = UserDao(this);
  late final DashboardDao dashboardDao = DashboardDao(this);
  late final CategoryDao categoryDao = CategoryDao(this);
  late final ProductDao productDao = ProductDao(this);
  late final CustomerDao customerDao = CustomerDao(this);
  late final SupplierDao supplierDao = SupplierDao(this);
  late final PayablesDao payablesDao = PayablesDao(this);
  late final ReceivablesDao receivablesDao = ReceivablesDao(this);
  late final StockMutationDao stockMutationDao = StockMutationDao(this);
  late final AuditLogDao auditLogDao = AuditLogDao(this);

  @override int get schemaVersion => 21;

  @override MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(users).insert(UsersCompanion.insert(
        id: 'owner-01', name: 'Owner Putra Surabaya', role: 'owner',
        username: const Value('owner'), passwordHash: const Value('owner'), pinCode: const Value('123456'),
        status: const Value('aktif'), createdAt: Value(DateTime.now()),
        canOverridePrice: const Value(true), canGiveDiscount: const Value(true), canVoidTransaction: const Value(true),
        canManageStock: const Value(true), canCreateCustomer: const Value(true), canCollectPayment: const Value(true),
        canProcessReturn: const Value(true), maxDiscountPercent: const Value(100), isSynced: const Value(false),
      ));
      await categoryDao.seedDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
       // ... migrasi kamu yang lama tetap ...
       if (from < 13) {
        try { await m.addColumn(products, products.shortName); } catch(_){}
        try { await m.addColumn(products, products.code); } catch(_){}
        // ... lanjutkan semua migrasi kamu yang lama ...
      }
      if (from < 21) {
        try { await m.addColumn(customers, customers.code); } catch(_){}
        // ...
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  Future<void> prosesTransaksiPenyimpanan({required TransactionsCompanion dataTransaksi, required List<TransactionItemsCompanion> itemTransaksi}) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await stockMutationDao.catatPenjualan(productId: item.productId.value, qty: item.quantity.value * item.conversionFactor.value, refNo: dataTransaksi.invoiceNo.value, userId: dataTransaksi.salesId.value ?? 'kasir');
      }
      // ... sisa logic hutang kamu ...
    });
  }

  Future<void> prosesPembelianPenyimpanan({required PurchasesCompanion dataPembelian, required List<PurchaseItemsCompanion> itemPembelian}) async {
    await transaction(() async {
      await into(purchases).insert(dataPembelian);
      for (final item in itemPembelian) {
        await into(purchaseItems).insert(item);
        await stockMutationDao.catatMasuk(productId: item.productId.value, qtyMasuk: item.quantity.value * item.conversionFactor.value, hargaBeliPerPcs: item.buyPrice.value, refNo: dataPembelian.invoiceNo.value, userId: dataPembelian.userId.value);
      }
      // ...
    });
  }
}

// FIX UTAMA: keepAlive + jangan close di dispose
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.keepAlive();
  return db;
});

final allProductsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.productDao.watchActiveProducts();
});

final productsStreamProvider = allProductsStreamProvider;
final activeProductsStreamProvider = allProductsStreamProvider;