// lib/core/database/tables/product_table.dart
import 'package:drift/drift.dart';

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get unit => text().withDefault(const Constant('Pcs'))();
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();
  BoolColumn get allowMinusStock => boolean().withDefault(const Constant(false))();
  TextColumn get rackLocation => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class ProductAssets extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get path => text()();
  @override Set<Column> get primaryKey => {id};
}
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get unitName => text()();
  RealColumn get conversion => real().withDefault(const Constant(1))();
  @override Set<Column> get primaryKey => {id};
}
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantName => text()();
  RealColumn get price => real().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}
class ProductPromos extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get promoName => text()();
  @override Set<Column> get primaryKey => {id};
}
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get hppSnapshot => real().withDefault(const Constant(0.0))();
  RealColumn get currentStockSnapshot => real().withDefault(const Constant(0.0))();
  TextColumn get referenceNo => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {id};
}