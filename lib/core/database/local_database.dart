import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/user_table.dart';
import 'tables/product_table.dart';
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
import 'daos/stock_mutation_dao.dart';

part 'local_database.g.dart';

@DriftDatabase(tables: [
  Users, ShiftKasir, Categories, Products, ProductAssets, ProductUnits,
  ProductVariants, ProductPromos, Suppliers, StockMutations, Purchases,
  PurchaseItems, Transactions, TransactionItems, Customers, Payables,
  Receivables, DebtPayments, Expenses, AuditLogs, FraudAlerts,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v10'));
  late final UserDao userDao = UserDao(this);
  late final DashboardDao dashboardDao = DashboardDao(this);
  late final CategoryDao categoryDao = CategoryDao(this);
  late final ProductDao productDao = ProductDao(this);
  late final CustomerDao customerDao = CustomerDao(this);
  late final StockMutationDao stockMutationDao = StockMutationDao(this);

  @override int get schemaVersion => 13;

  @override MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(users).insert(UsersCompanion.insert(
        id: 'owner-01', name: 'Owner Putra Surabaya', role: 'owner',
        username: Value('owner'), passwordHash: Value('owner'), pinCode: Value('123456'),
        status: Value('aktif'), createdAt: Value(DateTime.now()),
        canOverridePrice: Value(true), canGiveDiscount: Value(true), canVoidTransaction: Value(true),
        canManageStock: Value(true), canCreateCustomer: Value(true), canCollectPayment: Value(true),
        canProcessReturn: Value(true), maxDiscountPercent: Value(100), isSynced: Value(false),
      ));
      await categoryDao.seedDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if(from<10){ await m.createTable(categories); await m.createTable(purchases); await m.createTable(purchaseItems); await m.createTable(auditLogs); await m.createTable(fraudAlerts); }
      if(from<13){
        try{
          await m.addColumn(categories, categories.code); await m.addColumn(categories, categories.slug);
          await m.addColumn(categories, categories.iconName); await m.addColumn(categories, categories.colorHex);
          await m.addColumn(categories, categories.imageUrl); await m.addColumn(categories, categories.parentId);
          await m.addColumn(categories, categories.level); await m.addColumn(categories, categories.sortOrder);
          await m.addColumn(categories, categories.productCount); await m.addColumn(categories, categories.usageCount);
          await m.addColumn(categories, categories.isFavorite); await m.addColumn(categories, categories.isSystem);
          await m.addColumn(products, products.shortName); await m.addColumn(products, products.barcode);
          await m.addColumn(products, products.description); await m.addColumn(products, products.subCategory);
          await m.addColumn(products, products.brand); await m.addColumn(products, products.warehouseLocation);
          await m.addColumn(products, products.tags); await m.addColumn(products, products.sellPriceGeneral);
        }catch(_){}
        final cats = await select(categories).get(); if(cats.isEmpty) await categoryDao.seedDefaults();
      }
    },
    beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); },
  );
}

final localDatabaseProvider = Provider<LocalDatabase>((ref){
  final db = LocalDatabase(); ref.onDispose(()=> db.close()); return db;
});