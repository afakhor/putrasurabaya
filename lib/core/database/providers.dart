import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_database.dart';

final productsStreamProvider = StreamProvider<List<ProductData>>((ref) {
  return ref.watch(localDatabaseProvider).productDao.watchAllProducts();
});

final productStreamProvider = StreamProvider.family<ProductData?, String>((ref, id) {
  return ref.watch(localDatabaseProvider).productDao.watchProductById(id);
});

final allStockMutationsStreamProvider = StreamProvider.family<List<StockCardItemData>, dynamic>((ref, filter) {
  return ref.watch(localDatabaseProvider).stockMutationDao.watchAllStockMutations();
});