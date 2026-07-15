import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  TextColumn get unitBase => text().withDefault(const Constant('pcs'))();
  RealColumn get stock => real().withDefault(const Constant(0))();
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
  RealColumn get sellingPrice => real()();
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
  TextColumn get invoiceNo => text()();
  RealColumn get subtotal => real()();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get productId => integer()();
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer()();
  IntColumn get transactionId => integer().nullable()();
  RealColumn get totalDebt => real()();
  RealColumn get remainingDebt => real()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
}

class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(tables: [Products, Categories, ProductUnits, Customers, Transactions, TransactionItems, Debts, DebtPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
  Future<List<Product>> getAllProducts() => select(products).get();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'ud_putra_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}