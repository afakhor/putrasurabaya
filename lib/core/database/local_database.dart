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

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(users).insert(UsersCompanion.insert(
        id: 'owner-01',
        name: 'Owner Putra Surabaya',
        role: 'owner',
        username: Value('owner'),
        passwordHash: Value('owner'),
        pinCode: Value('123456'),
        status: Value('aktif'),
        createdAt: Value(DateTime.now()),
        canOverridePrice: Value(true),
        canGiveDiscount: Value(true),
        canVoidTransaction: Value(true),
        canManageStock: Value(true),
        canCreateCustomer: Value(true),
        canCollectPayment: Value(true),
        canProcessReturn: Value(true),
        maxDiscountPercent: Value(100),
        isSynced: Value(false),
      ));
      await categoryDao.seedDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 10) {
        await m.createTable(categories);
        await m.createTable(purchases);
        await m.createTable(purchaseItems);
        await m.createTable(auditLogs);
        await m.createTable(fraudAlerts);
      }
      if (from < 12) {
        try {
          await m.addColumn(categories, categories.code);
          await m.addColumn(categories, categories.slug);
          await m.addColumn(categories, categories.iconName);
          await m.addColumn(categories, categories.colorHex);
          await m.addColumn(categories, categories.imageUrl);
          await m.addColumn(categories, categories.parentId);
          await m.addColumn(categories, categories.level);
          await m.addColumn(categories, categories.sortOrder);
          await m.addColumn(categories, categories.productCount);
          await m.addColumn(categories, categories.usageCount);
          await m.addColumn(categories, categories.isFavorite);
          await m.addColumn(categories, categories.isSystem);
        } catch (_) {}
        final cats = await select(categories).get();
        if (cats.isEmpty) await categoryDao.seedDefaults();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  Future<List<ProductData>> getAllProducts() => select(products).get();

  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        final prod = await (select(products)..where((t) => t.id.equals(item.productId.value))).getSingle();
        await (update(products)..where((t) => t.id.equals(item.productId.value))).write(
          ProductsCompanion(stock: Value(prod.stock - item.quantity.value)),
        );
      }
      if (dataTransaksi.remainingDebt.value > 0 && dataTransaksi.customerId.value!= null) {
        await into(receivables).insert(
          ReceivablesCompanion.insert(
            id: 'RC-${dataTransaksi.id.value}',
            transactionId: dataTransaksi.id.value,
            customerId: dataTransaksi.customerId.value!,
            totalAmount: dataTransaksi.grandTotal.value,
            paidAmount: Value(dataTransaksi.payAmount.value),
            remainingAmount: dataTransaksi.remainingDebt.value,
            dueDate: DateTime.now().add(const Duration(days: 14)),
            status: Value(DebtStatus.tentukanStatus(dataTransaksi.remainingDebt.value, dataTransaksi.payAmount.value)),
          ),
        );
      }
    });
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(() => db.close());
  return db;
});