import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sesuaikan path ini dengan lokasi file local_database Anda
import '../database/local_database.dart'; 

class SyncService {
  final Ref _ref; // 💡 PERBAIKAN: Gunakan Ref untuk fleksibilitas akses provider
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription? _productSubscription; // 💡 TAMBAHAN: Subscription untuk memantau produk dari Cloud
  
  bool _isSyncing = false;

  SyncService(this._ref);

  // Getter helper untuk mempermudah pemanggilan database SQLite lokal
  LocalDatabase get _db => _ref.read(localDatabaseProvider);

  /// Memulai pemantauan koneksi internet dan sinkronisasi produk real-time
  void startListening() {
    debugPrint('🔄 SyncService: Memulai engine sinkronisasi dua arah...');

    // Bersihkan subscription lama jika fungsi ini tidak sengaja terpanggil ulang
    _connectivitySubscription?.cancel();
    _productSubscription?.cancel();

    // ==========================================
    // Arah 1: Cloud Firestore ➔ Drift SQLite Lokal (Real-time)
    // ==========================================
    _listenToCloudProducts();

    // ==========================================
    // Arah 2: Drift SQLite Lokal ➔ Cloud Firestore (Trigger Koneksi)
    // ==========================================
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {

      final hasInternet = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (hasInternet) {
        debugPrint('🌐 Internet Terdeteksi! Menjalankan upload transaksi offline...');
        syncLocalToCloud();
      } else {
        debugPrint('🚫 Perangkat Offline. Sinkronisasi transaksi ditunda.');
      }
    });
  }

  /// 💡 FUNGSI BARU: Mengunduh data produk dari Firestore ke SQLite Lokal secara otomatis
  void _listenToCloudProducts() {
    _productSubscription = _firestore
        .collection('products')
        .snapshots()
        .listen((snapshot) async {
      
      debugPrint('📦 Mengunduh perubahan data produk (${snapshot.docs.length} item) dari Cloud...');
      
      await _db.transaction(() async {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          
          // Upsert: Jika ID barang sudah ada maka diupdate, jika belum ada maka dimasukkan baru
          await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion(
              id: Value(doc.id),
              name: Value(data['name'] ?? ''),
              barcode: Value(data['barcode']),
              buyPrice: Value((data['buyPrice'] ?? 0).toDouble()),
              sellPriceGeneral: Value((data['sellPrice'] ?? 0).toDouble()),
              stock: Value((data['stock'] ?? 0).toDouble()), // SQLite Drift menggunakan tipe Real/Double
              categoryId: Value(data['category'] ?? 'Semua'),
            ),
          );
        }
      });
      debugPrint('✅ Sinkronisasi produk masuk database lokal sukses.');
    }, onError: (error) {
      debugPrint('⚠️ Gagal menyinkronkan data katalog produk dari Cloud: $error');
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
      debugPrint('❌ Gagal sinkronisasi data transaksi: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Proses internal upload transaksi ke Cloud Firestore (Logika lama Anda yang sudah aman)
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
        }, SetOptions(merge: true));

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

  /// Wajib dipanggil saat modul atau aplikasi ditutup
  void dispose() {
    _connectivitySubscription?.cancel();
    _productSubscription?.cancel(); // 💡 Bersihkan stream produk agar tidak bocor di memory
    debugPrint('🛑 SyncService: Pemantauan koneksi dan produk resmi dihentikan.');
  }
}

// 💡 PERBAIKAN PROVIDER: Cukup pass 'ref' ke dalam instance service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
