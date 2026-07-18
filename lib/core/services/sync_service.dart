import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// Provider utama agar SyncService bisa di-inject di mana saja
final syncServiceProvider = Provider<SyncService>((ref) {
  // Pastikan Anda sudah membuat provider untuk AppDatabase di main.dart, misal: databaseProvider
  final db = ref.watch(databaseProvider); 
  return SyncService(db);
});

class SyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._db);

  /// 1. AKTIFKAN PEMANTAUAN INTERNET OTOMATIS
  void startListening() {
    debugPrint('🔄 SyncService: Memulai pemantauan koneksi internet...');
    
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      
      // Cek apakah ada koneksi aktif (Wifi, Mobile Data, atau Ethernet)
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

  /// 2. LOGIKA UTAMA SINKRONISASI DATA
  Future<void> syncLocalToCloud() async {
    // Cegah proses ganda berjalan bersamaan (Race Condition)
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncTransactions();
      // Anda bisa menambahkan fungsi _syncDebts() atau _syncProducts() di sini nanti
    } catch (e) {
      debugPrint('❌ Gagal sinkronisasi data: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 3. SINKRONISASI TABEL TRANSAKSI
  Future<void> _syncTransactions() async {
    // Ambil semua data transaksi lokal yang belum tersinkron (isSynced == false)
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
        // Ambil item produk terkait transaksi ini dari tabel local TransactionItems
        final items = await (_db.select(_db.transactionItems)
              ..where((item) => item.transactionId.equals(tx.id)))
            .get();

        // Push ke Firebase Cloud Firestore menggunakan ID yang sama dengan lokal
        await _firestore.collection('transactions').doc(tx.id).set({
          'invoiceNo': tx.invoiceNo,
          'subtotal': tx.subtotal,
          'total': tx.total,
          'paid': tx.paid,
          'debt': tx.debt,
          'change': tx.change,
          'paymentMethod': tx.paymentMethod,
          'createdAt': tx.date.toIso8601String(),
          'createdBy': 'Offline Kasir', // Bisa disesuaikan dengan nama user auth
          'items': items.map((item) => {
            'productId': item.productId,
            'quantity': item.quantity,
            'price': item.price,
            'unit': item.unit,
          }).toList(),
        });

        // Jika berhasil di-upload ke Firestore, perbarui flag di SQLite lokal menjadi true
        await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id)))
            .write(TransactionsCompanion(
              isSynced: const Value(true),
            ));
        
        debugPrint('🚀 Nota ${tx.invoiceNo} berhasil disinkronkan ke Cloud!');
      } catch (e) {
        // Jika satu nota gagal (misal data korup), log error dan lanjut ke nota berikutnya
        debugPrint('⚠️ Gagal mengunggah nota ${tx.invoiceNo}: $e');
      }
    }
  }

  /// HENTIKAN LISTENER SAAT APLIKASI DITUTUP (ANTI LEAK MEMORY)
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
