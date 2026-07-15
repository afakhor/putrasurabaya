import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  TextColumn get unitBase => text().withDefault(const Constant('pcs'))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class ProductUnits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().customConstraint('REFERENCES products(id)')();
  TextColumn get unit => text()();
  RealColumn get conversion => real()();
  RealColumn get sellPrice => real()();
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
  RealColumn get paid => real()();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().customConstraint('REFERENCES transactions(id)')();
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  TextColumn get unit => text()();
  RealColumn get qty => real()();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().customConstraint('REFERENCES transactions(id)')();
  IntColumn get customerId => integer().customConstraint('REFERENCES customers(id)')();
  RealColumn get amount => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
}

class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().customConstraint('REFERENCES debts(id)')();
  RealColumn get amount => real()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Products, Categories, ProductUnits, Customers, Transactions, TransactionItems, Debts, DebtPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ud_putra_db'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );

  Future<List<Product>> getAllProducts() => select(products).get();
  Future<Product> getProductByBarcode(String code) => (select(products)..where((t) => t.barcode.equals(code))).getSingle();
  Future<List<Customer>> getAllCustomers() => select(customers).get();
}