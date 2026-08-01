import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tabel kamu semua
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

part 'local_database.g.dart';

@DriftDatabase(tables: [
  Users,
  ShiftKasir,
  Categories,
  Products,
  ProductAssets,
  ProductUnits,
  ProductVariants,
  ProductPromos,
  Suppliers,
  StockMutations,
  Purchases,
  PurchaseItems,
  Transactions,
  TransactionItems,
  Customers,
  Payables,
  Receivables,
  DebtPayments,
  Expenses,
  AuditLogs,
  FraudAlerts,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v10'));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stock_mutations_product_date ON stock_mutations (product_id, date);',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 7) {
        await m.createTable(shiftKasir);
        await m.createTable(payables);
        await m.createTable(receivables);
        await m.createTable(debtPayments);
        await m.createTable(expenses);
      }
      if (from < 8) {
        await m.addColumn(users, users.apiKey);
      }
      if (from < 9) {
        await m.addColumn(products, products.rackLocation);
        await m.addColumn(products, products.allowMinusStock);
      }
      if (from < 10) {
        await m.createTable(categories);
        await m.createTable(purchases);
        await m.createTable(purchaseItems);
        await m.createTable(auditLogs);
        await m.createTable(fraudAlerts);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  // HELPER LAMA KAMU - UDAH AKU SESUAIKAN SAMA KOLOM ASLI
  Future<List<ProductData>> getAllProducts() => select(products).get();

  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);

      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        // potong stok
        final prod = await (select(products)..where((t) => t.id.equals(item.productId.value))).getSingle();
        await (update(products)..where((t) => t.id.equals(item.productId.value))).write(
          ProductsCompanion(stock: Value(prod.stock - item.quantity.value)),
        );
      }

      // kalau masih ada sisa hutang, catat piutang
      if (dataTransaksi.remainingDebt.value > 0 && dataTransaksi.customerId.value != null) {
        final receivableId = 'RC-${dataTransaksi.id.value}';
        await into(receivables).insert(
          ReceivablesCompanion.insert(
            id: receivableId,
            transactionId: dataTransaksi.id.value,
            customerId: dataTransaksi.customerId.value!,
            totalAmount: dataTransaksi.grandTotal.value,
            paidAmount: Value(dataTransaksi.payAmount.value),
            remainingAmount: dataTransaksi.remainingDebt.value,
            dueDate: DateTime.now().add(const Duration(days: 14)),
            status: Value(DebtStatus.tentukanStatus(
              dataTransaksi.remainingDebt.value,
              dataTransaksi.payAmount.value,
            )),
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