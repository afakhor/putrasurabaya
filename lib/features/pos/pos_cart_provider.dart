import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/transaction_dao.dart';
import 'package:ud_putra_kasir/core/services/sync_service.dart';

// ==========================================
// 1. MODEL ITEM (CART ITEM)
// ==========================================
class CartItem {
  final ProductData product;
  final double quantity;
  final double price;
  final double discount;

  CartItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get subtotal => (quantity * price) - discount;

  CartItem copyWith({
    ProductData? product,
    double? quantity,
    double? price,
    double? discount,
  }) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    discount: discount ?? this.discount,
  );
}

// ==========================================
// 2. STATE KERANJANG
// ==========================================
class PosCartState {
  final List<CartItem> items;
  final CustomerData? selectedCustomer;
  final String paymentMethod; 
  final double paidAmount;
  final double discountTotal;

  PosCartState({
    this.items = const [],
    this.selectedCustomer,
    this.paymentMethod = 'cash',
    this.paidAmount = 0,
    this.discountTotal = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => (subtotal - discountTotal).clamp(0, double.infinity);
  double get debt => (paymentMethod == 'tempo') ? (total - paidAmount).clamp(0, double.infinity) : 0;
  double get change => (paidAmount > total) ? (paidAmount - total) : 0;
  
  bool get isEmpty => items.isEmpty;

  PosCartState copyWith({
    List<CartItem>? items,
    CustomerData? selectedCustomer,
    String? paymentMethod,
    double? paidAmount,
    double? discountTotal,
    bool clearCustomer = false,
  }) => PosCartState(
    items: items ?? this.items,
    selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paidAmount: paidAmount ?? this.paidAmount,
    discountTotal: discountTotal ?? this.discountTotal,
  );
}

// ==========================================
// 3. NOTIFIER (LOGIKA BISNIS MODERN)
// ==========================================
class PosCartNotifier extends Notifier<PosCartState> {
  @override
  PosCartState build() => PosCartState();

  void addProduct(ProductData product, {double quantity = 1}) {
    final index = state.items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final items = List<CartItem>.from(state.items);
      items[index] = items[index].copyWith(quantity: items[index].quantity + quantity);
      state = state.copyWith(items: items);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity, price: product.sellPriceGeneral)]);
    }
  }

  void clearCart() => state = PosCartState();

  // ==========================================
  // 4. CHECKOUT (SINKRON DENGAN STRUK)
  // ==========================================
  Future<bool> checkout(Ref ref) async {
    if (state.isEmpty) return false;

    final db = ref.read(localDatabaseProvider);
    final txId = 'TX-${DateTime.now().microsecondsSinceEpoch}';

    try {
      await db.transaction(() async {
        // Simpan Transaksi
        await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: txId,
          total: state.total,
          paid: state.paidAmount,
          debt: state.debt,
          paymentMethod: state.paymentMethod,
          date: DateTime.now(),
        ));

        // Simpan Item
        for (var item in state.items) {
          await db.into(db.transactionItems).insert(TransactionItemsCompanion.insert(
            transactionId: txId,
            productId: item.product.id,
            quantity: item.quantity,
            price: item.price,
          ));
        }
      });

      ref.read(syncServiceProvider).syncLocalToCloud();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final posCartProvider = NotifierProvider<PosCartNotifier, PosCartState>(PosCartNotifier.new);
