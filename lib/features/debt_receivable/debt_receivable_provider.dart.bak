import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/receivables_dao.dart';

// Riverpod provider untuk mengambil daftar seluruh piutang
final receivablesListProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(localDatabaseProvider);
  
  // Menggunakan method DAO untuk mengambil data piutang
  return db.getReceivablesWithCustomer(); 
});
