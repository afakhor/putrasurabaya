import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/local_database.dart';

class SyncService {
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription? _productSub;
  bool _isSyncing = false;

  SyncService(this._ref);
  LocalDatabase get _db => _ref.read(localDatabaseProvider);

  void startListening() {
    debugPrint('🔄 SyncService: start dua arah');
    _connSub?.cancel();
    _productSub?.cancel();

    // 1. CLOUD -> LOKAL (produk master dari owner)
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
            mode: InsertMode.insertOrReplace, // paling aman buat sync
          );
        }
      });
      debugPrint('📦 ${snap.docs.length} produk dari cloud -> lokal');
    });

    // 2. LOKAL -> CLOUD (transaksi kasir kalau ada internet)
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
      if (online) syncLocalToCloud();
    });
  }

  Future<void> syncLocalToCloud() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final unsynced = await (_db.select(_db.transactions)..where((t) => t.isSynced.equals(false))).get();
      if (unsynced.isEmpty) return;
      
      for (var tx in unsynced) {
        try {
          final items = await (_db.select(_db.transactionItems)..where((i) => i.transactionId.equals(tx.id))).get();
          final debt = await (_db.select(_db.customerDebts)..where((d) => d.transactionId.equals(tx.id))).getSingleOrNull();

          await _firestore.collection('transactions').doc(tx.id).set({
            'invoiceNo': tx.invoiceNo,
            'subtotal': tx.subtotal,
            'total': tx.total,
            'paid': tx.paid,
            'debt': tx.debt,
            'change': tx.change,
            'paymentMethod': tx.paymentMethod,
            'date': tx.date.toIso8601String(),
            'isDebt': tx.debt > 0,
            'customerDebtId': debt?.id,
            'items': items.map((e) => {'productId': e.productId, 'quantity': e.quantity, 'price': e.price, 'unit': e.unit}).toList(),
          }, SetOptions(merge: true));

          await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id))).write(const TransactionsCompanion(isSynced: Value(true)));
          debugPrint('🚀 ${tx.invoiceNo} synced');
        } catch (e) {
          debugPrint('⚠️ Gagal sync ${tx.invoiceNo}: $e');
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