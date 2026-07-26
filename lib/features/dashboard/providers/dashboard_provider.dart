import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import DAO dan Database
import '../../../core/database/daos/dashboard_dao.dart';
import '../../../core/database/local_database.dart';

// Import Model Summary
import '../models/dashboard_finance_summary.dart';

/// Provider untuk mengakses instance DashboardDao
final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return DashboardDao(db);
});

/// StreamProvider untuk memantau ringkasan keuangan dashboard secara real-time
final dashboardFinanceSummaryProvider =
    StreamProvider<DashboardFinanceSummary>((ref) {
  final dao = ref.watch(dashboardDaoProvider);
  return dao.watchFinanceSummary();
});
