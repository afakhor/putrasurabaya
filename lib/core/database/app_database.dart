import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/product_pos.dart'; // Sesuaikan dengan path model Product Bapak
import '../../features/pos/pos_page.dart'; // Untuk membaca model CartItem

class AppDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================
  // 1. DATA PRODUK (STREAM REALTIME)
  // =========================================================
  Stream<List<Product>> streamProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          barcode: data['barcode'],
          sellPrice: (data['sellPrice'] ?? 0).toDouble(),
          buyPrice: (data['buyPrice'] ?? 0).toDouble(),
          unitBase: data['unitBase'] ?? 'pcs',
          stock: (data['stock'] ?? 0).toInt(),
          category: data['category'] ?? 'Umum',
        );
      }).toList();
    });
  }

  // =========================================================
  // 2. PROSES TRANSAKSI (BATCH WRITE: SIMPAN & POTONG STOK)
  // =========================================================
  Future<void> prosesTransaksiPenyimpanan({
    required String invoiceNo,
    required double total,
    required double bayar,
    required double sisaHutang,
    required double uangKembali,
    required String method,
    required String kasirNama,
    required List<CartItem> cartItems,
  }) async {
    // Menggunakan WriteBatch agar jika salah satu proses gagal, seluruh transaksi dibatalkan (aman dari error data)
    final batch = _firestore.batch();
    final txDocRef = _firestore.collection('transactions').doc();

    // Dokumen 1: Simpan Nota Transaksi Baru
    batch.set(txDocRef, {
      'invoiceNo': invoiceNo,
      'subtotal': total,
      'total': total,
      'paid': bayar,
      'debt': sisaHutang,
      'paymentMethod': method,
      'change': uangKembali,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': kasirNama,
      'items': cartItems.map((item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'quantity': item.qty,
        'price': item.price,
        'unit': item.unit,
        'subtotal': item.subtotal,
      }).toList(),
    });

    // Dokumen 2: Kurangi Stok Produk secara Otomatis di Cloud
    for (var item in cartItems) {
      final productDocRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productDocRef, {
        'stock': FieldValue.increment(-item.qty), // Mengurangi stok sejumlah qty yang dibeli
      });
    }

    // Eksekusi semua perintah batch sekaligus ke Firebase
    await batch.commit();
  }
}

// Global Provider agar bisa dipanggil dengan mudah oleh ref.read() di file UI manapun
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream Provider khusus untuk dipakai di UI GridView Produk
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(appDatabaseProvider).streamProducts();
});
