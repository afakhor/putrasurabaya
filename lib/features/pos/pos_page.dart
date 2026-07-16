import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/app_database.dart';
import '../../core/utils/format_rupiah.dart';
import '../../main.dart';

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
  void removeProduct(int productId) => state = state.where((e) => e.product.id!= productId).toList();
  void clear() => state = [];
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

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

      @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    if (kIsWeb) return;
    try {
      // 1. Minta izin Bluetooth terlebih dahulu setelah halaman dirender
      await requestBluetoothPermissions();

      // 2. Baru cek status koneksi printer setelah izin diberikan/ditolak
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (mounted) setState(() => _isConnected = isConnected);
    } catch (e) {
      // biarin aja kalau gagal, jangan crash
      debugPrint('Bluetooth init error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir UD. Putra Surabaya'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(_isConnected? Icons.print : Icons.print_disabled, color: _isConnected? Colors.green : Colors.red),
              onPressed: _connectPrinter,
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<List<Product>>(
              future: db.getAllProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text('Belum ada produk. Klik +'));
                final data = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) => Card(
                    child: InkWell(
                      onTap: () => ref.read(cartProvider.notifier).addProduct(data[i]),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(data[i].name, textAlign: TextAlign.center, maxLines: 2),
                          Text(formatRupiah(data[i].sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                );
              },
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
                    trailing: Text(formatRupiah(cart[i].subtotal)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text('TOTAL: ${formatRupiah(total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: cart.isEmpty? null : () => _showBayarDialog(context, ref, total), child: const Text('BAYAR'))),
                ]),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: kIsWeb? null : FloatingActionButton(onPressed: () => _addDummyProduct(ref), child: const Icon(Icons.add)),
    );
  }

    void _connectPrinter() async {
    if (kIsWeb) return;
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pair printer dulu di setting Bluetooth HP')));
        }
        return;
      }
      bool result = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
      if (mounted) setState(() => _isConnected = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Bluetooth: $e')));
      }
      debugPrint('BT Error: $e');
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
    setState(() {});
  }

  void _showBayarDialog(BuildContext context, WidgetRef ref, double total) {
    final bayarController = TextEditingController(text: total.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bayar: ${formatRupiah(total)}'),
        content: TextField(controller: bayarController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Bayar')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final bayar = double.tryParse(bayarController.text)?? 0;
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
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
      invoiceNo: invoiceNo,
      subtotal: total,
      total: total,
      paid: Value(bayar),
      debt: Value(total - bayar > 0? total - bayar : 0),
      paymentMethod: Value(method),
      change: Value(bayar > total? bayar - total : 0),
    ));
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