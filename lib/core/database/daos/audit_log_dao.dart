import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, FraudAlerts])
class AuditLogDao extends DatabaseAccessor<LocalDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(LocalDatabase db) : super(db);

  /// 1. Catat Log Aktivitas
  Future<void> logActivity({
    required String userId,
    required String userRole,
    required String actionType,
    required String description,
    String? referenceId,
    String? oldValue,
    String? newValue,
  }) async {
    await into(auditLogs).insert(
      AuditLogsCompanion.insert(
        id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userRole: userRole,
        actionType: actionType,
        description: description,
        referenceId: Value(referenceId),
        oldValue: Value(oldValue),
        newValue: Value(newValue),
      ),
    );
  }

  /// 2. Picu Peringatan Fraud (Kuning / Merah)
  Future<void> triggerFraudAlert({
    required String userId,
    required String fraudCategory,
    required String severity, // 'kuning' atau 'merah'
    required String title,
    required String detailAnalysis,
    String? auditLogId,
  }) async {
    await into(fraudAlerts).insert(
      FraudAlertsCompanion.insert(
        id: 'ALERT-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        auditLogId: Value(auditLogId),
        fraudCategory: fraudCategory,
        severity: severity,
        title: title,
        detailAnalysis: detailAnalysis,
      ),
    );
  }

  /// 3. Stream Status Risiko Utama untuk Dashboard Owner ('hijau', 'kuning', 'merah')
  Stream<String> watchOwnerRiskStatus() {
    return (select(fraudAlerts)..where((tbl) => tbl.isResolved.equals(false))).watch().map((alerts) {
      if (alerts.isEmpty) return 'hijau';
      final hasRed = alerts.any((a) => a.severity == 'merah');
      return hasRed ? 'merah' : 'kuning';
    });
  }

  /// 4. Ambil Daftar Alert Fraud Aktif (Belum Dikonfirmasi Owner)
  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)
          ..where((tbl) => tbl.isResolved.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// 5. RESET HAK OWNER: Konfirmasi dan Hapus Warning Fraud oleh Owner
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

final auditLogDaoProvider = Provider<AuditLogDao>((ref) {
  return AuditLogDao(ref.watch(localDatabaseProvider));
});
