import 'package:drift/drift.dart';

@DataClassName('PayableData')
class Payables extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get supplierName => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  RealColumn get amount => real().withDefault(const Constant(0))();
  RealColumn get remaining => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('belum_lunas'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ReceivableData')
class Receivables extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get invoiceNo => text().nullable()(); // FIX BUILD - ini yang error
  TextColumn get customerId => text().nullable()();
  TextColumn get customerIdRef => text().nullable()(); // FIX
  TextColumn get customerName => text().nullable()();
  TextColumn get salesId => text().nullable()();
  TextColumn get salesmanId => text().nullable()(); // FIX
  TextColumn get kenapaNgendap => text().withDefault(const Constant('MACET'))(); // FIX
  IntColumn get umurNgendap => integer().withDefault(const Constant(0))(); // FIX
  TextColumn get statusNgendapWarna => text().withDefault(const Constant('HIJAU'))(); // FIX
  DateTimeColumn get invoiceDate => dateTime().nullable()(); // FIX
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  RealColumn get amount => real().withDefault(const Constant(0))();
  RealColumn get remaining => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('belum_lunas'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  TextColumn get id => text()();
  TextColumn get refId => text().nullable()();
  TextColumn get debtId => text().nullable()();
  TextColumn get debtType => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get userId => text().nullable()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get proofImage => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseData')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()(); // FIX
  TextColumn get userId => text().nullable()(); // FIX
  @override Set<Column> get primaryKey => {id};
}