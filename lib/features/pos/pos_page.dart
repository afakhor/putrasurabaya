import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // untuk kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  void removeProduct(int productId) {
    state = state.where((e) => e.product.id!= productId).toList();
  }

  void updateQty(int productId, double newQty) {
    if (newQty <= 0) {
      removeProduct(productId);
      return;
    }
    final index = state.indexWhere((e) => e.product.id == productId);
    if (index >= 0) {
      state[index].qty = newQty;
      state = [...state];
    }
  }

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
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    if (kIsWeb) return; // Skip bluetooth di web
    bool? isConnected = await bluetooth.isConnected;
    setState(() => _isConnected = isConnected?? false);
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
          // Status Printer - Hidden di Web
          if (!kIsWeb)
            IconButton(
              icon: Icon(_isConnected? Icons.print : Icons.print_disabled, color: _isConnected? Colors.green : Colors.red),
              onPressed: _connectPrinter,
              tooltip: _isConnected? 'Printer Connected' : 'Connect Printer',
            ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Chip(label: Text('WEB PREVIEW'), backgroundColor: Colors.orange),
            ),
        ],
      ),
      body: Row(
        children: [
          // Kiri: List Produk
          Expanded(
            flex: 3,
            child: FutureBuilder<List<Product>>(
              future: db.getAllProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada produk.\nKlik + untuk tambah dummy.'));
                }
                final data = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600? 4 : 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                            Text('Stok: ${formatAngka(data[i].stock)} ${data[i].unitBase}', style: const TextStyle(fontSize: 12)),
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
                    child: cart.isEmpty
                       ? const Center(child: Text('Keranjang kosong'))
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (ctx, i) => Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                dense: true,
                                title: Text(cart[i].product.name, style: const TextStyle(fontSize: 14)),
                                subtitle: Text('${cart[i].qty} ${cart[i].unit} x ${formatAngka(cart[i].price)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(formatRupiah(cart[i].subtotal)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => ref.read(cartProvider.notifier).removeProduct(cart[i].product.id),
                                    ),
                                  ],
                                ),
                              ),
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
                            onPressed: cart.isEmpty? null : () => _showBayarDialog(context, ref, total),
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
      floatingActionButton: kIsWeb ? null : FloatingActionButton(
  onPressed: () {
    _addDummyProduct(ref);
  },
  tooltip: 'Tambah Produk Dummy',
  child: const Icon(Icons.add),
),

  void _connectPrinter() async {
    if (kIsWeb) return;
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    if (devices.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pair printer dulu di Bluetooth HP')));
      return;
    }
    // Pilih device pertama aja buat simple
    await bluetooth.connect(devices.first);
    bool? isConnected = await bluetooth.isConnected;
    setState(() => _isConnected = isConnected?? false);
  }

  void _addDummyProduct(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.into(db.products).insert(ProductsCompanion.insert(
      name: 'Semen Gresik ${DateTime.now().second}',
      barcode: 'PSB${DateTime.now().millisecondsSinceEpoch}',
      sellPrice: 75000,
      buyPrice: 70000,
      unitBase: 'sak',
      stock: 100,
    ));
    ref.invalidate(databaseProvider);
  }

  void _showBayarDialog(BuildContext context, WidgetRef ref, double total) {
    final bayarController = TextEditingController(text: total.toStringAsFixed(0));
    String paymentMethod = 'Cash';
    File? ktpFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Bayar: ${formatRupiah(total)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bayarController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Bayar', prefixText: 'Rp '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Metode Bayar'),
                  items: ['Cash', 'Transfer', 'Piutang'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => paymentMethod = val!),
                ),
                if (paymentMethod == 'Piutang' &&!kIsWeb)...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.camera);
                      if (img!= null) setState(() => ktpFile = File(img.path));
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(ktpFile == null? 'Foto KTP' : 'KTP OK'),
                  ),
                ],
                if (kIsWeb && paymentMethod == 'Piutang')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Foto KTP hanya di APK', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final bayar = double.tryParse(bayarController.text)?? 0;
                if (paymentMethod == 'Piutang' &&!kIsWeb && ktpFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto KTP wajib untuk piutang')));
                  return;
                }
                _prosesTransaksi(ref, total, bayar, paymentMethod);
                Navigator.pop(ctx);
              },
              child: const Text('Proses'),
            ),
          ],
        ),
      ),
    );
  }

  void _prosesTransaksi(WidgetRef ref, double total, double bayar, String method) async {
    final db = ref.read(databaseProvider);
    final cart = ref.read(cartProvider);
    final debt = total - bayar;

    // Simpan transaksi
    final invoiceNo = 'INV${DateTime.now().millisecondsSinceEpoch}';
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      invoiceNo: invoiceNo,
      total: total,
      paid: bayar,
      debt: debt > 0? debt : 0,
      paymentMethod: Value(method),
    ));

    // Print struk kalau bukan web & ada koneksi
    if (!kIsWeb && _isConnected) {
      bluetooth.printNewLine();
      bluetooth.printCustom('UD. PUTRA SURABAYA', 3, 1);
      bluetooth.printCustom(invoiceNo, 1, 1);
      bluetooth.printNewLine();
      for (var item in cart) {
        bluetooth.printLeftRight('${item.product.name}', formatRupiah(item.subtotal), 0);
        bluetooth.printCustom('${item.qty} ${item.unit} x ${formatAngka(item.price)}', 0, 0);
      }
      bluetooth.printNewLine();
      bluetooth.printLeftRight('TOTAL', formatRupiah(total), 1);
      bluetooth.printLeftRight('BAYAR', formatRupiah(bayar), 1);
      bluetooth.printLeftRight('KEMBALI', formatRupiah(bayar - total), 1);
      if (debt > 0) bluetooth.printLeftRight('PIUTANG', formatRupiah(debt), 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('Terima Kasih', 1, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();
    }

    ref.read(cartProvider.notifier).clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kIsWeb? 'Transaksi sukses (Preview Web)' : 'Transaksi sukses & struk dicetak')),
      );
    }
  }
}