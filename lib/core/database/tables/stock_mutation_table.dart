import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  
  // Relasi ke Produk
  TextColumn get productId => text().references(Products, #id)();
  
  // Tipe Mutasi: 'PEMBELIAN', 'ITEM_MASUK', 'PROSES_JADI', 'PENJUALAN', 'ITEM_KELUAR', 'PERAKITAN_BAHAN', 'OPNAME'
  TextColumn get type => text()(); 
  
  RealColumn get quantity => real()();
  RealColumn get stockBefore => real()();
  RealColumn get stockAfter => real()();
  RealColumn get hppSnapshot => real().withDefault(const Constant(0.0))();
  
  TextColumn get referenceNo => text()(); // No Nota / Ref Opname (OPN-xxx, ASM-xxx, MUT-xxx)
  DateTimeColumn get date => dateTime()(); // Tanggal kejadian mutasi (bisa tanggal mundur jika opname)
  
  TextColumn get userId => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
