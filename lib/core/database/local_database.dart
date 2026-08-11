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
import 'daos/transaction_dao.dart';
import 'daos/report_dao.dart';
import 'daos/shift_dao.dart';

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
  late final TransactionDao transactionDao = TransactionDao(this);
  late final ReportDao reportDao = ReportDao(this);
  late final ShiftDao shiftDao = ShiftDao(this);

  AuditLogDao get fraudAlertDao => auditLogDao;
  ReportDao get reportDaoAlias => reportDao;

  @override int get schemaVersion => 26; // NAIK DARI 25 KE 26

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(users).insert(UsersCompanion.insert(
        id: 'owner-01', name: 'Owner Putra Surabaya', role: 'owner',
        username: const Value('owner'), passwordHash: const Value('owner'), pinCode: const Value('123456'),
        status: const Value('aktif'), createdAt: Value(DateTime.now()),
        canOverridePrice: const Value(true), canGiveDiscount: const Value(true), canVoidTransaction: const Value(true),
        canManageStock: const Value(true), canCreateCustomer: const Value(true), canCollectPayment: const Value(true),
        canProcessReturn: const Value(true), maxDiscountPercent: const Value(100), isSynced: const Value(false),
        canDeleteTransaction: const Value(true), canEditHpp: const Value(true), canViewProfit: const Value(true), canViewDashboardBos: const Value(true),
      ));
      await categoryDao.seedDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 10) { try { await m.createTable(auditLogs); } catch(_){} try { await m.createTable(fraudAlerts); } catch(_){} }
      if (from < 13) { try { await m.addColumn(products, products.sellPriceTier1); } catch(_){} try { await m.addColumn(products, products.sellPriceTier2); } catch(_){} try { await m.addColumn(products, products.sellPriceTier3); } catch(_){} try { await m.addColumn(products, products.sellPriceGeneral); } catch(_){} }
      if (from < 15) { try { await m.addColumn(stockMutations, stockMutations.hppSnapshot); } catch(_){} }
      if (from < 20) { try { await m.addColumn(stockMutations, stockMutations.hppBefore); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.hppAfter); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.buyPriceAtThatTime); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.currentStockSnapshot); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.stockBefore); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.stockAfter); } catch(_){} try { await m.addColumn(stockMutations, stockMutations.referenceNo); } catch(_){} }
      if (from < 21) { try { await m.addColumn(customers, customers.tierHarga); } catch(_){} try { await m.addColumn(customers, customers.sisaHutang); } catch(_){} }
      if (from < 24) { try { await m.addColumn(products, products.lastBuyPrice); } catch(_){} }
      if (from < 25) {
        try { await m.addColumn(payables, payables.purchaseId); } catch(_){}
        try { await m.addColumn(payables, payables.supplierId); } catch(_){}
        try { await m.addColumn(payables, payables.totalAmount); } catch(_){}
        try { await m.addColumn(payables, payables.paidAmount); } catch(_){}
        try { await m.addColumn(payables, payables.remainingAmount); } catch(_){}
        try { await m.addColumn(receivables, receivables.transactionId); } catch(_){}
        try { await m.addColumn(receivables, receivables.customerId); } catch(_){}
        try { await m.addColumn(receivables, receivables.totalAmount); } catch(_){}
        try { await m.addColumn(receivables, receivables.paidAmount); } catch(_){}
        try { await m.addColumn(receivables, receivables.remainingAmount); } catch(_){}
        try { await m.addColumn(debtPayments, debtPayments.refId); } catch(_){}
        try { await m.addColumn(debtPayments, debtPayments.type); } catch(_){}
        try { await m.addColumn(debtPayments, debtPayments.paymentDate); } catch(_){}
        try { await m.addColumn(debtPayments, debtPayments.paymentMethod); } catch(_){}
      }
      // === PATCH v26 - RECEIVABLES.md TAMBAHAN BARU ===
      if (from < 26) {
        try { await m.addColumn(receivables, receivables.invoiceNo); } catch(_){}
        try { await m.addColumn(receivables, receivables.salesmanId); } catch(_){}
        try { await m.addColumn(receivables, receivables.customerIdRef); } catch(_){}
        try { await m.addColumn(receivables, receivables.kenapaNgendap); } catch(_){}
        try { await m.addColumn(receivables, receivables.umurNgendap); } catch(_){}
        try { await m.addColumn(receivables, receivables.statusNgendapWarna); } catch(_){}
        try { await m.addColumn(receivables, receivables.invoiceDate); } catch(_){}
        try { await m.addColumn(receivables, receivables.customerName); } catch(_){}
        try { await m.addColumn(receivables, receivables.salesId); } catch(_){}
        try { await m.addColumn(receivables, receivables.amount); } catch(_){}
        try { await m.addColumn(receivables, receivables.remaining); } catch(_){}
        try { await m.addColumn(customers, customers.blacklistReason); } catch(_){}
        try { await m.addColumn(customers, customers.blacklistBy); } catch(_){}
        try { await m.addColumn(customers, customers.blacklistAt); } catch(_){}
        try { await m.addColumn(customers, customers.kartuDosa); } catch(_){}
        try { await m.addColumn(auditLogs, auditLogs.ipAddress); } catch(_){}
        try { await m.addColumn(auditLogs, auditLogs.deviceId); } catch(_){}
        try { await m.addColumn(fraudAlerts, fraudAlerts.referenceId); } catch(_){}
        try { await m.addColumn(fraudAlerts, fraudAlerts.lossAmount); } catch(_){}
        try { await m.addColumn(users, users.waNumber); } catch(_){}
        try { await m.addColumn(users, users.canDeleteTransaction); } catch(_){}
        try { await m.addColumn(users, users.canEditHpp); } catch(_){}
        try { await m.addColumn(users, users.canViewProfit); } catch(_){}
        try { await m.addColumn(users, users.canViewDashboardBos); } catch(_){}
        try { await m.addColumn(expenses, expenses.notes); } catch(_){}
        try { await m.addColumn(expenses, expenses.userId); } catch(_){}
        try { await m.addColumn(payables, payables.supplierName); } catch(_){}
        try { await m.addColumn(payables, payables.amount); } catch(_){}
        try { await m.addColumn(payables, payables.remaining); } catch(_){}
      }
    },
    beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); },
  );

  Future<void> prosesTransaksiPenyimpanan({required TransactionsCompanion dataTransaksi, required List<TransactionItemsCompanion> itemTransaksi}) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);
      String custName = 'Umum';
      String? custId = dataTransaksi.customerId.value;
      if(custId != null){
        final c = await (select(customers)..where((t)=> t.id.equals(custId))).getSingleOrNull();
        if(c != null) custName = c.name;
      }
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await stockMutationDao.catatPenjualanDirect(
          productId: item.productId.value,
          qty: item.quantity.value * item.conversionFactor.value,
          refNo: dataTransaksi.invoiceNo.value,
          userId: dataTransaksi.salesId.value?? 'kasir-01',
          customerName: custName,
          paymentStatus: dataTransaksi.status.value.toUpperCase(),
          tier: item.selectedTier.value,
          hargaJual: item.appliedTierPrice.value,
          total: item.subtotal.value
        );
      }
      if (dataTransaksi.remainingDebt.value > 0 && custId != null) {
        final now = DateTime.now();
        await into(receivables).insert(ReceivablesCompanion.insert(
          id: 'RC-${dataTransaksi.id.value}',
          transactionId: Value(dataTransaksi.id.value),
          invoiceNo: Value(dataTransaksi.invoiceNo.value),
          customerId: Value(custId),
          customerIdRef: Value(custId),
          customerName: Value(custName),
          salesId: Value(dataTransaksi.salesId.value),
          salesmanId: Value(dataTransaksi.salesId.value),
          totalAmount: Value(dataTransaksi.grandTotal.value),
          amount: Value(dataTransaksi.grandTotal.value),
          paidAmount: Value(dataTransaksi.payAmount.value),
          remainingAmount: Value(dataTransaksi.remainingDebt.value),
          remaining: Value(dataTransaksi.remainingDebt.value),
          dueDate: Value(dataTransaksi.dueDate.value ?? DateTime.now().add(const Duration(days: 14))),
          invoiceDate: Value(now),
          status: const Value('belum_lunas'),
          kenapaNgendap: Value(custName == 'Umum' ? 'MACET' : 'TEMPO'),
          umurNgendap: const Value(0),
          statusNgendapWarna: const Value('HIJAU'),
        ));
        final cust = await (select(customers)..where((t)=> t.id.equals(custId))).getSingleOrNull();
        if(cust!=null){
          await (update(customers)..where((t)=> t.id.equals(cust.id))).write(
            CustomersCompanion(sisaHutang: Value(cust.sisaHutang + dataTransaksi.remainingDebt.value), updatedAt: Value(DateTime.now()))
          );
        }
      }
    });
  }

  Future<void> prosesPembelianPenyimpanan({required PurchasesCompanion dataPembelian, required List<PurchaseItemsCompanion> itemPembelian}) async {
    await transaction(() async {
      await into(purchases).insert(dataPembelian);
      for (final item in itemPembelian) {
        await into(purchaseItems).insert(item);
        await stockMutationDao.catatMasukDirect(
          productId: item.productId.value,
          qtyMasuk: item.quantity.value * item.conversionFactor.value,
          hargaBeliPerPcs: item.buyPrice.value,
          refNo: dataPembelian.invoiceNo.value,
          userId: dataPembelian.userId.value
        );
      }
      if (dataPembelian.debtAmount.value > 0) {
        final sup = await (select(suppliers)..where((t)=> t.id.equals(dataPembelian.supplierId.value))).getSingleOrNull();
        await into(payables).insert(PayablesCompanion.insert(
          id: 'PY-${dataPembelian.id.value}',
          purchaseId: Value(dataPembelian.id.value),
          supplierId: Value(dataPembelian.supplierId.value),
          supplierName: Value(sup?.name),
          totalAmount: Value(dataPembelian.totalAmount.value),
          amount: Value(dataPembelian.totalAmount.value),
          paidAmount: Value(dataPembelian.paidAmount.value),
          remainingAmount: Value(dataPembelian.debtAmount.value),
          remaining: Value(dataPembelian.debtAmount.value),
          dueDate: Value(dataPembelian.dueDate.value?? DateTime.now().add(const Duration(days: 30))),
          status: const Value('belum_lunas')
        ));
      }
    });
  }

  Future<void> onPayablePaid({required String invoiceNo, required double amount, required String userId}) async {
    var payable = await (select(payables)..where((t)=> t.purchaseId.equals(invoiceNo))).getSingleOrNull();
    payable ??= await (select(payables)..where((t)=> t.id.equals(invoiceNo))).getSingleOrNull();
    if(payable==null) throw Exception('Payable $invoiceNo tidak ditemukan');
    await payablesDao.bayarAngsuranHutang(payableId: payable.id, nominalBayar: amount, paymentMethod: 'CASH', notes: 'Bayar via Invoice $invoiceNo by $userId');
  }

  Future<void> onPurchaseCreatedFull({required PurchasesCompanion dataPembelian, required List<PurchaseItemsCompanion> items, bool isBarangDiterima = true}) async {
    if(!isBarangDiterima){
      await transaction(() async {
        await into(purchases).insert(dataPembelian.copyWith(status: const Value('in_transit')));
        if (dataPembelian.debtAmount.value > 0) {
          final sup = await (select(suppliers)..where((t)=> t.id.equals(dataPembelian.supplierId.value))).getSingleOrNull();
          await into(payables).insert(PayablesCompanion.insert(
            id: 'PY-${dataPembelian.id.value}',
            purchaseId: Value(dataPembelian.id.value),
            supplierId: Value(dataPembelian.supplierId.value),
            supplierName: Value(sup?.name),
            totalAmount: Value(dataPembelian.totalAmount.value),
            amount: Value(dataPembelian.totalAmount.value),
            paidAmount: Value(dataPembelian.paidAmount.value),
            remainingAmount: Value(dataPembelian.debtAmount.value),
            remaining: Value(dataPembelian.debtAmount.value),
            dueDate: Value(dataPembelian.dueDate.value?? DateTime.now().add(const Duration(days: 30))),
            status: const Value('belum_lunas')
          ));
        }
      });
    } else {
      await prosesPembelianPenyimpanan(dataPembelian: dataPembelian, itemPembelian: items);
    }
  }
}

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