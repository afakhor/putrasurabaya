import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/product_pos.dart'; 
import '../../features/pos/pos_page.dart'; 

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Aliran data produk dari cloud (Realtime)
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

  // Tambah produk baru langsung ke cloud
  Future<void> tambahProdukCloud({
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Transaksi penjualan masuk ke cloud
  Future<void> prosesTransaksiPenyimpananCloud({
    required String invoiceNo,
    required double total,
    required double bayar,
    required double sisaHutang,
    required double uangKembali,
    required String method,
    required String kasirNama,
    required List<CartItem> cartItems,
  }) async {
    final batch = _firestore.batch();
    final txDocRef = _firestore.collection('transactions').doc();

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

    for (var item in cartItems) {
      final productDocRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productDocRef, {
        'stock': FieldValue.increment(-item.qty),
      });
    }

    await batch.commit();
  }
}

// Provider untuk akses Firebase Cloud
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Stream Provider untuk GridView Kasir (Membaca data cloud)
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(firestoreServiceProvider).streamProducts();
});
