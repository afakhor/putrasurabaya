import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';
import 'category_table.dart';
import 'customer_table.dart';
import 'transaction_table.dart';
import 'purchase_table.dart';

class DebtStatus {
  static const unpaid = 'belum_lunas';
  static const paid = 'lunas';
  static const String belumLunas = 'belum_lunas';
  static const String lunas = 'lunas';
}

class PaymentType {
  static const cash = 'cash';
  static const transfer = 'transfer';
  static const String cashType = 'cash';
}

// ... lanjut table Payables, Receivables kamu yang lama biarkan ...
// ==========================================
// 1. MODUL PIUTANG CUSTOMER (AR - Accounts Receivable)
// ==========================================
@DataClassName('ReceivableData')
class Receivables extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text().references(Transactions, #id)(); // Relasi ke Faktur Penjualan
  TextColumn get customerId => text().references(Customers, #id)(); // Relasi ke Pelanggan
  TextColumn get salesId => text().nullable()(); // Salesman penanggung jawab piutang

  RealColumn get totalAmount => real()(); // Total Piutang Awal
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); // Total Terbayar
  RealColumn get remainingAmount => real()(); // Sisa Piutang (totalAmount - paidAmount)
  
  TextColumn get status => text().withDefault(const Constant(DebtStatus.unpaid))(); // unpaid, partial, paid
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // Status Sync Server
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. MODUL HUTANG SUPPLIER (AP - Accounts Payable)
// ==========================================
@DataClassName('PayableData')
class Payables extends Table {
  TextColumn get id => text()(); 
  TextColumn get purchaseId => text().references(Purchases, #id)(); // Relasi ke Faktur Pembelian Supplier
  TextColumn get supplierId => text()(); 

  RealColumn get totalAmount => real()(); // Total Hutang Awal
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); // Total Terbayar
  RealColumn get remainingAmount => real()(); // Sisa Hutang ke Supplier
  
  TextColumn get status => text().withDefault(const Constant(DebtStatus.unpaid))(); // unpaid, partial, paid
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 3. TABEL RIWAYAT CICILAN / PELUNASAN (Hutang & Piutang)
// ==========================================
@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  TextColumn get id => text()(); 
  TextColumn get refId => text()(); // Merekam ID dari Receivables.id atau Payables.id
  TextColumn get type => text()(); // 'receivable' (Terima Piutang) atau 'payable' (Bayar Hutang)
  TextColumn get userId => text()(); // User Kasir / Salesman yang menerima / menyerahkan uang
  
  RealColumn get amount => real()(); // Nominal Cicilan / Pelunasan
  TextColumn get paymentMethod => text().withDefault(const Constant(PaymentType.cash))(); // cash, transfer
  TextColumn get proofImage => text().nullable()(); // Path / URL foto bukti transfer / kuitansi
  TextColumn get notes => text().nullable()(); // Catatan tambahan
  
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 4. MODUL KAS OUT (EXPENSES) & KAS IN NON-PENJUALAN
// ==========================================
@DataClassName('ExpenseData')
class Expenses extends Table {
  TextColumn get id => text()(); 
  TextColumn get categoryId => text().references(Categories, #id)(); // Relasi ke Kategori ('expense' / 'cash_in')
  TextColumn get userId => text()(); // Admin / Owner yang mencatat transaksi
  
  RealColumn get amount => real()(); // Nominal Uang Masuk / Keluar
  TextColumn get paymentMethod => text().withDefault(const Constant(PaymentType.cash))(); // cash, transfer
  TextColumn get notes => text().nullable()(); // Keterangan (misal: "Beli Bensin Mobil Box")
  
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
