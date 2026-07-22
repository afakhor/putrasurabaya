import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';
import '../../core/utils/format_rupiah.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/database/local_database.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/services/sync_service.dart';
import '../../main.dart';
import 'pos_models.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);
  void addProduct(Product p) {
    final i = state.indexWhere((e) => e.product.id == p.id);
    if (i >= 0) {
      state = [for (int j = 0; j < state.length; j++) if (j == i) state[j].copyWith(qty: state[j].qty + 1) else state[j]];
    } else {
      state = [...state, CartItem(product: p, unit: p.unitBase, price: p.sellPrice)];
    }
  }
  void removeProduct(String id) => state = state.where((e) => e.product.id!= id).toList();
  void clear() => state = [];
  double get total => state.fold(0, (s, e) => s + e.subtotal);
}
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

class POSPage extends ConsumerStatefulWidget {
  const POSPage({super.key});
  @override ConsumerState<POSPage> createState() => _POSPageState();
}

class _POSPageState extends ConsumerState<POSPage> {
  bool _isConnected = false;
  @override void initState() { super.initState(); _initBluetooth(); }
  void _initBluetooth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await PermissionHelper.requestBluetoothPermissions();
    bool c = await PrintBluetoothThermal.connectionStatus;
    if (mounted) setState(() => _isConnected = c);
  }
  String _baris(String kiri, String kanan) {
    int sp = 32 - (kiri.length + kanan.length);
    if (sp < 1) sp = 1;
    return '$kiri${' ' * sp}$kanan\n';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;
    final user = ref.watch(currentUserProvider);
    // Gabung: Cloud dulu, kalau offline fallback ke Drift lokal
    final productsAsync = ref.watch(productsStreamProvider);
    final db = ref.watch(localDatabaseProvider);

    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        bool land = c.maxWidth > 600;
        Widget grid = productsAsync.when(
          data: (cloudData) {
            if (cloudData.isNotEmpty) {
              return _buildGrid(cloudData, land);
            }
            // Fallback offline: baca dari Drift
            return StreamBuilder<List<ProductData>>(
              stream: db.select(db.products).watch(),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.isEmpty) return const Center(child: Text('Belum ada produk (offline)'));
                final local = snap.data!.map((e) => Product.fromDrift(e)).toList();
                return _buildGrid(local, land);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00A65A))),
          error: (e, _) => Center(child: Text('Error: $e')),
        );

        Widget cartSection = Column(children: [
          Expanded(child: ListView.builder(itemCount: cart.length, itemBuilder: (ctx, i) => ListTile(
            title: Text(cart[i].product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('${cart[i].qty.toStringAsFixed(0)} ${cart[i].unit} x ${formatRupiah(cart[i].price)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(formatRupiah(cart[i].subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => ref.read(cartProvider.notifier).removeProduct(cart[i].product.id))
            ]),
          ))),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text('TOTAL: ${formatRupiah(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: cart.isEmpty? null : () => _showBayar(context, ref, total, user),
              child: const Text('PROSES BAYAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ))
          ])),
        ]);
        return land? Row(children: [Expanded(flex: 3, child: grid), Expanded(flex: 2, child: cartSection)]) : Column(children: [Expanded(flex: 4, child: grid), const Divider(height: 1), Expanded(flex: 3, child: cartSection)]);
      }),
    );
  }

  Widget _buildGrid(List<Product> data, bool land) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: land? 3 : 2, childAspectRatio: 1.3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: data.length,
      itemBuilder: (ctx, i) => Card(child: InkWell(onTap: () => ref.read(cartProvider.notifier).addProduct(data[i]), child: Padding(padding: const EdgeInsets.all(8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(data[i].name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(formatRupiah(data[i].sellPrice), style: const TextStyle(color: Color(0xFF00A65A), fontWeight: FontWeight.bold, fontSize: 12)), Text('Stok: ${data[i].stock}', style: TextStyle(fontSize: 10, color: Colors.grey[600]))])))),
    );
  }

  void _showBayar(BuildContext context, WidgetRef ref, double total, Map<String, dynamic>? user) {
    final bayarCtrl = TextEditingController(text: NumberFormat.decimalPattern('id_ID').format(total.toInt()));
    double kembali = 0;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (context, setS) {
      return AlertDialog(
        title: Text('Total: ${formatRupiah(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: bayarCtrl, keyboardType: TextInputType.number, autofocus: true, onChanged: (t) { final n = double.tryParse(t.replaceAll('.', ''))?? 0; setS(() => kembali = n - total); }, inputFormatters: [FilteringTextInputFormatter.digitsOnly, RupiahInputFormatter()], decoration: const InputDecoration(labelText: 'Bayar', prefixText: 'Rp ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kembali >= 0? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)), child: Text(kembali >= 0? 'Kembali: ${formatRupiah(kembali)}' : 'Piutang: ${formatRupiah(kembali.abs())}', style: TextStyle(fontWeight: FontWeight.bold, color: kembali >= 0? Colors.green.shade800 : Colors.red.shade800))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () { final b = double.tryParse(bayarCtrl.text.replaceAll('.', ''))?? total; _proses(ref, total, b, 'Cash', user); Navigator.pop(ctx); }, child: const Text('Proses & Cetak', style: TextStyle(color: Colors.white)))],
      );
    }));
  }

  void _proses(WidgetRef ref, double total, double bayar, String method, Map<String, dynamic>? user) async {
    final cart = ref.read(cartProvider);
    final invoiceNo = 'PSB-${DateTime.now().millisecondsSinceEpoch}';
    try {
      double hutang = total - bayar > 0? total - bayar : 0;
      double kembali = bayar > total? bayar - total : 0;
      final txId = 'TX-${DateTime.now().millisecondsSinceEpoch}';
      final items = cart.map((it) => TransactionItemsCompanion.insert(id: 'ITEM-$txId-${it.product.id}', transactionId: txId, productId: it.product.id, quantity: it.qty, price: it.price, unit: it.unit)).toList();

      // PENTING: Selalu simpan ke Drift dulu (Offline-First)
      await ref.read(localDatabaseProvider).prosesTransaksiPenyimpanan(
        dataTransaksi: TransactionsCompanion.insert(id: txId, invoiceNo: invoiceNo, subtotal: total, total: total, paid: Value(bayar), debt: Value(hutang), change: Value(kembali), paymentMethod: Value(method)),
        itemTransaksi: items,
      );

      // Sync background, jangan await
      ref.read(syncServiceProvider).syncLocalToCloud();

      if (_isConnected) {
        String s = ' UD. PUTRA SURABAYA\n--------------------------------\nNo: $invoiceNo\n--------------------------------\n';
        for (var it in cart) { s += '${it.product.name}\n'; s += _baris(' ${it.qty.toStringAsFixed(0)} ${it.unit} x ${formatRupiah(it.price)}', formatRupiah(it.subtotal)); }
        s += '--------------------------------\n'; s += _baris('TOTAL:', formatRupiah(total)); s += _baris('BAYAR:', formatRupiah(bayar)); if (kembali > 0) s += _baris('KEMBALI:', formatRupiah(kembali)); if (hutang > 0) s += _baris('PIUTANG:', formatRupiah(hutang)); s += '\n\n\n';
        await PrintBluetoothThermal.writeBytes(s.codeUnits);
      }

      ref.read(cartProvider.notifier).clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hutang > 0? 'Transaksi + Piutang ${formatRupiah(hutang)} tersimpan!' : 'Transaksi Berhasil'), backgroundColor: const Color(0xFF00A65A)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }
}