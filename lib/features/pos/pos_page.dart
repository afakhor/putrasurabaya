import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'dart:io';
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
  bool _isConnected = false;
  String? _printerMac;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    if (kIsWeb) return;
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (mounted) {
      setState(() => _isConnected = isConnected);
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
      floatingActionButton: kIsWeb? null : FloatingActionButton(
        onPressed: () => _addDummyProduct(ref),
        tooltip: 'Tambah Produk Dummy',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _connectPrinter() async {
    if (kIsWeb) return;
    List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
    if (devices.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pair printer dulu di Bluetooth HP')));
      return;
    }
    // Ambil printer pertama
    _printerMac = devices.first.macAdress;
    bool result = await PrintBluetoothThermal.connect(macPrinterAddress: _printerMac!);
    setState(() => _isConnected = result);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result? 'Printer ${devices.first.name} connected' : 'Gagal connect')));
    }
  }

  void _addDummyProduct(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.into(db.products).insert(ProductsCompanion.insert(
      name: 'Semen Gresik ${DateTime.now().second}',
      barcode: 'PSB${DateTime.now().millisecondsSinceEpoch}',
      sellPrice: 75000,
      buyPrice: 70000,
      unitBase: 'sak',
      stock: const Value(100),
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

    final invoiceNo = 'INV${DateTime.now().millisecondsSinceEpoch}';
    final transId = await db.into(db.transactions).insert(TransactionsCompanion.insert(
      invoiceNo: invoiceNo,
      subtotal: total,
      total: total,
      paid: bayar,
      debt: Value(debt > 0? debt : 0),
      paymentMethod: Value(method),
      change: Value(bayar > total? bayar - total : 0),
    ));

    for (var item in cart) {
      await db.into(db.transactionItems).insert(TransactionItemsCompanion.insert(
        transactionId: transId,
        productId: item.product.id,
        productName: item.product.name,
        unit: item.unit,
        qty: item.qty,
        price: item.price,
        subtotal: item.subtotal,
      ));
    }

    if (!kIsWeb && _isConnected) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text('UD. PUTRA SURABAYA', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text(invoiceNo, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      for (var item in cart) {
        bytes += generator.row([
          PosColumn(text: item.product.name, width: 8),
          PosColumn(text: formatRupiah(item.subtotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.text('${item.qty} ${item.unit} x ${formatAngka(item.price)}', styles: const PosStyles(align: PosAlign.left));
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: formatRupiah(total), width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'BAYAR', width: 6),
        PosColumn(text: formatRupiah(bayar), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'KEMBALI', width: 6),
        PosColumn(text: formatRupiah(bayar > total? bayar - total : 0), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (debt > 0) {
        bytes += generator.row([
          PosColumn(text: 'PIUTANG', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(text: formatRupiah(debt), width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.text('Terima Kasih', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(bytes);
    }

    ref.read(cartProvider.notifier).clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kIsWeb? 'Transaksi sukses (Preview Web)' : 'Transaksi sukses & struk dicetak')),
      );
    }
  }
}