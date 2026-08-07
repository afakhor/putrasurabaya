import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_database.dart';
import 'daos/stock_mutation_dao.dart';

final productDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).productDao);
final stockMutationDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).stockMutationDao);
final dashboardDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).dashboardDao);

final productsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  return ref.watch(localDatabaseProvider).productDao.watchAllProducts();
});
final productStreamProvider = StreamProvider.family<ProductData?, String>((ref, id) {
  return ref.watch(localDatabaseProvider).productDao.watchProductById(id);
});
final kartuStokStreamProvider = StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  return ref.watch(localDatabaseProvider).stockMutationDao.watchKartuStok(productId);
});
final allStockMutationsStreamProvider = StreamProvider.family<List<StockCardItemData>, Map<String,dynamic>>((ref, filter) {
  return ref.watch(localDatabaseProvider).stockMutationDao.watchAllStockMutations(
    mutationTypeFilter: filter['type'] as String?,
    keyword: filter['keyword'] as String?,
  );
});