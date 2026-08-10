import 'package:drift/drift.dart';
import 'product_table.dart';

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get hppBefore => real().withDefault(const Constant(0))();
  RealColumn get hppAfter => real().withDefault(const Constant(0))();
  RealColumn get hppSnapshot => real().withDefault(const Constant(0))();
  RealColumn get currentStockSnapshot => real().withDefault(const Constant(0))();
  RealColumn get buyPriceAtThatTime => real().withDefault(const Constant(0))();
  TextColumn get referenceId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}