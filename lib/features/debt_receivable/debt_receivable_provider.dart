// lib/features/debt_receivable/debt_receivable_provider.dart

import 'package0:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/database/daos/receivables_dao.dart'; // <--- IMPORT DI SINI

// Riverpod provider untuk mengambil daftar seluruh piutang
final receivablesListProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(localDatabaseProvider);
  
  // Menggunakan method DAO untuk mengambil data piutang
  return db.getReceivablesWithCustomer(); 
});
