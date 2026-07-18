import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/product_pos.dart'; // Jalur model Product Bapak
import '../../features/pos/pos_page.dart'; // Jalur model CartItem

class AppDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================
  // 1. DATA PRODUK (STREAM REALTIME & MANAJEMEN DATA)
  // =========================================================
  
  // Fungsi Aliran Data Produk Realtime untuk GridView Kasir
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

  // Fungsi Menyimpan Produk Baru dari Form Dialog Tambah Produk
  Future<void> tambahProduk({
    required String name,
    required double buyPrice,
    required double sellPrice,
    String? barcode,
    String unitBase = 'pcs',
    int stock = 0,
    String category = 'Umum',
  }) async {
    await _firestore.collection('products').add({
      'name': name,
      'barcode': barcode ?? 'PSB-${DateTime.now().millisecondsSinceEpoch}',
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'unitBase': unitBase,
      'stock': stock,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(), // Timestamp server Firebase
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
    // Menggunakan WriteBatch agar aman: jika salah satu gagal, seluruh transaksi dibatalkan otomatis
    final batch = _firestore.batch();
    final txDocRef = _firestore.collection('transactions').doc();

    // Dokumen 1: Simpan Nota Transaksi Baru ke Folder 'transactions'
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

    // Dokumen 2: Kurangi Stok Produk secara Otomatis di Cloud Firestore
    for (var item in cartItems) {
      final productDocRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productDocRef, {
        'stock': FieldValue.increment(-item.qty), // Memotong stok langsung di server
      });
    }

    // Eksekusi semua perintah batch sekaligus
    await batch.commit();
  }
}

// =========================================================
// 3. RIVERPOD PROVIDERS (Eksport Global)
// =========================================================

// Global Provider agar Class Database bisa dibaca oleh file UI manapun
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream Provider khusus untuk melayani tampilan GridView Produk secara realtime
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(appDatabaseProvider).streamProducts();
});
