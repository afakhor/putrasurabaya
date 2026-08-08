import 'package:drift/drift.dart';
import 'product_table.dart';
import 'supplier_table.dart';

@DataClassName('PurchaseData')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNo => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get userId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get debtAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get status => text().withDefault(const Constant('lunas'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseItemData')
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  TextColumn get unitName => text().withDefault(const Constant('Pcs'))();
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))();
  RealColumn get quantity => real()();
  RealColumn get buyPrice => real()(); // HPP masuk - ini yang auto jadi buyPrice di Products
  RealColumn get subtotal => real()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}