import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TABLES
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

// DAOS
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

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
      // MIGRASI LAMA KAMU TETAP
      if (from < 10) {
        try { await m.createTable(auditLogs); } catch(_){}
        try { await m.createTable(fraudAlerts); } catch(_){}
      }
      if (from < 12) {
        try { await m.addColumn(categories, categories.code); } catch(_){}
        try { await m.addColumn(categories, categories.slug); } catch(_){}
        try { await m.addColumn(categories, categories.iconName); } catch(_){}
        try { await m.addColumn(categories, categories.colorHex); } catch(_){}
        try { await m.addColumn(categories, categories.imageUrl); } catch(_){}
        try { await m.addColumn(categories, categories.parentId); } catch(_){}
        try { await m.addColumn(categories, categories.level); } catch(_){}
        try { await m.addColumn(categories, categories.sortOrder); } catch(_){}
        try { await m.addColumn(categories, categories.productCount); } catch(_){}
        try { await m.addColumn(categories, categories.usageCount); } catch(_){}
        try { await m.addColumn(categories, categories.isFavorite); } catch(_){}
        try { await m.addColumn(categories, categories.isSystem); } catch(_){}
      }
      if (from < 13) {
        try { await m.addColumn(products, products.shortName); } catch(_){}
        try { await m.addColumn(products, products.barcode); } catch(_){}
        try { await m.addColumn(products, products.description); } catch(_){}
        try { await m.addColumn(products, products.subCategory); } catch(_){}
        try { await m.addColumn(products, products.brand); } catch(_){}
        try { await m.addColumn(products, products.warehouseLocation); } catch(_){}
        try { await m.addColumn(products, products.tags); } catch(_){}
        try { await m.addColumn(products, products.sellPriceGeneral); } catch(_){}
        try { await m.addColumn(products, products.sellPriceTier1); } catch(_){}
        try { await m.addColumn(products, products.sellPriceTier2); } catch(_){}
        try { await m.addColumn(products, products.sellPriceTier3); } catch(_){}
        try { await m.addColumn(products, products.maxDiscountSales); } catch(_){}
        try { await m.addColumn(products, products.isPriceLocked); } catch(_){}
        try { await m.addColumn(products, products.minStock); } catch(_){}
        try { await m.addColumn(products, products.maxStock); } catch(_){}
        try { await m.addColumn(products, products.allowMinusStock); } catch(_){}
        try { await m.addColumn(products, products.unit); } catch(_){}
        try { await m.addColumn(products, products.rackLocation); } catch(_){}
        try { await m.addColumn(products, products.isSynced); } catch(_){}
      }
      if (from < 15) {
        try { await m.addColumn(stockMutations, stockMutations.hppSnapshot); } catch(_){}
        try { await m.addColumn(stockMutations, stockMutations.rackLocation); } catch(_){}
      }
      if (from < 17) {
        try { await m.addColumn(auditLogs, auditLogs.isSynced); } catch(_){}
        try { await m.addColumn(fraudAlerts, fraudAlerts.isSynced); } catch(_){}
      }
      // MIGRASI BARU v18-v21 - HPP AUTO + SUPPLIER CUSTOMER LENGKAP
      if (from < 20) {
        try { await m.addColumn(stockMutations, stockMutations.hppBefore); } catch(_){}
        try { await m.addColumn(stockMutations, stockMutations.hppAfter); } catch(_){}
        try { await m.addColumn(stockMutations, stockMutations.buyPriceAtThatTime); } catch(_){}
        try { await m.addColumn(stockMutations, stockMutations.currentStockSnapshot); } catch(_){}
        
        // SUPPLIER LENGKAP
        try { await m.addColumn(suppliers, suppliers.code); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.wa); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.kelurahan); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.kota); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.picName); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.category); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.type); } catch(_){}
        try { await m.addColumn(suppliers, suppliers.paymentTerm); } catch(_){}
      }
      if (from < 21) {
        // CUSTOMER LENGKAP
        try { await m.addColumn(customers, customers.code); } catch(_){}
        try { await m.addColumn(customers, customers.wa); } catch(_){}
        try { await m.addColumn(customers, customers.kelurahan); } catch(_){}
        try { await m.addColumn(customers, customers.kota); } catch(_){}
        try { await m.addColumn(customers, customers.kelas); } catch(_){}
        try { await m.addColumn(customers, customers.paymentType); } catch(_){}
        try { await m.addColumn(customers, customers.tierHarga); } catch(_){}
        try { await m.addColumn(customers, customers.plafonHutang); } catch(_){}
        try { await m.addColumn(customers, customers.sisaHutang); } catch(_){}
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  // ORCHESTRATOR 1 PINTU - POS
  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await stockMutationDao.catatPenjualan(
          productId: item.productId.value,
          qty: item.quantity.value * item.conversionFactor.value,
          refNo: dataTransaksi.invoiceNo.value,
          userId: dataTransaksi.salesId.value ?? 'kasir',
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
            CustomersCompanion(sisaHutang: Value(cust.sisaHutang + dataTransaksi.remainingDebt.value), updatedAt: Value(DateTime.now()))
          );
        }
      }
    });
  }

  // ORCHESTRATOR PEMBELIAN - HPP AUTO WEIGHTED
  Future<void> prosesPembelianPenyimpanan({
    required PurchasesCompanion dataPembelian,
    required List<PurchaseItemsCompanion> itemPembelian,
  }) async {
    await transaction(() async {
      await into(purchases).insert(dataPembelian);
      for (final item in itemPembelian) {
        await into(purchaseItems).insert(item);
        await stockMutationDao.catatMasuk(
          productId: item.productId.value,
          qtyMasuk: item.quantity.value * item.conversionFactor.value,
          hargaBeliPerPcs: item.buyPrice.value,
          refNo: dataPembelian.invoiceNo.value,
          userId: dataPembelian.userId.value,
        );
      }
      if (dataPembelian.debtAmount.value > 0) {
        await into(payables).insert(PayablesCompanion.insert(
          id: 'PY-${dataPembelian.id.value}',
          purchaseId: dataPembelian.id.value,
          supplierId: dataPembelian.supplierId.value,
          totalAmount: dataPembelian.totalAmount.value,
          paidAmount: Value(dataPembelian.paidAmount.value),
          remainingAmount: dataPembelian.debtAmount.value,
          dueDate: dataPembelian.dueDate.value ?? DateTime.now().add(const Duration(days: 30)),
          status: Value(DebtStatus.tentukanStatus(dataPembelian.debtAmount.value, dataPembelian.paidAmount.value)),
        ));
      }
    });
  }
}

// PROVIDER GLOBAL - CUMA 1, ANTI LOADING MUTER
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// STREAM GLOBAL UNTUK PILIH BARANG - INI YANG FIX LOADING DI SCREENSHOT KAMU
final allProductsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.productDao.watchActiveProducts();
});
final productsStreamProvider = allProductsStreamProvider;