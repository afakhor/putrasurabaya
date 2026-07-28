// lib/features/pos/pos_cart_provider.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/transaction_dao.dart';
import 'package:ud_putra_kasir/core/services/sync_service.dart';


// ==========================================
// 1. MODEL ITEM KERANJANG (CART ITEM)
// ==========================================

class CartItem {
  final ProductData product;
  final double quantity;
  final double price;
  final String unit;
  final double discount;

  CartItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.unit = 'Pcs',
    this.discount = 0,
  });

  /// Subtotal per baris item (Qty * Harga - Diskon Item)
  double get subtotal => (quantity * price) - discount;

  CartItem copyWith({
    ProductData? product,
    double? quantity,
    double? price,
    String? unit,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      discount: discount ?? this.discount,
    );
  }
}

// ==========================================
// 2. MODEL STATE KERANJANG POS (STATE)
// ==========================================

class PosCartState {
  final List<CartItem> items;
  final CustomerData? selectedCustomer;
  final String paymentMethod; // 'cash', 'qris', 'transfer', 'tempo'
  final double paidAmount;
  final double discountTotal;
  final double taxTotal;

  PosCartState({
    this.items = const [],
    this.selectedCustomer,
    this.paymentMethod = 'cash',
    this.paidAmount = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
  });

  /// Total kotor semua item sebelum diskon nota
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Total bersih yang wajib dibayar
  double get total {
    final net = subtotal - discountTotal + taxTotal;
    return net < 0 ? 0 : net;
  }

  /// Kembalian kasir (jika nominal bayar > total)
  double get change => (paidAmount > total) ? (paidAmount - total) : 0;

  /// Utang/Sisa Piutang (jika bayar < total)
  double get debt => (paidAmount < total) ? (total - paidAmount) : 0;

  bool get isEmpty => items.isEmpty;

  PosCartState copyWith({
    List<CartItem>? items,
    CustomerData? selectedCustomer,
    bool clearCustomer = false,
    String? paymentMethod,
    double? paidAmount,
    double? discountTotal,
    double? taxTotal,
  }) {
    return PosCartState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      discountTotal: discountTotal ?? this.discountTotal,
      taxTotal: taxTotal ?? this.taxTotal,
    );
  }
}

// ==========================================
// 3. STATE NOTIFIER UNTUK LOGIKA KASIR
// ==========================================

class PosCartNotifier extends StateNotifier<PosCartState> {
  final Ref _ref;

  PosCartNotifier(this._ref) : super(PosCartState());

  LocalDatabase get _db => _ref.read(localDatabaseProvider);

  /// Menambahkan produk ke keranjang (jika sudah ada, qty bertambah)
  void addProduct(ProductData product, {double quantity = 1}) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      final currentItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = CartItem(
        product: product,
        quantity: quantity,
        price: product.sellPriceGeneral,
        unit: 'Pcs',
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Mengubah jumlah (quantity) suatu produk
  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Menghapus produk dari keranjang
  void removeProduct(String productId) {
    final updatedItems = state.items.where((item) => item.product.id != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Mengatur pelanggan terpilih
  void setCustomer(CustomerData? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
  }

  /// Mengatur metode pembayaran
  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Mengatur jumlah uang yang diterima dari pembeli
  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  /// Mengatur potongan diskon total nota
  void setDiscountTotal(double discount) {
    state = state.copyWith(discountTotal: discount);
  }

  /// Resets/Clear keranjang belanja
  void clearCart() {
    state = PosCartState();
  }

  // ==========================================
  // 4. PROSES CHECKOUT & UNGGAH SINKRONISASI
  // ==========================================

  /// Menyimpan transaksi ke Drift DB (termasuk potong stok & piutang)
  /// dan memicu SyncService untuk mengunggah ke Cloud jika online.
  Future<bool> checkout({
    String? salesId,
    String? shiftId,
  }) async {
    if (state.isEmpty) return false;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final transactionId = 'TX-$timestamp';
    final invoiceNo = 'INV/$timestamp';

    try {
      // 1. Susun Companion Header Transaksi
      final transactionCompanion = TransactionsCompanion(
        id: Value(transactionId),
        invoiceNo: Value(invoiceNo),
        salesId: Value(salesId),
        shiftId: Value(shiftId),
        customerId: Value(state.selectedCustomer?.id),
        subtotal: Value(state.subtotal),
        discountTotal: Value(state.discountTotal),
        taxTotal: Value(state.taxTotal),
        total: Value(state.total),
        paid: Value(state.paidAmount),
        debt: Value(state.debt),
        change: Value(state.change),
        paymentMethod: Value(state.paymentMethod),
        date: Value(DateTime.now()),
        isSynced: const Value(false), // Masuk antrean lokal (offline-first)
      );

      // 2. Susun Companion Item Transaksi
      final itemsList = state.items.map((item) {
        return TransactionItemsCompanion(
          id: Value('ITM-${DateTime.now().microsecondsSinceEpoch}-${item.product.id}'),
          transactionId: Value(transactionId),
          productId: Value(item.product.id),
          quantity: Value(item.quantity),
          price: Value(item.price),
          buyPriceAtTransaction: Value(item.product.buyPrice), // Snapshot HPP Moving Average
          unit: Value(item.unit),
        );
      }).toList();

      // 3. Simpan secara Atomik via LocalDatabase (Potong stok & catat piutang otomatis)
      await _db.prosesTransaksiPenyimpanan(
        dataTransaksi: transactionCompanion,
        itemTransaksi: itemsList,
      );

      // 4. Pemicu Sinkronisasi Instan ke Cloud
      _ref.read(syncServiceProvider).syncLocalToCloud();

      // 5. Bersihkan Keranjang setelah simpan sukses
      clearCart();

      return true;
    } catch (e) {
      return false;
    }
  }
}

// ==========================================
// 5. PROVIDER GLOBAL RIVERPOD
// ==========================================

final posCartProvider = StateNotifierProvider<PosCartNotifier, PosCartState>((ref) {
  return PosCartNotifier(ref);
});
