import 'package:drift/drift.dart';

// ==========================================
// 1. TABEL UTAMA USER / PENGGUNA (USERS)
// ==========================================
@DataClassName('UserData')
class Users extends Table {
  // --- 1. IDENTITAS & OTENTIKASI ---
  TextColumn get id => text()(); 
  TextColumn get username => text().nullable()(); // Identifier Login / No HP
  TextColumn get name => text()();
  TextColumn get role => text()(); // 'superuser', 'admin', 'kasir', 'salesman'
  TextColumn get passwordHash => text().nullable()();
  TextColumn get pinCode => text().nullable()(); // PIN 6-digit untuk Cepat Buka Laci/Kasir
  TextColumn get apiKey => text().nullable()(); 

  // --- 2. DATA PROFIL & STATUS ---
  TextColumn get phone => text().nullable()();
  TextColumn get salesArea => text().nullable()(); // Area penagihan/penjualan
  TextColumn get address => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'suspended'

  // --- 3. HAK AKSES HARGA & DISKON ---
  BoolColumn get canOverridePrice => boolean().withDefault(const Constant(false))(); 
  BoolColumn get canGiveDiscount => boolean().withDefault(const Constant(false))();
  RealColumn get maxDiscountPercent => real().withDefault(const Constant(5.0))(); 

  // --- 4. HAK AKSES OPERASIONAL & TRANSAKSI ---
  BoolColumn get canCreateCustomer => boolean().withDefault(const Constant(true))();
  BoolColumn get canCollectPayment => boolean().withDefault(const Constant(true))();
  BoolColumn get canProcessReturn => boolean().withDefault(const Constant(false))();
  BoolColumn get canVoidTransaction => boolean().withDefault(const Constant(false))();
  BoolColumn get canManageStock => boolean().withDefault(const Constant(false))(); // Akses Stok Opname

  // --- 5. AUDITING & OFFLINE SYNC ---
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. TABEL SHIFT KASIR (SHIFT KASIR)
// ==========================================
@DataClassName('ShiftKasirData')
class ShiftKasir extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  
  // --- REKAP ARUS KAS SHIFT ---
  RealColumn get initialCash => real().withDefault(const Constant(0.0))(); // Modal Kas Awal Laci
  RealColumn get totalCashSales => real().withDefault(const Constant(0.0))(); // Total Penjualan Tunai
  RealColumn get totalNonCashSales => real().withDefault(const Constant(0.0))(); // Non-Tunai (Transfer/QRIS)
  RealColumn get totalReceivableCollected => real().withDefault(const Constant(0.0))(); // Terimaan Piutang Tunai
  
  // --- HITUNGAN AKHIR TUTUP SHIFT ---
  RealColumn get expectedCash => real().withDefault(const Constant(0.0))(); // Formula: initialCash + totalCashSales + totalReceivableCollected
  RealColumn get actualCash => real().nullable()(); // Hitungan Fisik Uang Laci oleh Kasir
  RealColumn get cashDifference => real().nullable()(); // Selisih: (actualCash - expectedCash)
  
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))(); // 'open' / 'closed'

  // --- AUDITING & OFFLINE SYNC ---
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}

// ==========================================
// HELPER KONSTANTA ROLE & SHIFT
// ==========================================
abstract class UserRole {
  static const String superuser = 'superuser';
  static const String admin = 'admin';
  static const String kasir = 'kasir';
  static const String salesman = 'salesman';
}

abstract class ShiftStatus {
  static const String open = 'open';
  static const String closed = 'closed';
}
