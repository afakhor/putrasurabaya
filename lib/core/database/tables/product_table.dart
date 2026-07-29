import 'package:drift/drift.dart';

// ... Tabel Products, ProductAssets, ProductUnits, ProductVariants, ProductPromos tetap sama ...

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  /// Type: 'PEMBELIAN', 'PENJUALAN', 'RETUR_PENJUALAN', 'RETUR_PEMBELIAN', 'OPNAME', 'ITEM_MASUK', 'ITEM_KELUAR'
  TextColumn get type => text()();
  RealColumn get quantity => real()(); // Positif (+) untuk masuk, Negatif (-) untuk keluar
  RealColumn get stockBefore => real()();
  RealColumn get stockAfter => real()();
  RealColumn get hppSnapshot => real()();
  TextColumn get referenceNo => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override 
  Set<Column> get primaryKey => {id};
}
