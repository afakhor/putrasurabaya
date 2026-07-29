import 'package:drift/drift.dart';

@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  
  /// Tipe Kategori: 
  /// - 'product'   (Kategori Barang / Produk)
  /// - 'expense'   (Kategori Pengeluaran Operasional / Kas Out)
  /// - 'cash_in'   (Kategori Pemasukan Non-Penjualan / Kas In)
  /// - 'customer'  (Kategori / Tier Pelanggan: Grosir, Eceran, VIP)
  /// - 'other'     (Kategori Lain-lain)
  TextColumn get type => text()();

  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'nonaktif'
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Helper Konstanta Tipe Kategori (Mencegah Salah Ketik)
abstract class CategoryType {
  static const String product = 'product';
  static const String expense = 'expense';
  static const String cashIn = 'cash_in'; // <-- TAMBAHAN KATEGORI CASH IN
  static const String customer = 'customer';
  static const String other = 'other';
}
