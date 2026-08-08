import 'package:drift/drift.dart';

@DataClassName('AuditLogData')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userRole => text()();
  TextColumn get actionType => text()();
  TextColumn get description => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('FraudAlertData')
class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get auditLogId => text().nullable()();
  TextColumn get fraudCategory => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get detailAnalysis => text()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolvedBy => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}