import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pos/pos_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    // Mengaktifkan fitur offline cache bawaan Firestore
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ===========================================================================
  // 1. READ / STREAM PRODUK DARI FIRESTORE
  // ===========================================================================

  /// Stream daftar produk dari Firestore dengan Error Handling
  Stream<List<Product>> streamProducts() {
    return _db
        .collection('products')
        .where('is_active', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();
    }).handleError((error) {
      // Log error tanpa menghentikan Stream UI
      print('Firestore Stream Error: $error');
      return <Product>[];
    });
  }

  // ===========================================================================
  // 2. BACKUP / SYNC TRANSAKSI DARI LOKAL KE CLOUD (PUSH)
  // ===========================================================================

  /// Mengunggah Transaksi POS dari Drift Local ke Cloud Firestore
  Future<void> uploadTransaction(Map<String, dynamic> transactionData) async {
    try {
      final docId = transactionData['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await _db
          .collection('transactions')
          .doc(docId)
          .set(transactionData, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Koneksi timeout saat backup.'),
          );
    } catch (e) {
      print('Gagal upload transaksi ke Firestore: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 3. BATCH SYNC PRODUK MASTER (UP/DOWN)
  // ===========================================================================

  /// Mengunggah / Memperbarui Satu Produk ke Cloud
  Future<void> saveProduct(String id, Map<String, dynamic> productData) async {
    await _db
        .collection('products')
        .doc(id)
        .set(productData, SetOptions(merge: true));
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

/// Provider Singleton untuk FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// StreamProvider Produk dari Cloud
final cloudProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(firestoreServiceProvider).streamProducts();
});
