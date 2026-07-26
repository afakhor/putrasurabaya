import 'package:drift/drift.dart';

/// ==========================================
/// 1. MODUL PIUTANG CUSTOMER (ACCOUNTS RECEIVABLE / AR)
/// ==========================================

/// Tabel Utama Piutang Customer
class Receivables extends Table {
  TextColumn get id => text()(); // Contoh: RC-171829100
  TextColumn get transactionId => text()(); // ID Transaksi Penjualan Kasir
  TextColumn get customerId => text()(); // Relasi ke ID Customer
  RealColumn get totalAmount => real()(); // Total Nominal Piutang
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); // Total Terbayar
  RealColumn get remainingAmount => real()(); // Sisa Piutang
  TextColumn get status => text().withDefault(const Constant('unpaid'))(); // 'unpaid', 'partial', 'paid'
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==========================================
/// 2. MODUL HUTANG SUPPLIER (ACCOUNTS PAYABLE / AP)
/// ==========================================

/// Tabel Utama Hutang Ke Supplier
class Payables extends Table {
  TextColumn get id => text()(); // Contoh: AP-171829100
  TextColumn get purchaseRef => text()(); // No Nota / Faktur Pembelian Stok
  TextColumn get supplierId => text()(); // Relasi ke ID Supplier
  RealColumn get totalAmount => real()(); // Total Nominal Hutang
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); // Total Terbayar
  RealColumn get remainingAmount => real()(); // Sisa Hutang
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  TextColumn get status => text().withDefault(const Constant('unpaid'))(); // 'unpaid', 'partial', 'paid'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==========================================
/// 3. TABEL TERPUSAT RIWAYAT PEMBAYARAN (ARUS KAS HUTANG & PIUTANG)
/// ==========================================

/// Tabel Riwayat Angsuran / Pelunasan (Menggabungkan Riwayat AR & AP)
class DebtPayments extends Table {
  TextColumn get id => text()(); // Contoh: PAY-AR-171829100 atau PAY-AP-171829100
  TextColumn get refId => text()(); // Referensi ID dari Tabel Receivables atau Payables
  TextColumn get type => text()(); // 'receivable_collect' (Piutang Masuk) atau 'payable_pay' (Hutang Keluar)
  RealColumn get amount => real()(); // Nominal Yang Dibayarkan
  TextColumn get paymentMethod => text()(); // 'cash', 'transfer', 'qris'
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()(); // Catatan opsional

  @override
  Set<Column> get primaryKey => {id};
}

/// ==========================================
/// 4. MODUL BEBAN USAHA & OPERASIONAL (EXPENSES)
/// ==========================================

/// Tabel Operasional / Beban Usaha (Gaji, Listrik, Sewa, Kerusakan Stok)
class Expenses extends Table {
  TextColumn get id => text()(); // Contoh: EXP-171829100
  TextColumn get category => text()(); // 'Gaji', 'Listrik', 'Sewa', 'Operasional', 'Bebani Kerusakan'
  RealColumn get amount => real()(); // Nominal Beban
  TextColumn get notes => text().nullable()(); // Catatan penjelas (dibuat nullable agar fleksibel)
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
