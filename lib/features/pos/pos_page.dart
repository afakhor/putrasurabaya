import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';

// State untuk keranjang
class CartItem {
  final Product product;
  double qty;
  String unit;
  double price;
  CartItem({required this.product, this.qty = 1, required this.unit, required this.price});
  double get subtotal => qty * price;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product p) {
    final index = state.indexWhere((e) => e.product.id == p.id);
    if (index >= 0) {
      state[index].qty++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: p, unit: p.unitBase, price: p.sellPrice)];
    }
  }

  void clear() => state = [];
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

class POSPage extends ConsumerWidget {
  const POSPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kasir UD. Putra Surabaya')),
      body: Row(
        children: [
          // Kiri: List Produk
          Expanded(
            flex: 3,
            child: FutureBuilder<List<Product>>(
              future: db.getAllProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada produk.\nTambah di menu Produk dulu.'));
                }
                final data = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) => Card(
                    child: InkWell(
                      onTap: () => ref.read(cartProvider.notifier).addProduct(data[i]),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data[i].name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(formatRupiah(data[i].sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Stok: ${data[i].stock} ${data[i].unitBase}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Kanan: Keranjang
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue[800],
                    width: double.infinity,
                    child: const Text('KERANJANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (ctx, i) => ListTile(
                        dense: true,
                        title: Text(cart[i].product.name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${cart[i].qty} ${cart[i].unit} x ${formatAngka(cart[i].price)}'),
                        trailing: Text(formatRupiah(cart[i].subtotal)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(formatRupiah(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.isEmpty? null : () {
                              // Nanti disini dialog bayar + print
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur bayar nyusul ya')),
                              );
                            },
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                            child: const Text('BAYAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Nanti buat nambah produk dummy buat test
          _addDummyProduct(ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addDummyProduct(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.into(db.products).insert(ProductsCompanion.insert(
      name: 'Semen Gresik 50kg',
      barcode: 'PSB${DateTime.now().millisecondsSinceEpoch}',
      sellPrice: 75000,
      buyPrice: 70000,
      unitBase: 'sak',
      stock: 100,
    ));
    // Refresh UI
    ref.invalidate(databaseProvider);
  }
}