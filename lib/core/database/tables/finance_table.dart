// lib/core/database/tables/financial_tables.dart
import 'package:drift/drift.dart';

/// Tabel Hutang Ke Supplier (Accounts Payable / AP)
class Payables extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseRef => text()(); // No Nota Pembelian
  TextColumn get supplierId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real()();
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  TextColumn get status => text()(); // 'unpaid', 'partial', 'paid'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Piutang Customer (Accounts Receivable / AR)
class Receivables extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()(); // ID Penjualan Kasir
  TextColumn get customerId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real()();
  DateTimeColumn get dueDate => dateTime()(); // Tanggal Jatuh Tempo
  TextColumn get status => text()(); // 'unpaid', 'partial', 'paid'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Riwayat Angsuran & Pelunasan Hutang/Piutang
class DebtPayments extends Table {
  TextColumn get id => text()();
  TextColumn get refId => text()(); // FK ke Payables.id atau Receivables.id
  TextColumn get type => text()(); // 'payable_pay' (Bayar Hutang) atau 'receivable_collect' (Terima Piutang)
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()(); // 'cash', 'transfer'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

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
