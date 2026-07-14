import 'package:drift/drift.dart';
import 'connection/connection.dart' as impl; // Ini yg conditional

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().withLength(min: 1, max: 50).nullable()();
  TextColumn get barcode => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get unitBase => text().withDefault(const Constant('pcs'))();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  RealColumn get total => real()();
  RealColumn get paid => real()();
  RealColumn get debt => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  TextColumn get productName => text()();
  TextColumn get unit => text()();
  RealColumn get qty => real()();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
}

@DriftDatabase(tables: [Products, Customers, Transactions, TransactionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 1;
  Future<List<Product>> getAllProducts() => select(products).get();
}