// lib/core/services/sync_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_database.dart';
import '../database/daos/transaction_dao.dart';

class SyncService {
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription? _productSub;
  bool _isSyncing = false;

  SyncService(this._ref);

  LocalDatabase get _db => _ref.read(localDatabaseProvider);
  TransactionDao get _txDao => _ref.read(transactionDaoProvider);

  /// Menjalankan listener sinkronisasi dua arah
  void startListening() {
    debugPrint('🔄 SyncService: Menerima koneksi sinkronisasi dua arah');
    _connSub?.cancel();
    _productSub?.cancel();

    // 1. CLOUD -> LOKAL (Produk Master dari Owner/Cloud)
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
              barcode: Value(d['barcode']),
              buyPrice: Value((d['buyPrice'] ?? 0).toDouble()),
              sellPriceGeneral: Value((d['sellPrice'] ?? d['sellPriceGeneral'] ?? 0).toDouble()),
              stock: Value((d['stock'] ?? 0).toDouble()),
              categoryId: Value(d['category'] ?? d['categoryId'] ?? 'Umum'),
              statusActive: const Value('aktif'),
            ),
            mode: InsertMode.insertOrReplace, // Update jika sudah ada, insert jika baru
          );
        }
      });
      debugPrint('📦 ${snap.docs.length} produk disinkronkan dari cloud ke lokal');
    });

    // 2. LOKAL -> CLOUD (Antrean Transaksi Kasir saat Online)
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any(
        (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
      );
      if (online) {
        syncLocalToCloud();
      }
    });
  }

  /// Mengunggah transaksi lokal yang tersimpan dalam antrean (isSynced = false) ke Firestore
  Future<void> syncLocalToCloud() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Ambil antrean transaksi belum terkirim via DAO
      final unsynced = await _txDao.getUnsyncedTransactions();
      if (unsynced.isEmpty) return;

      debugPrint('🚀 Memproses antrean ${unsynced.length} transaksi ke cloud...');

      for (var tx in unsynced) {
        try {
          // 2. Ambil detail item rincian transaksi via DAO
          final items = await _txDao.getItemsForTransaction(tx.id);

          // 3. Set dokumen transaksi ke Firestore
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

          // 4. Perbarui status lokal menjadi isSynced = true via DAO
          await _txDao.markAsSynced(tx.id);
          debugPrint('✅ Transaksi ${tx.invoiceNo} berhasil diunggah');
        } catch (e) {
          debugPrint('⚠️ Gagal sinkronisasi transaksi ${tx.invoiceNo}: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Membatalkan listener saat service di-dispose
  void dispose() {
    _connSub?.cancel();
    _productSub?.cancel();
  }
}

/// Provider Global Riverpod untuk SyncService
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
