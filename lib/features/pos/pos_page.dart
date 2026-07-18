import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk fungsi Clipboard & Formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; // Untuk format tanggal nota
import '../../core/utils/format_rupiah.dart';
import '../../core/utils/permission_helper.dart';
import '../../main.dart';
import '../product/product_page.dart'; 
import '../../core/database/app_database.dart'; // File database baru kita

// 1. MODEL ITEM KERANJANG
class CartItem {
  final Product product;
  final double qty;
  final String unit;
  final double price;

  CartItem({
    required this.product, 
    this.qty = 1, 
    required this.unit, 
    required this.price,
  });

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

// 2. STATE MANAGER KERANJANG BELANJA
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
      state = [...state, CartItem(product: p, unit: p.unitBase ?? 'pcs', price: p.sellPrice)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((e) => e.product.id != productId).toList();
  }

  void clear() => state = [];
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

// Catatan: 'productsStreamProvider' yang lama di sini sudah DIHAPUS 
// karena sekarang otomatis membaca dari lib/core/database/app_database.dart

// 4. HALAMAN UTAMA POS KASIR
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

  // Helper untuk meratakan teks kiri dan kanan pas 32 karakter struk thermal
  String _buatBarisStruk(String kiri, String kanan) {
    int sisaSpasi = 32 - (kiri.length + kanan.length);
    if (sisaSpasi < 1) sisaSpasi = 1;
    return '$kiri${' ' * sisaSpasi}$kanan\n';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;
    // productsAsync di bawah ini sekarang otomatis membaca provider dari app_database.dart
    final productsAsync = ref.watch(productsStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir UD. Putra Surabaya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF00A65A),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.print : Icons.print_disabled, 
              color: _isConnected ? Colors.white : Colors.red.shade200,
            ),
            onPressed: _connectPrinter,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLandscape = constraints.maxWidth > 600;

          Widget productGrid = productsAsync.when(
            data: (data) {
              if (data.isEmpty) return const Center(child: Text('Belum ada produk di cloud.'));
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLandscape ? 3 : 2, 
                  childAspectRatio: 1.3, 
                  crossAxisSpacing: 8, 
                  mainAxisSpacing: 8,
                ),
                itemCount: data.length,
                itemBuilder: (ctx, i) => Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () => ref.read(cartProvider.notifier).addProduct(data[i]),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Text(
                            data[i].name, 
                            textAlign: TextAlign.center, 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(data[i].sellPrice), 
                            style: const TextStyle(color: Color(0xFF00A65A), fontWeight: FontWeight.bold),
                          ),
                          Text('Stok: ${data[i].stock}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ]
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))),
            error: (error, stack) => Center(child: Text('Gagal Memuat: $error')),
          );

          Widget cartSection = Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Text(cart[i].product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${cart[i].qty.toStringAsFixed(0)} ${cart[i].unit} x ${formatRupiah(cart[i].price)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatRupiah(cart[i].subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Column(
                  children: [
                    Text('TOTAL: ${formatRupiah(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A65A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: cart.isEmpty ? null : () => _showBayarDialog(context, ref, total, user), 
                        child: const Text('PROSES BAYAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          return isLandscape 
              ? Row(children: [Expanded(flex: 3, child: productGrid), Expanded(flex: 2, child: cartSection)])
              : Column(children: [Expanded(flex: 4, child: productGrid), const Divider(height: 1), Expanded(flex: 3, child: cartSection)]);
        }
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A65A),
        onPressed: () => _addDummyProduct(), 
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _connectPrinter() async {
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pasangkan printer di pengaturan bluetooth HP')));
        return;
      }
      bool result = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
      if (mounted) setState(() => _isConnected = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tersambung printer: $e')));
    }
  }

  void _addDummyProduct() async {
    await FirebaseFirestore.instance.collection('products').add({
      'name': 'Semen Gresik ${DateTime.now().second}',
      'barcode': 'PSB${DateTime.now().millisecondsSinceEpoch}',
      'sellPrice': 75000.0,
      'buyPrice': 70000.0,
      'unitBase': 'sak',
      'stock': 100,
      'category': 'Material',
    });
  }

  // DIALOG PEMBAYARAN INTERAKTIF DENGAN AUTOMATIC TITIK RIBUAN
  void _showBayarDialog(BuildContext context, WidgetRef ref, double total, Map<String, dynamic>? user) {
    final String initialText = NumberFormat.decimalPattern('id_ID').format(total.toInt());
    final bayarController = TextEditingController(text: initialText);

    final bool canEditPrice = user != null && (user['role'] == 'owner' || user['canEditPrice'] == true);
    double kembalian = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {

          void hitungKembalianLokal(String teks) {
            final cleanStr = teks.replaceAll('.', '');
            final nominalBayar = double.tryParse(cleanStr) ?? 0;
            setDialogState(() {
              kembalian = nominalBayar - total;
            });
          }

          return AlertDialog(
            title: Text('Total Tagihan: ${formatRupiah(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: bayarController, 
                  keyboardType: TextInputType.number, 
                  onChanged: hitungKembalianLokal,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(), 
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Uang Bayar',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  enabled: canEditPrice,
                ),
                if (!canEditPrice)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '*Jumlah pembayaran terkunci otomatis sesuai otorisasi akun Anda.', 
                      style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kembalian >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kembalian >= 0 ? 'Kembalian: ${kembalian.toRupiah()}' : 'Kurang (Hutang): ${kembalian.abs().toRupiah()}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kembalian >= 0 ? Colors.green.shade800 : Colors.red.shade800),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
                onPressed: () {
                  final cleanText = bayarController.text.replaceAll('.', '');
                  final double uangBayar = double.tryParse(cleanText) ?? total;

                  _prosesTransaksi(ref, total, uangBayar, 'Cash', user);
                  Navigator.pop(ctx);
                },
                child: const Text('Proses & Cetak', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // PROSES TRANSAKSI SINKRON, PRINT BLUETOOTH & COPY STRUK WA
    // PROSES TRANSAKSI SINKRON, PRINT BLUETOOTH & COPY STRUK WA
  void _prosesTransaksi(WidgetRef ref, double total, double bayar, String method, Map<String, dynamic>? user) async {
    final cart = ref.read(cartProvider);
    final invoiceNo = 'PSB-${DateTime.now().millisecondsSinceEpoch}';
    final String tanggalNota = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))),
    );

    try {
      double sisaHutang = total - bayar > 0 ? total - bayar : 0;
      double uangKembali = bayar > total ? bayar - total : 0;

      // PANGGIL PROVIDER YANG BENAR: localDatabaseProvider (sesuai local_database.dart)
      await ref.read(localDatabaseProvider).prosesTransaksiPenyimpanan(
        invoiceNo: invoiceNo,
        total: total,
        bayar: bayar,
        sisaHutang: sisaHutang,
        uangKembali: uangKembali,
        method: method,
        kasirNama: user?['name'] ?? 'Kasir',
        cartItems: cart,
      );

      if (mounted) Navigator.pop(context); // Tutup dialog loading

      // =========================================================
      // 1. GENERATE LOGIKA STRUK FISIK (THERMAL BLUETOOTH 58MM)
      // =========================================================
      if (_isConnected) {
        String struk = '     UD. PUTRA SURABAYA\n';
        struk += '  Jl. Raya Surabaya - Tambak\n';
        struk += '--------------------------------\n';
        struk += 'No Nota : $invoiceNo\n';
        struk += 'Tanggal : $tanggalNota\n';
        struk += 'Kasir   : ${user?['name'] ?? 'Staff'}\n';
        struk += '--------------------------------\n';
        for (var item in cart) {
          struk += '${item.product.name}\n';
          String detailBaris = '  ${item.qty.toStringAsFixed(0)} ${item.unit} x ${formatRupiah(item.price)}';
          String totalBaris = formatRupiah(item.subtotal);
          struk += _buatBarisStruk(detailBaris, totalBaris);
        }
        struk += '--------------------------------\n';
        struk += _buatBarisStruk('TOTAL TAGIHAN :', formatRupiah(total));
        struk += _buatBarisStruk('TUNAI/BAYAR   :', formatRupiah(bayar));
        if (uangKembali > 0) {
          struk += _buatBarisStruk('KEMBALIAN     :', formatRupiah(uangKembali));
        }
        if (sisaHutang > 0) {
          struk += _buatBarisStruk('SISA BON/UTANG:', formatRupiah(sisaHutang));
        }
        struk += '--------------------------------\n';
        struk += '     Terima Kasih Atas\n';
        struk += '     Kepercayaan Anda :)\n\n\n';

        await PrintBluetoothThermal.writeBytes(struk.codeUnits);
      }

      // =========================================================
      // 2. GENERATE STRUK DIGITAL UNTUK WHATSAPP (SALIN OTOMATIS)
      // =========================================================
      String strukWa = '*📢 STRUK DIGITAL UD. PUTRA SURABAYA*\n';
      strukWa += '---------------------------------------------\n';
      strukWa += '*No. Nota :* $invoiceNo\n';
      strukWa += '*Tanggal :* $tanggalNota\n';
      strukWa += '*Kasir :* ${user?['name'] ?? 'Staff'}\n';
      strukWa += '---------------------------------------------\n\n';
      strukWa += '*Rincian Belanja:*\n';
      for (var item in cart) {
        strukWa += '▪️ ${item.product.name}\n';
        strukWa += '   ${item.qty.toStringAsFixed(0)} ${item.unit} x ${formatRupiah(item.price)} = *${formatRupiah(item.subtotal)}*\n';
      }
      strukWa += '---------------------------------------------\n';
      strukWa += '*TOTAL TAGIHAN : ${formatRupiah(total)}*\n';
      strukWa += '*DIBAYAR : ${formatRupiah(bayar)}*\n';
      if (uangKembali > 0) strukWa += '*KEMBALIAN : ${formatRupiah(uangKembali)}*\n';
      if (sisaHutang > 0) strukWa += '*SISA BON/HUTANG : ${formatRupiah(sisaHutang)}*\n';
      strukWa += '---------------------------------------------\n';
      strukWa += 'Semen & Bahan Bangunan Berkualitas.\n';
      strukWa += '_Maturnuwun atas kunjungan Anda!_ 😊';

      await Clipboard.setData(ClipboardData(text: strukWa));

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sukses! Struk fisik dicetak & format WhatsApp berhasil DISALIN otomatis.'),
            backgroundColor: Color(0xFF00A65A),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
