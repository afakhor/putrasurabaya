import 'package:drift/drift.dart';

@DataClassName('AuditLogData')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userRole => text().withDefault(const Constant('kasir'))();
  TextColumn get actionType => text()(); // OVERRIDE_PRICE, DISCOUNT_EXCEED, VOID, DELETE, EDIT_HPP
  TextColumn get tblName => text().named('table_name').nullable()();
  TextColumn get recordId => text().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get description => text().nullable()();
  // TAMBAHAN ANTI HANTU
  TextColumn get ipAddress => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('FraudAlertData')
class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get alertType => text()(); // DISCOUNT_EXCEED, JUAL_RUGI, VOID_BANYAK, STOK_MINUS
  TextColumn get title => text().withDefault(const Constant('Alert'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get detailAnalysis => text().withDefault(const Constant(''))();
  TextColumn get severity => text().withDefault(const Constant('kuning'))(); // kuning, orange, merah
  TextColumn get fraudCategory => text().withDefault(const Constant('general'))();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get auditLogId => text().nullable()();
  TextColumn get resolvedBy => text().nullable()();
  // TAMBAHAN
  TextColumn get referenceId => text().nullable()(); // invoiceNo / productId
  RealColumn get lossAmount => real().withDefault(const Constant(0))(); // untuk hitung laba semu
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}