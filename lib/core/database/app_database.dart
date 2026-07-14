import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().withLength(min: 1, max: 50).nullable()();
  TextColumn get barcode => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get unitBase => text().withDefault(const Constant('pcs'))();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class ProductUnits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get unitName => text()();
  RealColumn get conversionRate => real()(); // 1 sak = 50 kg
  RealColumn get sellPrice => real()();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get debtTotal => real().withDefault(const Constant(0))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get customerName => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paid => real()();
  RealColumn get change => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get cashierName => text().nullable()();
  TextColumn get note => text().nullable()();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get unit => text()();
  RealColumn get qty => real()();
  RealColumn get price => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  RealColumn get totalDebt => real()();
  RealColumn get remainingDebt => real()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get ktpImagePath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Belum Lunas'))();
}

class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().references(Debts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [Products, Categories, ProductUnits, Customers, Transactions, TransactionItems, Debts, DebtPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Product>> getAllProducts() => select(products).get();
  Future<Product> getProductByBarcode(String code) => (select(products)..where((t) => t.barcode.equals(code))).getSingle();
  Future<List<Customer>> getAllCustomers() => select(customers).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ud_putra.db'));
    return NativeDatabase(file);
  });
}