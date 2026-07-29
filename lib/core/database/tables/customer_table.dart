import 'package:drift/drift.dart';
import 'category_table.dart';

/// TABEL MASTER PELANGGAN / CUSTOMER
@DataClassName('CustomerData')
class Customers extends Table {
  // --- 1. IDENTITAS & KONTAK ---
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get salesArea => text().nullable()(); // Wilayah / Rute Salesman

  // --- 2. KATEGORI & TIER HARGA ---
  TextColumn get categoryId => text().nullable().references(Categories, #id)(); // Relasi ke Kategori Pelanggan
  IntColumn get defaultTier => integer().withDefault(const Constant(1))(); // Tier 1 (Eceran), 2 (Semi), 3 (Grosir)

  // --- 3. KEANUGERAHAN KREDIT & PIUTANG ---
  RealColumn get totalDebt => real().withDefault(const Constant(0.0))(); // Total Piutang Berjalan
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))(); // Limit Maksimal Kredit (0.0 = Tanpa Limit)

  // --- 4. STATUS & AUDIT OFFLINE ---
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'nonaktif' (Soft Delete)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // Status Sync ke Cloud
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}
