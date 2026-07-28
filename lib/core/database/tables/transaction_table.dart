import 'package:drift/drift.dart';

import 'product_table.dart';

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()();
  TextColumn get salesId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get discountTotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxTotal => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0.0))();
  RealColumn get debt => real().withDefault(const Constant(0.0))();
  RealColumn get change => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); 

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text().references(Transactions, #id)(); 
  TextColumn get productId => text().references(Products, #id)(); 
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  RealColumn get buyPriceAtTransaction => real().withDefault(const Constant(0.0))(); 
  TextColumn get unit => text()();

  @override 
  Set<Column> get primaryKey => {id};
}
