import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/app_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../core/utils/permission_helper.dart';
import '../../main.dart';

class CartItem {
  final Product product;
  final double qty; // Ubah ke final untuk mendukung Immutability
  final String unit;
  final double price;
  
  CartItem({
    required this.product, 
    this.qty = 1, 
    required this.unit, 
    required this.price
  });

  double get subtotal => qty * price;

  // Helper untuk mengubah data secara aman (Immutable Copy)
  CartItem copyWith({double? qty, String? unit, double? price}) {
    return CartItem(
      product: product,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      price: price ?? this.price,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product p) {
    final index = state.indexWhere((e) => e.product.id == p.id);
    if (index >= 0) {
      // Mengubah state secara aman dengan membuat instansi objek baru
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(qty: state[i].qty + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(product: p, unit: p.unitBase, price: p.sellPrice)];
    }
  }

  void removeProduct(int productId) => 
      state = state.where((e) => e.product.id != productId).toList();
      
  void clear() => state = [];
  
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

// 💡 SOLUSI BUG 1: Gunakan StreamProvider agar database dibaca secara Real-Time & Efisien
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch(); // Otomatis update UI jika ada penambahan produk baru
});

class POSPage extends ConsumerStatefulWidget {
  const POSPage({super.key});
  @override
  ConsumerState<POSPage> createState() => _POSPageState();
}

class _POSPageState extends ConsumerState<POSPage> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    if (kIsWeb) return;
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      await requestBluetoothPermissions();
      await Future.delayed(const Duration(milliseconds: 500));
      
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (mounted) setState(() => _isConnected = isConnected);
    } catch (e) {
      debugPrint('Bluetooth init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;
    final productsAsync = ref.watch(productsStreamProvider); // Menggantikan FutureBuilder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir UD. Putra Surabaya'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(_isConnected ? Icons.print : Icons.print_disabled, 
                  color: _isConnected ? Colors.green : Colors.red),
              onPressed: _connectPrinter,
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            // 💡 SOLUSI BUG 1: Menggunakan data reaktif dari StreamProvider
            child: productsAsync.when(
              data: (data) {
                if (data.isEmpty) return const Center(child: Text('Belum ada produk. Klik +'));
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    childAspectRatio: 1.2, 
                    crossAxisSpacing: 8, 
                    mainAxisSpacing: 8
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
                            Text(data[i].name, textAlign: TextAlign.center, maxLines: 2),
                            Text(formatRupiah(data[i].sellPrice), 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Text(cart[i].product.name),
                    subtitle: Text('${cart[i].qty} x ${formatAngka(cart[i].price)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatRupiah(cart[i].subtotal)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => ref.read(cartProvider.notifier).removeProduct(cart[i].product.id),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text('TOTAL: ${formatRupiah(total)}', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton(
                      onPressed: cart.isEmpty ? null : () => _showBayarDialog(context, ref, total), 
                      child: const Text('BAYAR')
                    )
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: kIsWeb ? null : FloatingActionButton(
        onPressed: () => _addDummyProduct(ref), 
        child: const Icon(Icons.add)
      ),
    );
  }

  void _connectPrinter() async {
    if (kIsWeb) return;
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pair printer dulu di setting Bluetooth HP')));
        }
        return;
      }
      bool result = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
      if (mounted) setState(() => _isConnected = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Bluetooth: $e')));
      }
    }
  }

  void _addDummyProduct(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.into(db.products).insert(ProductsCompanion.insert(
      name: 'Semen Gresik ${DateTime.now().second}',
      barcode: Value('PSB${DateTime.now().millisecondsSinceEpoch}'),
      sellPrice: const Value(75000),
      buyPrice: const Value(70000),
      unitBase: const Value('sak'),
      stock: const Value(100),
    ));
    // setState(() {}) DIHAPUS karena StreamProvider otomatis mendeteksi database terupdate!
  }

  void _showBayarDialog(BuildContext context, WidgetRef ref, double total) {
    final bayarController = TextEditingController(text: total.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bayar: ${formatRupiah(total)}'),
        content: TextField(
            controller: bayarController, 
            keyboardType: TextInputType.number, 
            decoration: const InputDecoration(labelText: 'Jumlah Bayar')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final bayar = double.tryParse(bayarController.text) ?? 0;
              _prosesTransaksi(ref, total, bayar, 'Cash');
              Navigator.pop(ctx);
            },
            child: const Text('Proses'),
          ),
        ],
      ),
    );
  }

  void _prosesTransaksi(WidgetRef ref, double total, double bayar, String method) async {
    final db = ref.read(databaseProvider);
    final cart = ref.read(cartProvider);
    final invoiceNo = 'INV${DateTime.now().millisecondsSinceEpoch}';
    
    // 💡 SOLUSI BUG 2: Dapatkan ID Transaksi yang baru dimasukkan
    final transactionId = await db.into(db.transactions).insert(TransactionsCompanion.insert(
      invoiceNo: invoiceNo,
      subtotal: total,
      total: total,
      paid: Value(bayar),
      debt: Value(total - bayar > 0 ? total - bayar : 0),
      paymentMethod: Value(method),
      change: Value(bayar > total ? bayar - total : 0),
    ));

    // 💡 SOLUSI BUG 2: Masukkan semua item transaksi dari keranjang ke database
    for (var item in cart) {
      await db.into(db.transactionItems).insert(TransactionItemsCompanion.insert(
        transactionId: transactionId,
        productId: item.product.id,
        quantity: item.qty,
        price: item.price,
        unit: item.unit,
      ));
    }

    if (!kIsWeb && _isConnected) {
      String struk = 'UD. PUTRA SURABAYA\n$invoiceNo\n----------------\n';
      for (var item in cart) {
        struk += '${item.product.name}\n${item.qty} x ${formatAngka(item.price)} = ${formatRupiah(item.subtotal)}\n';
      }
      struk += '----------------\nTOTAL: ${formatRupiah(total)}\nBAYAR: ${formatRupiah(bayar)}\nTerima Kasih\n\n\n';
      await PrintBluetoothThermal.writeBytes(struk.codeUnits);
    }
    
    ref.read(cartProvider.notifier).clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi sukses')));
  }
}
