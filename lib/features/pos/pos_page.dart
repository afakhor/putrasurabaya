import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

import '../../core/utils/format_rupiah.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/database/local_database.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/services/sync_service.dart';
import '../../main.dart';
import 'pos_cart_provider.dart';
import 'pos_models.dart';

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
                        final local = snap.data!.map((e) => Product.fromDrift(e)).toList();
                        return _buildProductGrid(local, isLandscape, cartNotifier);
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
                              subtitle: Text('${_currencyFormatter.format(item.unitPrice)} x ${item.qty} ${item.unit}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currencyFormatter.format(item.subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                                    onPressed: () => cartNotifier.updateQty(index, item.qty - 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                    onPressed: () => cartNotifier.updateQty(index, item.qty + 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => cartNotifier.removeItem(index),
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
                            _currencyFormatter.format(cartState.grandTotal),
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
  Widget _buildProductGrid(List<Product> products, bool isLandscape, dynamic cartNotifier) {
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
            onTap: () => cartNotifier.addItem(product),
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
                        _currencyFormatter.format(product.sellPriceGeneral > 0 ? product.sellPriceGeneral : product.sellPrice),
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

  /// Dialog Form Pembayaran (Cash, QRIS, Tempo)
  void _showCheckoutModal(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);
    final cashController = TextEditingController(text: cartState.cashPaid > 0 ? cartState.cashPaid.toStringAsFixed(0) : '');
    final dpController = TextEditingController(text: cartState.dpAmount > 0 ? cartState.dpAmount.toStringAsFixed(0) : '');

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
                        Text('Total: ${_currencyFormatter.format(state.grandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A65A))),
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
                          cartNotifier.updatePaymentDetails(cashPaid: n);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: state.changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          state.changeAmount >= 0
                              ? 'Kembali: ${_currencyFormatter.format(state.changeAmount)}'
                              : 'Kurang: ${_currencyFormatter.format(state.changeAmount.abs())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: state.changeAmount >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],

                    // OPSI TEMPO / KREDIT
                    if (state.paymentMethod == 'tempo') ...[
                      ListTile(
                        title: Text(state.customer == null ? 'Pilih Customer (Wajib)' : 'Customer: ${state.customer!.name}'),
                        trailing: const Icon(Icons.person_add),
                        tileColor: Colors.amber[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () {
                          // Contoh Dummy set customer (Bisa dihubungkan ke Dialog / List Customer)
                          cartNotifier.setCustomer(const CustomerData(
                            id: 'CUST-001',
                            name: 'Pelanggan Umum',
                            status: 'aktif',
                          ));
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Uang Muka / DP (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final n = double.tryParse(val) ?? 0;
                          cartNotifier.updatePaymentDetails(dpAmount: n);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sisa Piutang: ${_currencyFormatter.format(state.remainingTempo)}',
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
                          try {
                            // Eksekusi Simpan Transaksi & Background Sync
                            final txId = await _prosesPenyimpanan(ref);
                            if (context.mounted && txId != null) {
                              Navigator.pop(context);
                              _cetakStrukAutomatis(ref, txId);
                              _showSuccessAndPrintDialog(context, txId);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal Checkout: $e'), backgroundColor: Colors.red),
                            );
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

  /// Eksekusi Penyimpanan Transaksi ke Local Drift & Sync Background
  Future<String?> _prosesPenyimpanan(WidgetRef ref) async {
    final cartState = ref.read(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);
    final txId = 'TX-${DateTime.now().millisecondsSinceEpoch}';
    final invoiceNo = 'PSB-${DateTime.now().millisecondsSinceEpoch}';

    final items = cartState.items.map((it) => TransactionItemsCompanion.insert(
      id: 'ITEM-$txId-${it.product.id}',
      transactionId: txId,
      productId: it.product.id,
      quantity: it.qty,
      price: it.unitPrice,
      unit: it.unit,
    )).toList();

    // 1. Simpan Offline-First ke Drift DB
    await ref.read(localDatabaseProvider).prosesTransaksiPenyimpanan(
      dataTransaksi: TransactionsCompanion.insert(
        id: txId,
        invoiceNo: invoiceNo,
        subtotal: cartState.subtotal,
        total: cartState.grandTotal,
        paid: Value(cartState.paymentMethod == 'cash' ? cartState.cashPaid : cartState.dpAmount),
        debt: Value(cartState.remainingTempo),
        change: Value(cartState.changeAmount > 0 ? cartState.changeAmount : 0),
        paymentMethod: Value(cartState.paymentMethod),
      ),
      itemTransaksi: items,
    );

    // 2. Trigger Sync ke Firestore di Background
    ref.read(syncServiceProvider).syncLocalToCloud();

    // 3. Clear Keranjang
    cartNotifier.clearCart();

    return txId;
  }

  /// Format & Kirim Perintah Cetak ke Thermal Printer
  Future<void> _cetakStrukAutomatis(WidgetRef ref, String txId) async {
    if (!_isConnected) return;
    final cartState = ref.read(posCartProvider);

    String s = '      UD. PUTRA SURABAYA\n';
    s += '--------------------------------\n';
    s += 'ID: $txId\n';
    s += 'Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n';
    s += '--------------------------------\n';

    for (var it in cartState.items) {
      s += '${it.product.name}\n';
      s += _baris(' ${it.qty.toStringAsFixed(0)} ${it.unit} x ${_currencyFormatter.format(it.unitPrice)}', _currencyFormatter.format(it.subtotal));
    }

    s += '--------------------------------\n';
    s += _baris('TOTAL:', _currencyFormatter.format(cartState.grandTotal));
    
    if (cartState.paymentMethod == 'cash') {
      s += _baris('BAYAR:', _currencyFormatter.format(cartState.cashPaid));
      s += _baris('KEMBALI:', _currencyFormatter.format(cartState.changeAmount));
    } else if (cartState.paymentMethod == 'tempo') {
      s += _baris('DP/UM:', _currencyFormatter.format(cartState.dpAmount));
      s += _baris('PIUTANG:', _currencyFormatter.format(cartState.remainingTempo));
    }

    s += '--------------------------------\n';
    s += '    Terima Kasih atas Kunjungan Anda\n\n\n';

    await PrintBluetoothThermal.writeBytes(s.codeUnits);
  }

  /// Dialog Sukses & Opsi Cetak Struk Manual
  void _showSuccessAndPrintDialog(BuildContext context, String txId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Color(0xFF00A65A), size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transaksi Berhasil Disimpan!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('No. Transaksi: $txId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk Lagi'),
            onPressed: () {
              _cetakStrukAutomatis(ref, txId);
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
