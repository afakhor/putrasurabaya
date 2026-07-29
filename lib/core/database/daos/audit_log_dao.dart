import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/constants/audit_constants.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_tables.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, FraudAlerts])
class AuditLogDao extends DatabaseAccessor<LocalDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(LocalDatabase db) : super(db);

  /// 1. Catat Audit Log Baru (Menembalikan Log ID)
  Future<String> logActivity({
    required String userId,
    required String userRole,
    required String actionType,
    required String description,
    String? referenceId,
    String? oldValue,
    String? newValue,
  }) async {
    final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch}';
    
    await into(auditLogs).insert(
      AuditLogsCompanion.insert(
        id: logId,
        userId: userId,
        userRole: userRole,
        actionType: actionType,
        description: description,
        referenceId: Value(referenceId),
        oldValue: Value(oldValue),
        newValue: Value(newValue),
      ),
    );
    
    return logId;
  }

  /// 2. Picu Fraud Alert (Dihubungkan dengan auditLogId)
  Future<void> triggerFraudAlert({
    required String userId,
    required String fraudCategory,
    required String severity,
    required String title,
    required String detailAnalysis,
    String? auditLogId,
  }) async {
    await into(fraudAlerts).insert(
      FraudAlertsCompanion.insert(
        id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        auditLogId: Value(auditLogId),
        fraudCategory: fraudCategory,
        severity: severity,
        title: title,
        detailAnalysis: detailAnalysis,
      ),
    );
  }

  /// 3. Stream Status Warna Indikator Risiko Owner (Hijau / Kuning / Merah)
  Stream<String> watchOwnerRiskStatus() {
    return (select(fraudAlerts)..where((tbl) => tbl.isResolved.equals(false)))
        .watch()
        .map((alerts) {
      if (alerts.isEmpty) return 'hijau';
      final hasRedAlert = alerts.any((a) => a.severity == FraudSeverity.merah);
      return hasRedAlert ? 'merah' : 'kuning';
    });
  }

  /// 4. Stream Daftar Alert yang Belum Selesai (Untuk Dashboard Owner)
  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)
          ..where((tbl) => tbl.isResolved.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// 5. Resolver Fraud Alert (Hanya dipanggil oleh Owner)
  Future<void> resolveFraudAlert({
    required String alertId,
    required String ownerUserId,
  }) async {
    await (update(fraudAlerts)..where((tbl) => tbl.id.equals(alertId))).write(
      FraudAlertsCompanion(
        isResolved: const Value(true),
        resolvedBy: Value(ownerUserId),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }
}

final auditLogDaoProvider = Provider<AuditLogDao>((ref) => AuditLogDao(ref.watch(localDatabaseProvider)));
