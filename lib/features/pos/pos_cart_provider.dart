import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/receivables_dao.dart';
import '../../core/database/local_database.dart';
import 'pos_models.dart';

/// State Keranjang Belanja Kasir (POS)
class PosCartState {
  final List<CartItem> items;
  final double discount;
  final double taxRate;

  PosCartState({
    this.items = const [],
    this.discount = 0,
    this.taxRate = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => (subtotal - discount) * (taxRate / 100);
  double get grandTotal => (subtotal - discount) + taxAmount;
  
  // Alias getter untuk kompatibilitas jika dipanggil sebagai totalPrice
  double get totalPrice => grandTotal;

  PosCartState copyWith({
    List<CartItem>? items,
    double? discount,
    double? taxRate,
  }) {
    return PosCartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

/// Controller / Notifier Keranjang Belanja Kasir
class PosCartNotifier extends StateNotifier<PosCartState> {
  final LocalDatabase _db;

  PosCartNotifier(this._db) : super(PosCartState());

  /// Menambah item produk ke keranjang
  void addItem(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] = current.copyWith(qty: current.qty + 1);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          product: product,
          qty: 1,
          unit: product.unitBase,
          price: product.sellPrice,
        )
      ]);
    }
  }

  /// Mengubah jumlah (qty) produk
  void updateQty(int index, double newQty) {
    if (newQty <= 0) {
      removeItem(index);
      return;
    }
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[index] = updatedItems[index].copyWith(qty: newQty);
    state = state.copyWith(items: updatedItems);
  }

  /// Menghapus item dari keranjang
  void removeItem(int index) {
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems.removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  /// Mengosongkan keranjang
  void clearCart() {
    state = PosCartState();
  }

  /// Proses Checkout / Pembayaran Transaksi
  Future<bool> processCheckout({
    required String paymentMethod, // 'cash', 'qris', atau 'tempo'
    required String customerId,
    required double dpAmount,
    required DateTime? dueDate,
  }) async {
    if (state.items.isEmpty) return false;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final txId = 'TRX-$timestamp';
    final invoiceNo = 'INV-$timestamp';
    final sisaPiutang = paymentMethod == 'tempo' 
        ? (state.grandTotal - dpAmount) 
        : 0.0;

    // 1. Simpan Transaksi Penjualan Utama & Detail Item ke Database
    final transactionCompanion = TransactionsCompanion.insert(
      id: txId,
      invoiceNo: invoiceNo,
      subtotal: state.subtotal,
      total: state.grandTotal,
      paid: Value(paymentMethod == 'tempo' ? dpAmount : state.grandTotal),
      debt: Value(sisaPiutang > 0 ? sisaPiutang : 0.0),
      change: const Value(0.0),
      paymentMethod: Value(paymentMethod),
      customerId: customerId.isNotEmpty ? Value(customerId) : const Value(null),
      date: Value(DateTime.now()),
    );

    final itemCompanions = state.items.map((item) {
      return TransactionItemsCompanion.insert(
        id: 'ITM-$timestamp-${item.product.id}',
        transactionId: txId,
        productId: item.product.id,
        quantity: item.qty,
        price: item.price,
        unit: item.unit,
      );
    }).toList();

    await _db.prosesTransaksiPenyimpanan(
      dataTransaksi: transactionCompanion,
      itemTransaksi: itemCompanions,
    );

    // 2. Jika Metode Bayar = TEMPO, catat ke tabel Receivables via ReceivablesDao
    if (paymentMethod == 'tempo') {
      await _db.catatPenjualanTempo(
        transactionId: txId,
        customerId: customerId,
        totalAmount: state.grandTotal,
        dpAmount: dpAmount,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
      );
    }

    // 3. Bersihkan keranjang setelah checkout berhasil
    clearCart();
    return true;
  }
}

/// Provider Utama Keranjang POS
final posCartProvider = StateNotifierProvider<PosCartNotifier, PosCartState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return PosCartNotifier(db);
});
