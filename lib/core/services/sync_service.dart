import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(localDatabaseProvider); 
  return SyncService(db);
});

class SyncService {
  final LocalDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._db);

  void startListening() {
    debugPrint('🔄 SyncService: Memulai pemantauan koneksi internet...');

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {

      final hasInternet = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (hasInternet) {
        debugPrint('🌐 Internet Terdeteksi! Memulai sinkronisasi data...');
        syncLocalToCloud();
      } else {
        debugPrint('🚫 Perangkat Offline. Sinkronisasi ditunda.');
      }
    });
  }

  Future<void> syncLocalToCloud() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncTransactions();
    } catch (e) {
      debugPrint('❌ Gagal sinkronisasi data: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTransactions() async {
    final unsyncedTx = await (_db.select(_db.transactions)
          ..where((t) => t.isSynced.equals(false)))
        .get();

    if (unsyncedTx.isEmpty) {
      debugPrint('✅ Semua data transaksi lokal sudah sinkron dengan Cloud.');
      return;
    }

    debugPrint('📦 Ditemukan ${unsyncedTx.length} transaksi baru yang belum di-upload.');

    for (var tx in unsyncedTx) {
      try {
        final items = await (_db.select(_db.transactionItems)
              ..where((item) => item.transactionId.equals(tx.id)))
            .get();

        await _firestore.collection('transactions').doc(tx.id).set({
          'invoiceNo': tx.invoiceNo,
          'subtotal': tx.subtotal,
          'total': tx.total,
          'paid': tx.paid,
          'debt': tx.debt,
          'change': tx.change,
          'paymentMethod': tx.paymentMethod,
          'createdAt': tx.date.toIso8601String(),
          'createdBy': 'Offline Kasir', 
          'items': items.map((item) => {
            'productId': item.productId,
            'quantity': item.quantity,
            'price': item.price,
            'unit': item.unit,
          }).toList(),
        });

        await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id)))
            .write(TransactionsCompanion(
              isSynced: const Value(true),
            ));

        debugPrint('🚀 Nota ${tx.invoiceNo} berhasil disinkronkan ke Cloud!');
      } catch (e) {
        debugPrint('⚠️ Gagal mengunggah nota ${tx.invoiceNo}: $e');
      }
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
