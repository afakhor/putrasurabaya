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
    // Menggunakan snapshot agar jika Owner ubah harga di Cloud, Kasir langsung update
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
              barcode: Value(Value(d['barcode'] ?? '')), // Null safety
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
    // Cek koneksi saat startup
    final initialResult = await Connectivity().checkConnectivity();
    _handleConnectivityChange(initialResult);

    // Listener perubahan koneksi
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final online = results.any((r) => 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.wifi || 
        r == ConnectivityResult.ethernet);
    
    if (online) {
      debugPrint('🌐 Internet terdeteksi, memicu sinkronisasi transaksi...');
      syncLocalToCloud();
    }
  }

  /// Mengunggah transaksi lokal yang belum terkirim
  Future<void> syncLocalToCloud() async {
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
