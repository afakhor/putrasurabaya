import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/transaction_dao.dart';

class SyncService {
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productSub;
  bool _isSyncing = false;

  SyncService(this._ref);

  LocalDatabase get _db => _ref.read(localDatabaseProvider);
  TransactionDao get _txDao => _ref.read(transactionDaoProvider);

  /// Menjalankan listener sinkronisasi dua arah
  Future<void> startListening() async {
    debugPrint('🔄 SyncService: Memulai sinkronisasi...');
    _connSub?.cancel();
    _productSub?.cancel();

    // 1. CLOUD -> LOKAL (Produk Master)
    _productSub = _firestore.collection('products').snapshots().listen((snap) async {
      if (snap.docs.isEmpty) return;

      await _db.batch((b) {
        for (var doc in snap.docs) {
          final d = doc.data();
          b.insert(
            _db.products,
            ProductsCompanion(
              id: Value(doc.id),
              name: Value(d['name'] ?? ''),
              barcode: Value(d['barcode'] ?? ''), 
              buyPrice: Value((d['buyPrice'] ?? 0).toDouble()),
              sellPriceGeneral: Value((d['sellPrice'] ?? d['sellPriceGeneral'] ?? 0).toDouble()),
              stock: Value((d['stock'] ?? 0).toDouble()),
              categoryId: Value(d['category'] ?? d['categoryId'] ?? 'Umum'),
              statusActive: const Value('aktif'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      debugPrint('📦 ${snap.docs.length} produk disinkronkan dari Cloud.');
    });

    // 2. LOKAL -> CLOUD (Antrean Transaksi)
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('🌐 Internet terdeteksi, memicu sinkronisasi...');
        syncLocalToCloud();
      }
    });
  }

  /// Wrapper untuk dipanggil dari UI (seperti di PosPage)
  Future<void> performSync() async {
    await syncLocalToCloud().then((_) {
      debugPrint('✅ Sinkronisasi Berhasil dipicu dari UI.');
    });
  }

  /// Mengunggah transaksi lokal yang belum terkirim
  Future<void> syncLocalToCloud() async {
    // 1. Pengecekan Koneksi
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('🚫 Sinkronisasi dibatalkan: Tidak ada koneksi internet.');
      return;
    }

    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final unsynced = await _txDao.getUnsyncedTransactions();
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('🚀 Memproses ${unsynced.length} transaksi ke Cloud...');

      for (var tx in unsynced) {
        try {
          final items = await _txDao.getItemsForTransaction(tx.id);

          await _firestore.collection('transactions').doc(tx.id).set({
            'invoiceNo': tx.invoiceNo,
            'salesId': tx.salesId,
            'shiftId': tx.shiftId,
            'customerId': tx.customerId,
            'subtotal': tx.subtotal,
            'discountTotal': tx.discountTotal,
            'taxTotal': tx.taxTotal,
            'total': tx.total,
            'paid': tx.paid,
            'debt': tx.debt,
            'change': tx.change,
            'paymentMethod': tx.paymentMethod,
            'date': tx.date.toIso8601String(),
            'isDebt': tx.debt > 0,
            'items': items.map((e) => {
              'productId': e.productId,
              'quantity': e.quantity,
              'price': e.price,
              'buyPriceAtTransaction': e.buyPriceAtTransaction,
              'unit': e.unit,
            }).toList(),
          }, SetOptions(merge: true));

          await _txDao.markAsSynced(tx.id);
          debugPrint('✅ Sukses: ${tx.invoiceNo}');
        } catch (e) {
          debugPrint('⚠️ Gagal kirim ${tx.invoiceNo}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fatal saat sinkronisasi: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connSub?.cancel();
    _productSub?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
