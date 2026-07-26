import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos/dashboard_dao.dart';
import '../../../core/database/local_database.dart';
import '../models/dashboard_finance_summary.dart';

/// Provider DAO
final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return DashboardDao(db);
});

/// StreamProvider Ringkasan Dashboard Utama Real-time
final dashboardFinanceSummaryProvider =
    StreamProvider<DashboardFinanceSummary>((ref) {
  final dao = ref.watch(dashboardDaoProvider);
  return dao.watchFinanceSummary();
});

/// FutureProvider untuk mengambil daftar produk yang stoknya menipis
final lowStockProductsProvider = FutureProvider<List<ProductData>>((ref) {
  final dao = ref.watch(dashboardDaoProvider);
  return dao.getLowStockProducts();
});
