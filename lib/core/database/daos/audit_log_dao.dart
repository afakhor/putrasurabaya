import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/constant/audit_constant.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, FraudAlerts])
class AuditLogDao extends DatabaseAccessor<LocalDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. AUDIT LOG ACTIVITY
  // ===========================================================================
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

  Stream<List<AuditLogData>> watchRecentAuditLogs({int limit = 50}) {
    return (select(auditLogs)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  /// INI YANG DIPAKAI MATA ELANG - FULL FILTER SINKRON TRANSACTION
  Stream<List<AuditLogData>> watchCctvPerItem({
    String? keyword,
    String? actionType,
    DateTime? start,
    DateTime? end,
  }) {
    return (select(auditLogs)
          ..where((tbl) {
            Expression<bool> clause = const Constant(true);
            if (keyword != null && keyword.isNotEmpty) {
              // LIKE %keyword% untuk search faktur / customer / kode / nama / sales / rack
              clause = clause & (tbl.description.like('%$keyword%') | tbl.actionType.like('%$keyword%') | tbl.oldValue.like('%$keyword%') | tbl.newValue.like('%$keyword%') | tbl.userId.like('%$keyword%') | tbl.referenceId.like('%$keyword%'));
            }
            if (actionType != null && actionType.isNotEmpty && actionType != 'SEMUA') {
              clause = clause & tbl.actionType.equals(actionType);
            }
            if (start != null) {
              clause = clause & tbl.createdAt.isBiggerOrEqualValue(start);
            }
            if (end != null) {
              // end of day
              final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
              clause = clause & tbl.createdAt.isSmallerOrEqualValue(endDay);
            }
            return clause;
          })
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<AuditLogData>> getLogsByReference(String referenceId) {
    return (select(auditLogs)
          ..where((tbl) => tbl.referenceId.equals(referenceId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // ===========================================================================
  // 2. FRAUD ALERT - FIX UNTUK ERROR fraudAlertDao IS NOT DEFINED
  // ===========================================================================
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

  Stream<String> watchOwnerRiskStatus() {
    return (select(fraudAlerts)..where((tbl) => tbl.isResolved.equals(false))).watch().map((alerts) {
      if (alerts.isEmpty) return 'hijau';
      final hasRed = alerts.any((a) => a.severity == FraudSeverity.merah);
      return hasRed ? 'merah' : 'kuning';
    });
  }

  Stream<List<FraudAlertData>> watchActiveFraudAlerts() {
    return (select(fraudAlerts)
          ..where((tbl) => tbl.isResolved.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // ============== FIX UTAMA BIAR db.fraudAlertDao.watchAllAlerts() JALAN ==============
  Stream<List<FraudAlertData>> watchAllAlerts() {
    return (select(fraudAlerts)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<FraudAlertData>> watchAllFraudAlerts() => watchAllAlerts();

  Future<List<FraudAlertData>> getAllUnresolved() {
    return (select(fraudAlerts)..where((t)=> t.isResolved.equals(false))).get();
  }
  // ============== END FIX ==============

  Future<void> resolveFraudAlert({required String alertId, required String ownerUserId}) async {
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

final auditLogDaoProvider = Provider<AuditLogDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return AuditLogDao(db);
});

// ALIAS BIAR db.fraudAlertDao TETAP BISA DIPANGGIL - FIX ERROR BUILD
extension FraudAlertDaoExtension on LocalDatabase {
  // ini akan di-override di local_database.dart dengan getter beneran
}