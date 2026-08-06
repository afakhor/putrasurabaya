import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/tables/product_table.dart';

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  
  // Enum: pembelian, itemMasuk, penjualan, itemKeluar, opname, perakitanBahan, prosesJadi
  TextColumn get type => text()(); 
  RealColumn get quantity => real()(); // + untuk masuk, - untuk keluar

  // SNAPSHOT WAJIB v14 & v15
  RealColumn get stockBefore => real().withDefault(const Constant(0))();
  RealColumn get stockAfter => real().withDefault(const Constant(0))();
  RealColumn get hppSnapshot => real().withDefault(const Constant(0))(); // v15
  RealColumn get currentStockSnapshot => real().withDefault(const Constant(0))(); // alias stockAfter untuk kartu
  TextColumn get rackLocation => text().nullable()(); // v15

  TextColumn get referenceNo => text()();
  DateTimeColumn get date => dateTime()(); // Bisa tanggal mundur untuk opname

  TextColumn get userId => text().nullable()(); // v14
  TextColumn get notes => text().nullable()(); // v14

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Konstanta tipe mutasi
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