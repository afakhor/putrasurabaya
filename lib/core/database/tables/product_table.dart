import 'package:drift/drift.dart';

@DataClassName('ProductData')
class Products extends Table {
  /// Unique ID Produk (e.g. PRD-123456)
  TextColumn get id => text()();

  /// Nama Barang / Produk
  TextColumn get name => text()();

  /// Barcode / Kode SKU Barang (Opsional)
  TextColumn get barcode => text().nullable()();

  /// Harga Beli / Kulakan (Modal)
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))();

  /// Harga Jual
  RealColumn get price => real().withDefault(const Constant(0.0))();

  /// Jumlah Stok Saat Ini
  IntColumn get stock => integer().withDefault(const Constant(0))();

  /// Batas Minimum Stok (Untuk peringatan stok menipis di Dashboard)
  IntColumn get minStock => integer().withDefault(const Constant(5))();

  /// Satuan Barang (pcs, kg, dus, dll)
  TextColumn get unit => text().withDefault(const Constant('pcs'))();

  /// Status Produk ('aktif' / 'nonaktif')
  TextColumn get statusActive => text().withDefault(const Constant('aktif'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
