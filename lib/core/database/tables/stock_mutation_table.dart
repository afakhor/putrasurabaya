import 'package:drift/drift.dart';
import 'product_table.dart';

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get stockBefore => real().withDefault(const Constant(0))();
  RealColumn get stockAfter => real().withDefault(const Constant(0))();
  RealColumn get currentStockSnapshot => real().withDefault(const Constant(0))(); // FIX UTAMA
  RealColumn get hppBefore => real().withDefault(const Constant(0))();
  RealColumn get hppAfter => real().withDefault(const Constant(0))();
  RealColumn get hppSnapshot => real().withDefault(const Constant(0))();
  RealColumn get buyPriceAtThatTime => real().withDefault(const Constant(0))();
  TextColumn get rackLocation => text().nullable()();
  TextColumn get referenceNo => text().withDefault(const Constant(''))();
  TextColumn get userId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {id};
}