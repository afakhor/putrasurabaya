import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import konsisten sesuai struktur project
import 'package:ud_putra_kasir/core/constants/audit_constants.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, FraudAlerts])
class AuditLogDao extends DatabaseAccessor<LocalDatabase>
    with _$AuditLogDaoMixin {
  AuditLogDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. AUDIT LOG ACTIVIY (PENCATATAN KANBAN & TRACEABILITY)
  // ===========================================================================

  /// Catat Audit Log Baru (Mengembalikan Log ID)
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
        isSynced: const Value(false),
      ),
    );

    return logId;
  }

  /// Stream Riwayat Audit Log Terbaru (Untuk Dashboard Owner / Supervisor)
  Stream<List<AuditLogData>> watchRecentAuditLogs({int limit = 50}) {
    return (select(auditLogs)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  /// Ambil Jejak Audit berdasarkan ID Referensi (Misal: No Faktur / TransactionId)
  Future<List<AuditLogData>> getLogsByReference(String referenceId) {
    return (select(auditLogs)
          ..where((tbl) => tbl.referenceId.equals(referenceId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // ===========================================================================
  // 2. FRAUD ALERT & INDIKATOR RISIKO OWNER
  // ===========================================================================

  /// Picu Fraud Alert (Dihubungkan dengan auditLogId)
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
        isSynced: const Value(false),
      ),
    );
  }

  /// Stream Status Warna Indikator Risiko Owner (Hijau / Kuning / Merah)
  Stream<String> watchOwnerRiskStatus() {
    return (select(fraudAlerts)..where((tbl) => tbl.isResolved.equals(false)))
        .watch()
        .map((alerts) {
      if (alerts.isEmpty) return 'hijau';
      final hasRedAlert = alerts.any((a) => a.severity == FraudSeverity.merah);
      return hasRedAlert ? 'merah' : 'kuning';
    });
  }

  /// Stream Daftar Alert yang Belum Selesai (Untuk Dashboard Owner)
  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)
          ..where((tbl) => tbl.isResolved.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Resolver Fraud Alert (Hanya dipanggil oleh Owner)
  Future<void> resolveFraudAlert({
    required String alertId,
    required String ownerUserId,
  }) async {
    await (update(fraudAlerts)..where((tbl) => tbl.id.equals(alertId))).write(
      FraudAlertsCompanion(
        isResolved: const Value(true),
        resolvedBy: Value(ownerUserId),
        resolvedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }
}

// ===========================================================================
// PROVIDER RIVERPOD
// ===========================================================================

final auditLogDaoProvider = Provider<AuditLogDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return AuditLogDao(db);
});
