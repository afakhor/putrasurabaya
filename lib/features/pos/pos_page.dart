import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/app_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../core/utils/permission_helper.dart';
import '../../main.dart';

class CartItem {
  final Product product;
  final double qty;
  final String unit;
  final double price;

  CartItem({required this.product, this.qty = 1, required this.unit, required this.price});
  double get subtotal => qty * price;
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
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(qty: state[i].qty + 1) else state[i]
      ];
    } else {
      state = [...state, CartItem(product: p, unit: p.unitBase, price: p.sellPrice)];
    }
  }

  void removeProduct(int productId) => state = state.where((e) => e.product.id != productId).toList();
  void clear() => state = [];
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch();
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
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      await requestBluetoothPermissions();
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
    final productsAsync = ref.watch(productsStreamProvider);
    final user = ref.watch(currentUserProvider); // Memantau batasan akses user saat ini

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir UD. Putra'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.print : Icons.print_disabled, 
                color: _isConnected ? Colors.green : Colors.red),
            onPressed: _connectPrinter,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Layout responsif untuk HP Android vertikal maupun horizontal
          bool isLandscape = constraints.maxWidth > 600;
          
          Widget productGrid = productsAsync.when(
            data: (data) {
              if (data.isEmpty) return const Center(child: Text('Belum ada produk. Klik +'));
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLandscape ? 3 : 2, 
                  childAspectRatio: 1.3, 
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
                          Text(data[i].name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(formatRupiah(data[i].sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );

          Widget cartSection = Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(cart[i].product.name),
                  subtitle: Text('${cart[i].qty} ${cart[i].unit} x ${formatAngka(cart[i].price)}'),
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
                Text('TOTAL: ${formatRupiah(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : () => _showBayarDialog(context, ref, total, user), 
                    child: const Text('BAYAR')
                  )
                ),
              ]),
            ),
          ]);

          return isLandscape 
              ? Row(children: [Expanded(flex: 3, child: productGrid), Expanded(flex: 2, child: cartSection)])
              : Column(children: [Expanded(flex: 4, child: productGrid), const Divider(height: 1), Expanded(flex: 3, child: cartSection)]);
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDummyProduct(ref), 
        child: const Icon(Icons.add)
      ),
    );
  }

  void _connectPrinter() async {
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pair printer dulu di setting HP')));
        return;
      }
      bool result = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
      if (mounted) setState(() => _isConnected = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Bluetooth: $e')));
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
  }

  void _showBayarDialog(BuildContext context, WidgetRef ref, double total, Map<String, dynamic> user) {
    final bayarController = TextEditingController(text: total.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bayar: ${formatRupiah(total)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bayarController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: 'Jumlah Bayar'),
              // KONTROL Akses 3: Jika dia Salesman DAN tidak diizinkan canEditPrice, kunci textfield input harga/bayar kustom
              enabled: user['role'] == 'owner' || user['canEditPrice'] == true,
            ),
            if (user['role'] == 'salesman' && user['canEditPrice'] == false)
              const Padding(
                padding: EdgeInsets.top(8.0),
                child: Text('*Nominal terkunci otomatis sesuai hak akses sales.', style: TextStyle(fontSize: 11, color: Colors.orange)),
              )
          ],
        ),
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

    final transactionId = await db.into(db.transactions).insert(TransactionsCompanion.insert(
      invoiceNo: invoiceNo,
      subtotal: total,
      total: total,
      paid: Value(bayar),
      debt: Value(total - bayar > 0 ? total - bayar : 0),
      paymentMethod: Value(method),
      change: Value(bayar > total ? bayar - total : 0),
    ));

    for (var item in cart) {
      await db.into(db.transactionItems).insert(TransactionItemsCompanion.insert(
        transactionId: transactionId,
        productId: item.product.id,
        quantity: item.qty,
        price: item.price,
        unit: item.unit,
      ));
    }

    if (_isConnected) {
      String struk = '   UD. PUTRA SURABAYA\n$invoiceNo\n------------------------\n';
      for (var item in cart) {
        struk += '${item.product.name}\n${item.qty} x ${formatAngka(item.price)} = ${formatRupiah(item.subtotal)}\n';
      }
      struk += '------------------------\nTOTAL: ${formatRupiah(total)}\nBAYAR: ${formatRupiah(bayar)}\n   Terima Kasih\n\n\n';
      await PrintBluetoothThermal.writeBytes(struk.codeUnits);
    }

    ref.read(cartProvider.notifier).clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi sukses')));
  }
}
