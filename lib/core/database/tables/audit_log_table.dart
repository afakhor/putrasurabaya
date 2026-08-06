import 'package:drift/drift.dart';

/// Tabel Audit Trail seluruh aktivitas sensitif - CCTV Digital
@DataClassName('AuditLogData')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // ID Salesman/Admin/Owner
  TextColumn get userRole => text()(); // owner / admin / kasir / salesman
  TextColumn get actionType => text()(); // PEMBELIAN, PENJUALAN, OPNAME, EDIT_HARGA, VOID_TRANSACTION
  TextColumn get description => text()(); 
  TextColumn get referenceId => text().nullable()(); // Invoice ID / Product ID / Transaction ID
  TextColumn get oldValue => text().nullable()(); // JSON snapshot sebelum
  TextColumn get newValue => text().nullable()(); // JSON snapshot sesudah
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // <-- FIX INI YANG HILANG
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Indikator Risiko Anti-Fraud untuk Owner
@DataClassName('FraudAlertData')
class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // user terduga
  TextColumn get auditLogId => text().nullable()(); // link ke AuditLogs.id
  TextColumn get fraudCategory => text()(); // MANIPULASI_STOK_OPNAME, MINUS_STOK, MAIN_HARGA
  TextColumn get severity => text()(); // kuning / merah
  TextColumn get title => text()();
  TextColumn get detailAnalysis => text()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolvedBy => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // <-- FIX INI YANG HILANG
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}