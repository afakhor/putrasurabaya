import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wajib ada untuk membaca 'Provider'
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

// Sesuaikan path ini dengan lokasi file local_database Anda
import '../database/local_database.dart'; 

class SyncService {
  final LocalDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._db);

  /// Memulai pemantauan koneksi internet secara berkala
  void startListening() {
    debugPrint('🔄 SyncService: Memulai pemantauan koneksi internet...');

    // PERBAIKAN 1: Bersihkan subscription lama jika fungsi ini tidak sengaja terpanggil dua kali
    // Ini mencegah penumpukan alokasi memori (memory leak) di latar belakang
    _connectivitySubscription?.cancel();

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

  /// Menjembatani proses sinkronisasi dengan status pengaman
  Future<void> syncLocalToCloud() async {
    if (_isSyncing) {
      debugPrint('⏳ Sinkronisasi sedang berjalan, mengabaikan request baru.');
      return;
    }
    
    _isSyncing = true;

    try {
      await _syncTransactions();
    } catch (e) {
      debugPrint('❌ Gagal sinkronisasi data: $e');
    } finally {
      // PERBAIKAN 2: Pastikan status dikembalikan ke false di dalam blok 'finally'
      // agar engine tidak terkunci selamanya jika terjadi error fatal di tengah jalan
      _isSyncing = false;
    }
  }

  /// Proses internal upload transaksi ke Cloud Firestore
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
        // Mengambil detail item dari transaksi terkait
        final items = await (_db.select(_db.transactionItems)
              ..where((item) => item.transactionId.equals(tx.id)))
            .get();

        // Kirim data ke Firestore
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
        }, SetOptions(merge: true)); // Gunakan merge agar tidak menimpa data utuh jika dokumen sudah ada

        // PERBAIKAN 3: Perbarui flag status sinkronisasi lokal ke SQLite
        // Pastikan 'package:drift/drift.dart' sudah diimpor di atas agar kata kunci 'Value' terbaca
        await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id)))
            .write(TransactionsCompanion(
              isSynced: const Value(true),
            ));

        debugPrint('🚀 Nota ${tx.invoiceNo} berhasil disinkronkan ke Cloud!');
      } catch (e) {
        // Jika ada satu nota yang rusak/gagal, loop akan tetap berlanjut ke nota berikutnya
        debugPrint('⚠️ Gagal mengunggah nota ${tx.invoiceNo}: $e');
      }
    }
  }

  /// Wajib dipanggil saat modul atau aplikasi ditutup
  void dispose() {
    _connectivitySubscription?.cancel();
    debugPrint('🛑 SyncService: Pemantauan koneksi resmi dihentikan.');
  }
}


final syncServiceProvider = Provider<SyncService>((ref) {
  // Pastikan 'localDatabaseProvider' sesuai dengan nama provider database lokal Anda
  final db = ref.watch(localDatabaseProvider); 
  return SyncService(db);
});
