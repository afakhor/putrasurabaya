import 'package:drift/drift.dart';

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get actionType => text()(); // KULAK, PRICE, UPDATE, EDIT
  TextColumn get tableName => text().nullable()();
  TextColumn get recordId => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get alertType => text()();
  TextColumn get description => text()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}