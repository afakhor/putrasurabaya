import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pos/pos_models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  Stream<List<Product>> streamProducts() {
    return _db.collection('products').orderBy('name').snapshots().map((s) => s.docs.map((d) => Product.fromFirestore(d.id, d.data())).toList());
  }
}
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final productsStreamProvider = StreamProvider<List<Product>>((ref) => ref.watch(firestoreServiceProvider).streamProducts());