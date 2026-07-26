import 'package:drift/drift.dart';

/// ==========================================
/// 1. MODUL PIUTANG CUSTOMER (ACCOUNTS RECEIVABLE / AR)
/// ==========================================

/// Tabel Utama Piutang Customer
class Receivables extends Table {
  TextColumn get id => text()(); // Contoh: RC-TRX-123 / RC-001
  TextColumn get transactionId => text()(); // ID Penjualan Kasir
  TextColumn get customerId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real()();
  TextColumn get status => text()(); // 'BELUM_LUNAS', 'DICICIL', 'LUNAS' (atau 'unpaid', 'partial', 'paid')
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Riwayat Pembayaran / Cicilan Piutang Customer
class ReceivablePayments extends Table {
  TextColumn get id => text()(); // Contoh: PAY-RC-123
  TextColumn get receivableId => text().references(Receivables, #id)(); // Relasi FK ke Receivables
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()(); // 'cash', 'transfer', 'qris'
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==========================================
/// 2. MODUL HUTANG SUPPLIER (ACCOUNTS PAYABLE / AP)
/// ==========================================

/// Tabel Utama Hutang Ke Supplier
class Payables extends Table {
  TextColumn get id => text()(); // Contoh: AP-001
  TextColumn get purchaseRef => text()(); // No Nota / Faktur Pembelian
  TextColumn get supplierId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real()();
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  TextColumn get status => text()(); // 'BELUM_LUNAS', 'DICICIL', 'LUNAS' (atau 'unpaid', 'partial', 'paid')
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Riwayat Pembayaran / Angsuran Hutang Supplier
class PayablePayments extends Table {
  TextColumn get id => text()(); // Contoh: PAY-AP-123
  TextColumn get payableId => text().references(Payables, #id)(); // Relasi FK ke Payables
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()(); // 'cash', 'transfer'
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==========================================
/// 3. MODUL BEBAN USAHA & OPERASIONAL
/// ==========================================

/// Tabel Operasional / Beban Usaha (Gaji, Listrik, Sewa, dll)
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()(); // 'Gaji', 'Listrik', 'Operasional', 'Beban Kerusakan'
  RealColumn get amount => real()();
  TextColumn get notes => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
