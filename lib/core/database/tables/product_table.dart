import 'package:drift/drift.dart';

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get unit => text().withDefault(const Constant('Pcs'))();
  
  // Stok & harga
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))(); // HPP Master
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();
  
  // Fitur Tambahan untuk DAO Stok Mutasi
  BoolColumn get allowMinusStock => boolean().withDefault(const Constant(false))();
  TextColumn get rackLocation => text().nullable()(); // Nomor / Posisi Rak Barang

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
