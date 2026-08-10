import 'package:drift/drift.dart';

@DataClassName('AuditLogData')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userRole => text()();
  TextColumn get actionType => text()(); // JUAL_TIER_1/2/3, KULAK_HPP_MA, JUAL_RUGI
  TextColumn get description => text()(); // untuk search customer / kode / nama
  TextColumn get referenceId => text().nullable()(); // INI NOMOR FAKTUR - kunci group by omset
  TextColumn get oldValue => text().nullable()(); // JSON: {code, name, categoryId, stock, hpp_ma, rack, supplierId}
  TextColumn get newValue => text().nullable()(); // JSON: {code, qty, harga_jual, hpp_ma, stock, customer, payment: LUNAS/HUTANG/CASH, tier, rack, categoryId, ref}
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('FraudAlertData')
class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get auditLogId => text().nullable()();
  TextColumn get fraudCategory => text()(); // JUAL_RUGI, MAIN_HARGA
  TextColumn get severity => text()(); // merah, kuning, hijau
  TextColumn get title => text()(); // HARGA BOCOR
  TextColumn get detailAnalysis => text()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolvedBy => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}