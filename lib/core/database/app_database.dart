import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart'; // <--- jangan lupa ini

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().nullable()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get purchasePrice => integer()();
  IntColumn get sellingPrice => integer()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class ProductUnits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  TextColumn get unitName => text()();
  IntColumn get conversion => integer()();
  IntColumn get sellingPrice => integer()();
  TextColumn get barcode => text().nullable()();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get total => integer()();
  IntColumn get customerId => integer().nullable()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get productId => integer()();
  IntColumn get quantity => integer()();
  IntColumn get price => integer()();
  TextColumn get unit => text()();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer()();
  IntColumn get transactionId => integer().nullable()();
  IntColumn get totalDebt => integer()();
  IntColumn get remainingDebt => integer()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
}

class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(tables: [
  Products, Categories, ProductUnits, 
  Customers, Transactions, TransactionItems, 
  Debts, DebtPayments
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- Query helper mu taruh bawah sini ---
  Future<List<Product>> getAllProducts() => select(products).get();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'ud_putra_db',
    // Ini kunci biar Web gak putih
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        if (result.missingFeatures.isNotEmpty) {
          print('Missing features: ${result.missingFeatures}');
        }
      },
    ),
  );
}