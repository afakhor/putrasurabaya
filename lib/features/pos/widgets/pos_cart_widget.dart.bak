import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ud_putra_kasir/features/pos/pos_cart_provider.dart';
import 'pos_payment_dialog.dart';

class PosCartWidget extends ConsumerWidget {
  final Function(PosCartState cartSnapshot)? onCheckoutSuccess;

  const PosCartWidget({super.key, this.onCheckoutSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // HEADER KERANJANG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blueGrey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'KERANJANG (${cartState.items.length})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (cartState.items.isNotEmpty)
                  InkWell(
                    onTap: () => cartNotifier.clearCart(),
                    child: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),

          // LIST ITEM KERANJANG
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Belum ada barang dipilih', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${currencyFormatter.format(item.price)} x ${item.quantity.toStringAsFixed(0)} ${item.unit}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            // TOMBOL MINUS
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 22),
                              onPressed: () => cartNotifier.updateQuantity(
                                item.product.id,
                                item.quantity - 1,
                              ),
                            ),
                            // TOMBOL PLUS
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                              onPressed: () => cartNotifier.addProduct(item.product),
                            ),
                            // TOMBOL HAPUS
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                              onPressed: () => cartNotifier.removeProduct(item.product.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // RINGKASAN & TOMBOL CHECKOUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                    Text(currencyFormatter.format(cartState.subtotal)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL BAYAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormatter.format(cartState.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A65A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A65A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('BAYAR / CHECKOUT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: cartState.isEmpty
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (_) => PosPaymentDialog(onSuccess: onCheckoutSuccess),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
