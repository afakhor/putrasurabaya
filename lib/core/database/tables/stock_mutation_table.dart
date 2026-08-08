import 'package:drift/drift.dart';
import 'product_table.dart';

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable();
  TextColumn get type => text()(); // PEMBELIAN, ITEM_MASUK, PENJUALAN, ITEM_KELUAR, OPNAME, PERBAIKAN_SALDO
  RealColumn get quantity => real()(); // + masuk - keluar
  RealColumn get stockBefore => real().withDefault(const Constant(0))();
  RealColumn get stockAfter => real().withDefault(const Constant(0))();
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

abstract class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String itemMasuk = 'ITEM_MASUK';
  static const String penjualan = 'PENJUALAN';
  static const String itemKeluar = 'ITEM_KELUAR';
  static const String opname = 'OPNAME';
  static const String perakitanBahan = 'PERAKITAN_BAHAN';
  static const String prosesJadi = 'PROSES_JADI';
  static const String perbaikan = 'PERBAIKAN_SALDO';
}