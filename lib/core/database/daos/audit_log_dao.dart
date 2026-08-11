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
    String? referenceId,
    String? oldValue,
    String? newValue,
    String? description,
    String? ipAddress,
    String? deviceId,
  }) async {
    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      userRole: Value(userRole),
      actionType: actionType,
      tblName: Value(tableName),
      recordId: Value(recordId),
      referenceId: Value(referenceId ?? recordId),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      description: Value(description),
      ipAddress: Value(ipAddress),
      deviceId: Value(deviceId),
    ));
  }

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
  }) => logAction(userId: userId, userRole: userRole, actionType: actionType, tableName: tableName, recordId: recordId ?? referenceId, referenceId: referenceId, oldValue: oldValueJson, newValue: newValueJson, description: description);

  Stream<List<AuditLogData>> watchRecentAuditLogs({int limit = 50}) {
    var q = select(auditLogs);
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    q.limit(limit);
    return q.watch();
  }

  Stream<List<AuditLogData>> watchCctvPerItem({String? keyword, DateTime? start, DateTime? end}) {
    var q = select(auditLogs);
    if (start != null && end != null) {
      q.where((tbl) => tbl.createdAt.isBetweenValues(start, end));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch().map((list) {
      if (keyword == null || keyword.isEmpty) return list;
      final k = keyword.toLowerCase();
      return list.where((e) => (e.description ?? '').toLowerCase().contains(k) || e.actionType.toLowerCase().contains(k) || (e.referenceId ?? '').toLowerCase().contains(k)).toList();
    });
  }

  Future<List<AuditLogData>> getLogsByReference(String referenceId) {
    var q = select(auditLogs);
    q.where((tbl) => tbl.referenceId.equals(referenceId));
    return q.get();
  }

  Future<void> createFraudAlert({
    required String userId,
    required String alertType,
    String title = 'Fraud Alert',
    String description = '',
    String detailAnalysis = '',
    String fraudCategory = FraudCategory.general,
    String severity = FraudSeverity.kuning,
    String? auditLogId,
    String? referenceId,
    double lossAmount = 0,
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
      referenceId: Value(referenceId),
      lossAmount: Value(lossAmount),
    ));
  }

  Future<void> pushFraud({required String userId, required String alertType, required String title, required String description, String category = 'general', String severity = 'kuning', String? auditLogId, String? referenceId, double lossAmount = 0}) =>
    createFraudAlert(userId: userId, alertType: alertType, title: title, description: description, detailAnalysis: description, fraudCategory: category, severity: severity, auditLogId: auditLogId, referenceId: referenceId, lossAmount: lossAmount);

  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    var q = select(fraudAlerts);
    q.where((t) => t.isResolved.equals(false));
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  Stream<List<FraudAlertData>> watchAllAlerts() {
    var q = select(fraudAlerts);
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  Stream<List<FraudAlertData>> watchAllFraudAlerts() => watchAllAlerts();
  Stream<List<AuditLogData>> watchByTable(String tableName) {
    var q = select(auditLogs);
    q.where((t) => t.tblName.equals(tableName));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(100);
    return q.watch();
  }
  Stream<List<FraudAlertData>> watchMerah() {
    var q = select(fraudAlerts);
    q.where((t) => t.severity.equals('merah'));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(50);
    return q.watch();
  }
  Stream<List<FraudAlertData>> watchAllActive() {
    var q = select(fraudAlerts);
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(100);
    return q.watch();
  }
  Future<List<FraudAlertData>> getAllUnresolved() {
    var q = select(fraudAlerts);
    q.where((t) => t.isResolved.equals(false));
    return q.get();
  }
  Future<void> resolveAlert(String id, String ownerUserId) async {
    var q = update(fraudAlerts);
    q.where((t) => t.id.equals(id));
    await q.write(FraudAlertsCompanion(isResolved: const Value(true), resolvedBy: Value(ownerUserId), isRead: const Value(true)));
  }

  // TAMBAHAN RECEIVABLES.md VI
  Stream<List<FraudAlertData>> watchSalesmanBiangNgendap() {
    var q = select(fraudAlerts);
    q.where((t) => t.fraudCategory.equals('piutang_macat') | t.fraudCategory.equals('jual_rugi'));
    q.orderBy([(t) => OrderingTerm.desc(t.lossAmount)]);
    return q.watch();
  }
}

final auditLogDaoProvider = Provider<AuditLogDao>((ref) => AuditLogDao(ref.watch(localDatabaseProvider)));