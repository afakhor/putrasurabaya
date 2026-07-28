local_database sebelum diperbaiki META.AI
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Tabel
import 'package:ud_putra_kasir/core/database/tables/user_table.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';
import 'package:ud_putra_kasir/core/database/tables/transaction_table.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';

// Import DAOs
import 'package:ud_putra_kasir/core/database/daos/dashboard_dao.dart';
import 'package:ud_putra_kasir/core/database/daos/product_dao.dart';
import 'package:ud_putra_kasir/core/database/daos/receivables_dao.dart';
import 'package:ud_putra_kasir/core/database/daos/transaction_dao.dart';
import 'package:ud_putra_kasir/core/database/daos/payables_dao.dart';

// Import Constant
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'local_database.g.dart';

@DriftDatabase(
  tables: [
    Users, 
    ShiftKasir, 
    Products, 
    ProductAssets, 
    ProductUnits, 
    ProductVariants, 
    ProductPromos, 
    Suppliers, 
    StockMutations, 
    Transactions, 
    TransactionItems,
    Customers,
    Payables, 
    Receivables, 
    DebtPayments, 
    Expenses,
  ],
  daos: [
    DashboardDao, 
    ProductDao, 
    ReceivablesDao, 
    PayablesDao, 
    TransactionDao,
  ],
)
class LocalDatabase extends _$LocalDatabase { 
  LocalDatabase() : super(driftDatabase(name: 'putra_sby_db_v8'));

  @override
  int get schemaVersion => 8;

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
      if (from < 8) {
        // Migrasi aman: Menambahkan kolom apiKey tanpa menghapus data user
        await m.addColumn(users, users.apiKey);
      }
    },
  );

  // ===========================================================================
  // HELPER METODE MUTASI HPP & TRANSAKSI POS
  // ===========================================================================

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

  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      await into(transactions).insert(dataTransaksi);

      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);
        await _mutasiDalamTransaksi(
          productId: item.productId.value, 
          type: 'keluar', 
          qty: item.quantity.value,
          hargaMasuk: 0.0, 
          refNo: dataTransaksi.invoiceNo.value,
        );
      }

      if (dataTransaksi.debt.value > 0 && dataTransaksi.customerId.value != null) {
        final totalHarga = dataTransaksi.total.value;
        final dp = dataTransaksi.paid.value;
        final sisaPiutang = dataTransaksi.debt.value;
        final custId = dataTransaksi.customerId.value!;
        final receivableId = 'RC-${dataTransaksi.id.value}';

        final statusPiutang = DebtStatus.tentukanStatus(sisaPiutang, dp);

        await into(receivables).insert(
          ReceivablesCompanion.insert(
            id: receivableId,
            transactionId: dataTransaksi.id.value,
            customerId: custId,
            totalAmount: totalHarga,
            paidAmount: Value(dp),
            remainingAmount: sisaPiutang < 0 ? 0.0 : sisaPiutang,
            dueDate: DateTime.now().add(const Duration(days: 14)),
            status: Value(statusPiutang),
          ),
        );

        final customer = await (select(customers)..where((t) => t.id.equals(custId))).getSingleOrNull();
        if (customer != null) {
          final newTotalDebt = customer.totalDebt + sisaPiutang;
          await (update(customers)..where((t) => t.id.equals(custId))).write(
            CustomersCompanion(totalDebt: Value(newTotalDebt)),
          );
        }

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

final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());