import 'package:drift/drift.dart';

/// TABEL MASTER KATEGORI UNIFIKASI (Serbaguna)
@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Tipe Kategori: 
  /// - 'product'   (Kategori Barang / Produk)
  /// - 'expense'   (Kategori Pengeluaran Operasional / Kas Out)
  /// - 'cash_in'   (Kategori Pemasukan Non-Penjualan / Kas In)
  /// - 'customer'  (Kategori / Tier Pelanggan: Grosir, Eceran, VIP)
  /// - 'other'     (Kategori Serbaguna / Lain-lain)
  TextColumn get type => text()();

  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'nonaktif'

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Helper Konstanta Tipe Kategori & Label UI (Mencegah Salah Ketik)
abstract class CategoryType {
  static const String product = 'product';
  static const String expense = 'expense';
  static const String cashIn = 'cash_in';
  static const String customer = 'customer';
  static const String other = 'other';

  /// Daftar seluruh tipe kategori untuk opsi Dropdown
  static const List<String> allTypes = [
    product,
    expense,
    cashIn,
    customer,
    other,
  ];

  /// Helper Konversi Key Tipe ke Label Bahasa Indonesia untuk UI
  static String getLabel(String type) {
    switch (type) {
      case product:
        return 'Kategori Produk';
      case expense:
        return 'Pengeluaran (Kas Out)';
      case cashIn:
        return 'Pemasukan (Kas In)';
      case customer:
        return 'Tier Pelanggan';
      case other:
        return 'Lain-lain';
      default:
        return type.toUpperCase();
    }
  }
}
