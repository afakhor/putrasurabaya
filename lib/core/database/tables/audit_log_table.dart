import 'package:drift/drift.dart';

/// Tabel Audit Trail seluruh aktivitas sensitif Salesman/Admin
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // ID Salesman/Admin yang melakukan tindakan
  TextColumn get userRole => text()(); // salesman / admin
  TextColumn get actionType => text()(); // EDIT_PRICE, CREATE_STORE, VOID_TRANSACTION, MUTATION_PAYMENT
  TextColumn get description => text()(); 
  TextColumn get referenceId => text().nullable()(); // Invoice ID / Customer ID / Product ID
  TextColumn get oldValue => text().nullable()(); // JSON snapshot sebelum diubah
  TextColumn get newValue => text().nullable()(); // JSON snapshot setelah diubah
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Indikator Status Risiko Anti-Fraud untuk Owner
class FraudAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // Salesman / Admin terduga
  TextColumn get auditLogId => text().nullable()();
  TextColumn get fraudCategory => text()(); // MAIN_HARGA, TOKO_FIKTIF, MANIPULASI_TAGIHAN, VOID_SUSPICIOUS
  TextColumn get severity => text()(); // kuning / merah
  TextColumn get title => text()();
  TextColumn get detailAnalysis => text()(); // Rincian indikasi kecurangan
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))(); // HANYA BISA DIBUAT TRUE OLEH OWNER
  TextColumn get resolvedBy => text().nullable()(); // User ID Owner yang mereset
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
