import 'package:drift/drift.dart';
import 'product_table.dart';
import 'supplier_table.dart';

@DataClassName('PurchaseData')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNo => text()(); // No Nota Supplier
  TextColumn get supplierId => text().references(Suppliers, #id)();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get debtAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text()(); // SuperUser / Gudang

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseItemData')
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get buyPrice => real()(); // Harga beli per unit dari supplier
  RealColumn get subtotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}
