import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../local_database.dart';
import '../../../features/dashboard/models/dashboard_finance_summary.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(tables: [Payables, Receivables])
class DashboardDao extends DatabaseAccessor<LocalDatabase> with _$DashboardDaoMixin {
  DashboardDao(LocalDatabase db) : super(db);

  /// Stream Ringkasan Hutang & Piutang Real-time
  Stream<DashboardFinanceSummary> watchFinanceSummary() {
    // 1. Stream Agregasi Total Sisa Hutang (Payables)
    final payablesSum = payables.remainingAmount.sum();
    final payablesCount = payables.id.count();

    final payablesStream = (selectOnly(payables)
          ..addColumns([payablesSum, payablesCount])
          ..where(payables.remainingAmount.isGreaterThanValue(0.0)))
        .watchSingle()
        .map((row) {
      return {
        'total': row.read(payablesSum) ?? 0.0,
        'count': row.read(payablesCount) ?? 0,
      };
    });

    // 2. Stream Agregasi Total Sisa Piutang (Receivables)
    final receivablesSum = receivables.remainingAmount.sum();
    final receivablesCount = receivables.id.count();

    final receivablesStream = (selectOnly(receivables)
          ..addColumns([receivablesSum, receivablesCount])
          ..where(receivables.remainingAmount.isGreaterThanValue(0.0)))
        .watchSingle()
        .map((row) {
      return {
        'total': row.read(receivablesSum) ?? 0.0,
        'count': row.read(receivablesCount) ?? 0,
      };
    });

    // 3. Gabungkan Kedua Stream Menggunakan Rx.combineLatest2
    return Rx.combineLatest2<Map<String, dynamic>, Map<String, dynamic>,
        DashboardFinanceSummary>(
      payablesStream,
      receivablesStream,
      (pData, rData) => DashboardFinanceSummary(
        totalSisaHutang: (pData['total'] as num).toDouble(),
        jumlahHutangAktif: pData['count'] as int,
        totalSisaPiutang: (rData['total'] as num).toDouble(),
        jumlahPiutangAktif: rData['count'] as int,
      ),
    );
  }
}
