import 'package:drift/drift.dart';

/// TABEL MASTER SUPPLIER / VENDOR
@DataClassName('SupplierData')
class Suppliers extends Table {
  // --- 1. IDENTITAS & KONTAK ---
  TextColumn get id => text()();
  TextColumn get name => text()(); // Nama Perusahaan / Toko Supplier
  TextColumn get contactPerson => text().nullable()(); // Nama Salesman / PIC Supplier
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();

  // --- 2. OPERASIONAL & HUTANG (AP) ---
  RealColumn get totalPayable => real().withDefault(const Constant(0.0))(); // Total Hutang Usaha ke Supplier ini
  IntColumn get leadTimeDays => integer().withDefault(const Constant(3))(); // Estimasi waktu pengiriman (hari)

  // --- 3. STATUS & AUDIT OFFLINE ---
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'nonaktif' (Soft Delete)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // Status Sync ke Cloud
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}
