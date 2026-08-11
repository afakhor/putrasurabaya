import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/constant/audit_constant.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, FraudAlerts])
class AuditLogDao extends DatabaseAccessor<LocalDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Future<void> logAction({
    required String userId,
    String userRole = 'kasir',
    required String actionType,
    String? tableName,
    String? recordId,
    String? oldValue,
    String? newValue,
    String? description,
  }) async {
    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      userRole: Value(userRole),
      actionType: actionType,
      tblName: Value(tableName),
      recordId: Value(recordId),
      referenceId: Value(recordId),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      description: Value(description),
    ));
  }

  // wrapper baru biar payables_dao tidak perlu import manual
  Future<void> logActivity({
    required String userId,
    String userRole = 'owner',
    required String actionType,
    required String tableName,
    String? referenceId,
    String? recordId,
    String? oldValueJson,
    String? newValueJson,
    String? description,
  }) => logAction(userId: userId, userRole: userRole, actionType: actionType, tableName: tableName, recordId: recordId ?? referenceId, oldValue: oldValueJson, newValue: newValueJson, description: description);

  Stream<List<AuditLogData>> watchRecentAuditLogs({int limit = 50}) {
    return (select(auditLogs)..orderBy([(t)=> OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])..limit(limit)).watch();
  }

  // FIX: jangan pakai | di drift, pakai filter dart nanti kalau butuh search
  Stream<List<AuditLogData>> watchCctvPerItem({String? keyword, DateTime? start, DateTime? end}) {
    var q = select(auditLogs);
    if (start != null && end != null) {
      q = q..where((tbl) => tbl.createdAt.isBetweenValues(start, end));
    }
    // keyword filter dilakukan di UI via dart, bukan via | drift yang error
    q = q..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch().map((list) {
      if (keyword == null || keyword.isEmpty) return list;
      final k = keyword.toLowerCase();
      return list.where((e) => (e.description ?? '').toLowerCase().contains(k) || e.actionType.toLowerCase().contains(k) || (e.referenceId ?? '').toLowerCase().contains(k)).toList();
    });
  }

  Future<List<AuditLogData>> getLogsByReference(String referenceId) => (select(auditLogs)..where((tbl) => tbl.referenceId.equals(referenceId))).get();

  Future<void> createFraudAlert({
    required String userId,
    required String alertType,
    String title = 'Fraud Alert',
    String description = '',
    String detailAnalysis = '',
    String fraudCategory = FraudCategory.general,
    String severity = FraudSeverity.kuning,
    String? auditLogId,
  }) async {
    await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      alertType: alertType,
      title: Value(title),
      description: Value(description),
      detailAnalysis: Value(detailAnalysis),
      fraudCategory: Value(fraudCategory),
      severity: Value(severity),
      auditLogId: Value(auditLogId),
    ));
  }

  Future<void> pushFraud({required String userId, required String alertType, required String title, required String description, String category = 'general', String severity = 'kuning', String? auditLogId}) =>
    createFraudAlert(userId: userId, alertType: alertType, title: title, description: description, detailAnalysis: description, fraudCategory: category, severity: severity, auditLogId: auditLogId);

  Stream<List<FraudAlertData>> watchActiveFraudAlerts() => (select(fraudAlerts)..where((t) => t.isResolved.equals(false))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  Stream<List<FraudAlertData>> watchAllAlerts() => (select(fraudAlerts)..orderBy([(t)=> OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  Stream<List<FraudAlertData>> watchAllFraudAlerts() => watchAllAlerts();
  Stream<List<AuditLogData>> watchByTable(String tableName) => (select(auditLogs)..where((t) => t.tblName.equals(tableName))..orderBy([(t) => OrderingTerm.desc(t.createdAt)]).limit(100)).watch();
  Stream<List<FraudAlertData>> watchMerah() => (select(fraudAlerts)..where((t) => t.severity.equals('merah'))..orderBy([(t) => OrderingTerm.desc(t.createdAt)]).limit(50)).watch();
  Stream<List<FraudAlertData>> watchAllActive() => (select(fraudAlerts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]).limit(100)).watch();
  Future<List<FraudAlertData>> getAllUnresolved() => (select(fraudAlerts)..where((t)=> t.isResolved.equals(false))).get();
  Future<void> resolveAlert(String id, String ownerUserId) async { await (update(fraudAlerts)..where((t)=> t.id.equals(id))).write(FraudAlertsCompanion(isResolved: const Value(true), resolvedBy: Value(ownerUserId), isRead: const Value(true))); }
}

final auditLogDaoProvider = Provider<AuditLogDao>((ref) => AuditLogDao(ref.watch(localDatabaseProvider)));