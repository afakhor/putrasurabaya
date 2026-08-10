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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  Stream<List<AuditLogData>> watchRecentAuditLogs({int limit = 50}) {
    return (select(auditLogs)..orderBy([(t)=> OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])..limit(limit)).watch();
  }

  Stream<List<AuditLogData>> watchCctvPerItem({String? keyword, DateTime? start, DateTime? end}) {
    var q = select(auditLogs);
    if(keyword!=null && keyword.isNotEmpty){
      q = q..where((tbl) => tbl.description.like('%$keyword%') | tbl.actionType.like('%$keyword%') | tbl.oldValue.like('%$keyword%') | tbl.newValue.like('%$keyword%') | tbl.userId.like('%$keyword%') | tbl.referenceId.like('%$keyword%'));
    }
    if(start!=null && end!=null){
      q = q..where((tbl)=> tbl.createdAt.isBetweenValues(start, end));
    }
    q = q..orderBy([(t)=> OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  Future<List<AuditLogData>> getLogsByReference(String referenceId) {
    return (select(auditLogs)..where((tbl) => tbl.referenceId.equals(referenceId))).get();
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
  }) async {
    await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)..where((t) => t.isResolved.equals(false))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  }

  Stream<List<FraudAlertData>> watchAllAlerts() {
    return (select(fraudAlerts)..orderBy([(t)=> OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  }

  Stream<List<FraudAlertData>> watchAllFraudAlerts() => watchAllAlerts();

  Future<List<FraudAlertData>> getAllUnresolved() {
    return (select(fraudAlerts)..where((t)=> t.isResolved.equals(false))).get();
  }

  Future<void> resolveAlert(String id, String ownerUserId) async {
    await (update(fraudAlerts)..where((t)=> t.id.equals(id))).write(FraudAlertsCompanion(
      isResolved: const Value(true),
      resolvedBy: Value(ownerUserId),
      isRead: const Value(true),
    ));
  }
}