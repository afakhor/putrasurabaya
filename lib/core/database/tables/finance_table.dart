import 'package:drift/drift.dart';

// ==========================================
// 1. MODUL PIUTANG CUSTOMER (AR)
// ==========================================
@DataClassName('ReceivableData')
class Receivables extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text()(); 
  TextColumn get customerId => text()(); 
  RealColumn get totalAmount => real()(); 
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); 
  RealColumn get remainingAmount => real()(); 
  TextColumn get status => text().withDefault(const Constant('unpaid'))(); 
  DateTimeColumn get dueDate => dateTime()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. MODUL HUTANG SUPPLIER (AP)
// ==========================================
@DataClassName('PayableData')
class Payables extends Table {
  TextColumn get id => text()(); 
  TextColumn get purchaseRef => text()(); 
  TextColumn get supplierId => text()(); 
  RealColumn get totalAmount => real()(); 
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); 
  RealColumn get remainingAmount => real()(); 
  DateTimeColumn get dueDate => dateTime()(); 
  TextColumn get status => text().withDefault(const Constant('unpaid'))(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 3. TABEL ARUS KAS HUTANG & PIUTANG
// ==========================================
@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  TextColumn get id => text()(); 
  TextColumn get refId => text()(); 
  TextColumn get type => text()(); 
  RealColumn get amount => real()(); 
  TextColumn get paymentMethod => text()(); 
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()(); 

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 4. MODUL BEBAN USAHA (EXPENSES)
// ==========================================
@DataClassName('ExpenseData')
class Expenses extends Table {
  TextColumn get id => text()(); 
  TextColumn get category => text()(); 
  RealColumn get amount => real()(); 
  TextColumn get notes => text().nullable()(); 
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
