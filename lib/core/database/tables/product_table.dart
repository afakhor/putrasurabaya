import 'package:drift/drift.dart';
import 'category_table.dart';

// ==========================================
// 1. TABEL UTAMA MASTER PRODUK
// ==========================================
@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get code => text().nullable()(); // SKU / Kode Barang
  TextColumn get barcode => text().nullable()(); // Barcode Scanner
  TextColumn get name => text()();
  
  // Harga Pokok & Multi Tier Harga Jual Utama (Pcs/Base Unit)
  RealColumn get costPrice => real().withDefault(const Constant(0.0))(); // HPP
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))(); // Tier 1 (Eceran)
  RealColumn get priceTier2 => real().withDefault(const Constant(0.0))(); // Tier 2 (Semi Grosir)
  RealColumn get priceTier3 => real().withDefault(const Constant(0.0))(); // Tier 3 (Grosir)

  // Stok & Satuan Dasar
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get minStock => real().withDefault(const Constant(0.0))(); // Alert Stok Menipis
  TextColumn get unit => text().withDefault(const Constant('Pcs'))(); // Satuan Dasar

  // Status & Audit Sync
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'nonaktif'
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. TABEL FOTO / ASSET PRODUK
// ==========================================
@DataClassName('ProductAssetData')
class ProductAssets extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get imagePath => text()(); // Path Lokal / URL Cloud
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 3. TABEL MULTI SATUAN & KONVERSI (Dus, Slop, Pack)
// ==========================================
@DataClassName('ProductUnitData')
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get unitName => text()(); // Misal: 'Dus', 'Slop'
  RealColumn get conversionFactor => real()(); // Faktor Pengali ke Pcs (misal 1 Dus = 24 Pcs)
  
  // Harga khusus per satuan grosir
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get priceTier1 => real().withDefault(const Constant(0.0))();
  RealColumn get priceTier2 => real().withDefault(const Constant(0.0))();
  RealColumn get priceTier3 => real().withDefault(const Constant(0.0))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 4. TABEL VARIAN PRODUK (Warna / Rasa / Ukuran)
// ==========================================
@DataClassName('ProductVariantData')
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantName => text()(); // Misal: 'Rasa Cokelat', 'Ukuran L'
  TextColumn get sku => text().nullable()();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))(); // Tambahan harga jika ada
  RealColumn get stock => real().withDefault(const Constant(0.0))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 5. TABEL PROMO & DISKON PRODUK
// ==========================================
@DataClassName('ProductPromoData')
class ProductPromos extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get promoName => text()();
  TextColumn get discountType => text()(); // 'percentage' atau 'nominal'
  RealColumn get discountValue => real()();
  
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 6. TABEL MUTASI & KARTU STOK
// ==========================================
@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  
  /// Type: Gunakan konstanta `StockMutationType`
  TextColumn get type => text()();
  RealColumn get quantity => real()(); // Positif (+) untuk masuk, Negatif (-) untuk keluar
  RealColumn get stockBefore => real()();
  RealColumn get stockAfter => real()();
  RealColumn get hppSnapshot => real()(); // Mencatat HPP saat mutasi terjadi
  TextColumn get referenceNo => text()(); // No Faktur / No Opname / No Retur
  
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()(); // Operator yang mengubah stok
  TextColumn get notes => text().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}

// ==========================================
// HELPER KONSTANTA TIPE MUTASI STOK
// ==========================================
abstract class StockMutationType {
  static const String pembelian = 'PEMBELIAN';
  static const String penjualan = 'PENJUALAN';
  static const String returPenjualan = 'RETUR_PENJUALAN';
  static const String returPembelian = 'RETUR_PEMBELIAN';
  static const String opname = 'OPNAME';
  static const String itemMasuk = 'ITEM_MASUK';
  static const String itemKeluar = 'ITEM_KELUAR';

  static const List<String> allTypes = [
    pembelian,
    penjualan,
    returPenjualan,
    returPembelian,
    opname,
    itemMasuk,
    itemKeluar,
  ];

  static String getLabel(String type) {
    switch (type) {
      case pembelian:
        return 'Pembelian Supplier';
      case penjualan:
        return 'Penjualan Kasir';
      case returPenjualan:
        return 'Retur Penjualan';
      case returPembelian:
        return 'Retur Pembelian';
      case opname:
        return 'Stok Opname';
      case itemMasuk:
        return 'Barang Masuk (Manual)';
      case itemKeluar:
        return 'Barang Keluar (Rusak/Hilang)';
      default:
        return type;
    }
  }
}
