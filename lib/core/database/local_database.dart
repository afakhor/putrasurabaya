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
import 'daos/supplier_dao.dart';
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

  // 7 DAO TERHUBUNG SEMUA
  late final UserDao userDao = UserDao(this);
  late final DashboardDao dashboardDao = DashboardDao(this);
  late final CategoryDao categoryDao = CategoryDao(this);
  late final ProductDao productDao = ProductDao(this);
  late final CustomerDao customerDao = CustomerDao(this);
  late final SupplierDao supplierDao = SupplierDao(this);
  late final StockMutationDao stockMutationDao = StockMutationDao(this);

  @override
  int get schemaVersion => 14; // FINAL UPGRADE 14

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
      }
      if (from < 13) {
        try {
          await m.addColumn(products, products.shortName);
          await m.addColumn(products, products.barcode);
          await m.addColumn(products, products.description);
          await m.addColumn(products, products.subCategory);
          await m.addColumn(products, products.brand);
          await m.addColumn(products, products.warehouseLocation);
          await m.addColumn(products, products.tags);
          await m.addColumn(products, products.sellPriceGeneral);
          await m.addColumn(products, products.sellPriceTier1);
          await m.addColumn(products, products.sellPriceTier2);
          await m.addColumn(products, products.sellPriceTier3);
          await m.addColumn(products, products.maxDiscountSales);
          await m.addColumn(products, products.isPriceLocked);
          await m.addColumn(products, products.minStock);
          await m.addColumn(products, products.maxStock);
          await m.addColumn(products, products.allowMinusStock);
          await m.addColumn(products, products.unit);
          await m.addColumn(products, products.rackLocation);
          await m.addColumn(products, products.isSynced);
        } catch (_) {}
        final cats = await select(categories).get();
        if (cats.isEmpty) await categoryDao.seedDefaults();
      }
      if (from < 14) {
        // SINKRONISASI STOCK MUTATION DAO EMAS - stockBefore / stockAfter
        try {
          await m.addColumn(stockMutations, stockMutations.stockBefore);
          await m.addColumn(stockMutations, stockMutations.stockAfter);
          await m.addColumn(stockMutations, stockMutations.variantId);
          await m.addColumn(stockMutations, stockMutations.userId);
          await m.addColumn(stockMutations, stockMutations.notes);
        } catch (_) {}
        // pastikan 24 kategori tetap ada setelah upgrade
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
        final newStock = prod.stock - item.quantity.value;
        final beforeStock = prod.stock;
        await (update(products)..where((t) => t.id.equals(item.productId.value))).write(
          ProductsCompanion(stock: Value(newStock)),
        );
        await stockMutationDao.addMutation(
          productId: prod.id,
          type: StockMutationType.penjualan,
          quantity: -item.quantity.value,
          stockAfter: newStock,
          hpp: prod.buyPrice,
          refNo: dataTransaksi.id.value,
          notes: 'Penjualan POS - before: $beforeStock',
        );
      }
      if (dataTransaksi.remainingDebt.value > 0 && dataTransaksi.customerId.value != null) {
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
        final cust = await (select(customers)..where((t)=> t.id.equals(dataTransaksi.customerId.value!))).getSingleOrNull();
        if(cust!=null){
          await (update(customers)..where((t)=> t.id.equals(cust.id))).write(
            CustomersCompanion(totalDebt: Value(cust.totalDebt + dataTransaksi.remainingDebt.value))
          );
        }
      }
    });
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(() => db.close());
  return db;
});