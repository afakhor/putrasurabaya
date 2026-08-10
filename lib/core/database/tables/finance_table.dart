import 'package:drift/drift.dart';

@DataClassName('PayableData')
class Payables extends Table {
  TextColumn get id => text()();
  TextColumn get supplierName => text()();
  RealColumn get amount => real()();
  RealColumn get remaining => real()();
  TextColumn get status => text().withDefault(const Constant('belum_lunas'))();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ReceivableData')
class Receivables extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  RealColumn get amount => real()();
  RealColumn get remaining => real()();
  TextColumn get status => text().withDefault(const Constant('belum_lunas'))();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()();
  TextColumn get debtType => text()();
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
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
  @override Set<Column> get primaryKey => {id};
}