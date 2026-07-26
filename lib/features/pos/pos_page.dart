// lib/features/pos/pos_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

import '../../core/utils/permission_helper.dart';
import '../../core/database/local_database.dart';
import '../../main.dart'; // tempat productsStreamProvider dipublish
import 'pos_cart_provider.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _searchQuery = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Inisialisasi & Izin Bluetooth Thermal Printer
  Future<void> _initBluetooth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await PermissionHelper.requestBluetoothPermissions();
    bool c = await PrintBluetoothThermal.connectionStatus;
    if (mounted) {
      setState(() => _isConnected = c);
    }
  }

  /// Formatter teks rata kiri-kanan (32 Karakter per baris untuk Printer 58mm)
  String _baris(String kiri, String kanan) {
    int sp = 32 - (kiri.length + kanan.length);
    if (sp < 1) sp = 1;
    return '$kiri${' ' * sp}$kanan\n';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final db = ref.watch(localDatabaseProvider);
    
    // 1. Membaca State Keranjang dari posCartProvider
    final cartState = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir / POS - UD. Putra Surabaya'),
        actions: [
          Icon(
            _isConnected ? Icons.print : Icons.print_disabled,
            color: _isConnected ? Colors.greenAccent : Colors.white54,
            tooltip: _isConnected ? 'Printer Terhubung' : 'Printer Terputus',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cartNotifier.clearCart(),
            tooltip: 'Bersihkan Keranjang',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLandscape = constraints.maxWidth > 600;

          // GRID PRODUK & SEARCH BAR
          Widget productCatalog = Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari Produk / Scan Barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  data: (cloudData) {
                    if (cloudData.isNotEmpty) {
                      return _buildProductGrid(cloudData, isLandscape, cartNotifier);
                    }
                    // Fallback Offline: Ambil dari DB Drift Lokal
                    return StreamBuilder<List<ProductData>>(
                      stream: db.select(db.products).watch(),
                      builder: (ctx, snap) {
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return const Center(child: Text('Belum ada produk (offline)'));
                        }
                        return _buildProductGrid(snap.data!, isLandscape, cartNotifier);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A65A)),
                  ),
                  error: (e, _) => Center(child: Text('Error Data: $e')),
                ),
              ),
            ],
          );

          // PANEL KERANJANG BELANJA
          Widget cartSection = Container(
            color: Colors.grey[50],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blueGrey[800],
                  width: double.infinity,
                  child: Text(
                    'KERANJANG BELANJA (${cartState.items.length})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: cartState.items.isEmpty
                      ? const Center(child: Text('Keranjang masih kosong'))
                      : ListView.separated(
                          itemCount: cartState.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = cartState.items[index];
                            return ListTile(
                              title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${_currencyFormatter.format(item.price)} x ${item.quantity} ${item.unit}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currencyFormatter.format(item.subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                                    onPressed: () => cartNotifier.updateQuantity(item.product.id, item.quantity - 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                    // 2. Menambah Produk saat Item Ditekan
                                    onPressed: () => cartNotifier.addProduct(item.product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => cartNotifier.removeProduct(item.product.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 14)),
                          Text(_currencyFormatter.format(cartState.subtotal), style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL BAYAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            _currencyFormatter.format(cartState.total),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A65A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A65A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: cartState.items.isEmpty ? null : () => _showCheckoutModal(context, ref),
                          child: const Text('BAYAR / CHECKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // LAYOUT SPLIT (LANDSCAPE VS PORTRAIT)
          if (isLandscape) {
            return Row(
              children: [
                Expanded(flex: 6, child: productCatalog),
                const VerticalDivider(width: 1),
                Expanded(flex: 4, child: cartSection),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 5, child: productCatalog),
                const Divider(height: 1),
                Expanded(flex: 4, child: cartSection),
              ],
            );
          }
        },
      ),
    );
  }

  /// Widget Grid Katalog Produk
  Widget _buildProductGrid(List<ProductData> products, bool isLandscape, PosCartNotifier cartNotifier) {
    final filtered = products.where((p) {
      final nameMatch = p.name.toLowerCase().contains(_searchQuery);
      final barcodeMatch = p.barcode?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatch || barcodeMatch;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Produk tidak ditemukan'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 3 : 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final product = filtered[i];
        return Card(
          elevation: 2,
          child: InkWell(
            // 2. Menambah Produk saat Item Ditekan
            onTap: () => cartNotifier.addProduct(product),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currencyFormatter.format(product.sellPriceGeneral > 0 ? product.sellPriceGeneral : 0),
                        style: const TextStyle(color: Color(0xFF00A65A), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stok: ${product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.stock < 5 ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dialog Form Pembayaran (Tunai, QRIS, Tempo)
  void _showCheckoutModal(BuildContext context, WidgetRef ref) {
    final cartState = ref.read(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);
    
    final cashController = TextEditingController(
      text: cartState.paidAmount > 0 ? cartState.paidAmount.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(posCartProvider);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Total: ${_currencyFormatter.format(state.total)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A65A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cash', label: Text('Tunai')),
                        ButtonSegment(value: 'qris', label: Text('QRIS')),
                        ButtonSegment(value: 'tempo', label: Text('Tempo')),
                      ],
                      selected: {state.paymentMethod},
                      onSelectionChanged: (set) => cartNotifier.setPaymentMethod(set.first),
                    ),
                    const SizedBox(height: 16),

                    // OPSI TUNAI
                    if (state.paymentMethod == 'cash') ...[
                      TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Uang Diterima (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final n = double.tryParse(val) ?? 0;
                          // 3. Mengubah Nominal Pembayaran
                          cartNotifier.setPaidAmount(n);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: state.paidAmount >= state.total ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          state.paidAmount >= state.total
                              ? 'Kembali: ${_currencyFormatter.format(state.change)}'
                              : 'Kurang: ${_currencyFormatter.format(state.total - state.paidAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: state.paidAmount >= state.total ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],

                    // OPSI TEMPO / KREDIT
                    if (state.paymentMethod == 'tempo') ...[
                      ListTile(
                        title: Text(
                          state.selectedCustomer == null 
                              ? 'Pilih Customer (Wajib)' 
                              : 'Customer: ${state.selectedCustomer!.name}'
                        ),
                        trailing: const Icon(Icons.person_add),
                        tileColor: Colors.amber[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () {
                          // Dummy set customer (Dapat dihubungkan dengan dialog/list customer)
                          cartNotifier.setCustomer(const CustomerData(
                            id: 'CUST-001',
                            name: 'Pelanggan Umum',
                            status: 'aktif',
                          ));
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Uang Muka / DP (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final n = double.tryParse(val) ?? 0;
                          // 3. Mengubah Nominal Pembayaran
                          cartNotifier.setPaidAmount(n);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sisa Piutang: ${_currencyFormatter.format(state.debt)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A65A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          // Simpan Snapshot state keranjang untuk dicetak
                          final snapshotCart = state;

                          // 4. Memproses Tombol Bayar / Checkout via PosCartNotifier
                          final success = await ref.read(posCartProvider.notifier).checkout(
                            salesId: 'SALES-01',
                            shiftId: 'SHIFT-01',
                          );

                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context);
                              _cetakStrukAutomatis(snapshotCart);
                              _showSuccessAndPrintDialog(context, snapshotCart);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal melakukan checkout transaksi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('PROSES & SIMPAN TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Format & Kirim Perintah Cetak ke Thermal Printer
  Future<void> _cetakStrukAutomatis(PosCartState cartSnapshot) async {
    if (!_isConnected || cartSnapshot.items.isEmpty) return;

    String s = '      UD. PUTRA SURABAYA\n';
    s += '--------------------------------\n';
    s += 'Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n';
    s += '--------------------------------\n';

    for (var it in cartSnapshot.items) {
      s += '${it.product.name}\n';
      s += _baris(' ${it.quantity.toStringAsFixed(0)} ${it.unit} x ${_currencyFormatter.format(it.price)}', _currencyFormatter.format(it.subtotal));
    }

    s += '--------------------------------\n';
    s += _baris('TOTAL:', _currencyFormatter.format(cartSnapshot.total));

    if (cartSnapshot.paymentMethod == 'cash') {
      s += _baris('BAYAR:', _currencyFormatter.format(cartSnapshot.paidAmount));
      s += _baris('KEMBALI:', _currencyFormatter.format(cartSnapshot.change));
    } else if (cartSnapshot.paymentMethod == 'tempo') {
      s += _baris('DP/UM:', _currencyFormatter.format(cartSnapshot.paidAmount));
      s += _baris('PIUTANG:', _currencyFormatter.format(cartSnapshot.debt));
    }

    s += '--------------------------------\n';
    s += '    Terima Kasih atas Kunjungan Anda\n\n\n';

    await PrintBluetoothThermal.writeBytes(s.codeUnits);
  }

  /// Dialog Sukses & Opsi Cetak Struk Manual
  void _showSuccessAndPrintDialog(BuildContext context, PosCartState cartSnapshot) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Color(0xFF00A65A), size: 60),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transaksi Berhasil Disimpan!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text('Data tersimpan secara offline & siap disinkronkan ke cloud.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk Lagi'),
            onPressed: () {
              _cetakStrukAutomatis(cartSnapshot);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mengirim perintah ke printer thermal...')),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
