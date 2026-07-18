import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_database.g.dart'; // <-- Diubah sesuai nama filenya

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()(); 
  TextColumn get status => text()(); 
  BoolColumn get canEditPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  TextColumn get unitBase => text().withDefault(const Constant('pcs'))();
  RealColumn get stock => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductUnitData')
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()(); 
  TextColumn get unitName => text()();
  IntColumn get conversion => integer()();
  RealColumn get sellingPrice => real()();
  TextColumn get barcode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()();
  RealColumn get subtotal => real()();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text()(); 
  TextColumn get productId => text()(); 
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  TextColumn get unit => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtData')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()(); 
  TextColumn get transactionId => text().nullable()(); 
  RealColumn get totalDebt => real()();
  RealColumn get remainingDebt => real()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()(); 
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Products, Categories, ProductUnits, Customers, Transactions, TransactionItems, Debts, DebtPayments])
class LocalDatabase extends _$LocalDatabase { // <-- Ganti nama class agar tidak bentrok
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; 

  Future<List<ProductData>> getAllProducts() => select(products).get();
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'putra_sby_db');
}

// Provider untuk akses Database Lokal di UI
final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());
