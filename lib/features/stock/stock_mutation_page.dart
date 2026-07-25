// lib/features/stock/stock_mutation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/format_rupiah.dart';

class StockMutationPage extends ConsumerStatefulWidget {
  const StockMutationPage({super.key});

  @override
  ConsumerState<StockMutationPage> createState() => _StockMutationPageState();
}

class _StockMutationPageState extends ConsumerState<StockMutationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok & Inventory'),
        backgroundColor: const Color(0xFF007F00),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.download), text: 'Barang Masuk (Pembelian)'),
            Tab(icon: Icon(Icons.fact_check), text: 'Stok Opname (Audit)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BarangMasukForm(),
          _StokOpnameForm(),
        ],
      ),
    );
  }
}

/// TAB 1: FORM BARANG MASUK / PEMBELIAN SUPPLIER
class _BarangMasukForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BarangMasukForm> createState() => _BarangMasukFormState();
}

class _BarangMasukFormState extends ConsumerState<_BarangMasukForm> {
  ProductData? _selectedProduct;
  final _qtyCtrl = TextEditingController();
  final _hargaBeliCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Input Pembelian Barang dari Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          // Pilih Produk
          FutureBuilder<List<ProductData>>(
            future: db.getAllProducts(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return DropdownButtonFormField<ProductData>(
                value: _selectedProduct,
                decoration: const InputDecoration(labelText: 'Pilih Produk / Material', border: OutlineInputBorder()),
                items: snap.data!.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Stok Saat Ini: ${p.stock})'))).toList(),
                onChanged: (v) => setState(() {
                  _selectedProduct = v;
                  if (v != null) _hargaBeliCtrl.text = v.buyPrice.toInt().toString();
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'No. Nota Supplier / Ref', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Kuantitas Masuk', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _hargaBeliCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli Per Unit (Rp)', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          if (_selectedProduct != null) Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimasi HPP Moving Average:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  Text('HPP Lama: ${formatRupiah(_selectedProduct!.buyPrice)}'),
                  Text('Stok Lama: ${_selectedProduct!.stock}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
              onPressed: _prosesBarangMasuk,
              child: const Text('SIMPAN BARANG MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _prosesBarangMasuk() async {
    if (_selectedProduct == null || _qtyCtrl.text.isEmpty || _hargaBeliCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi seluruh data transaksi!')));
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final hargaBeli = double.tryParse(_hargaBeliCtrl.text) ?? 0;
    final refNo = _refCtrl.text.isEmpty ? 'NOT-${DateTime.now().millisecondsSinceEpoch}' : _refCtrl.text;

    await ref.read(localDatabaseProvider).catatMutasiStok(
      productId: _selectedProduct!.id,
      type: 'masuk',
      qty: qty,
      hargaBeliMasuk: hargaBeli,
      refNo: refNo,
      catatan: 'Barang masuk dari supplier. Ref: $refNo',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok & Moving Average HPP Berhasil Diperbarui!'), backgroundColor: Color(0xFF00A65A)));
      setState(() {
        _selectedProduct = null;
        _qtyCtrl.clear();
        _hargaBeliCtrl.clear();
        _refCtrl.clear();
      });
    }
  }
}

/// TAB 2: FORM STOK OPNAME AUDIT FISIK LAPANGAN
class _StokOpnameForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StokOpnameForm> createState() => _StokOpnameFormState();
}

class _StokOpnameFormState extends ConsumerState<_StokOpnameForm> {
  ProductData? _selectedProduct;
  final _stokFisikCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit Stok Fisik Lapangan vs Sistem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          FutureBuilder<List<ProductData>>(
            future: db.getAllProducts(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return DropdownButtonFormField<ProductData>(
                value: _selectedProduct,
                decoration: const InputDecoration(labelText: 'Pilih Produk Yang Diaudit', border: OutlineInputBorder()),
                items: snap.data!.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Sistem: ${p.stock})'))).toList(),
                onChanged: (v) => setState(() => _selectedProduct = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _stokFisikCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Stok Hasil Hitung Fisik Rak', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _catatanCtrl, decoration: const InputDecoration(labelText: 'Keterangan Selisih (Misal: Barang Pecah/Hilang)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
              onPressed: _eksekusiOpname,
              child: const Text('PROSES STOK OPNAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _eksekusiOpname() async {
    if (_selectedProduct == null || _stokFisikCtrl.text.isEmpty) return;

    final stokFisik = double.tryParse(_stokFisikCtrl.text) ?? 0;

    await ref.read(localDatabaseProvider).catatMutasiStok(
      productId: _selectedProduct!.id,
      type: 'opname',
      qty: stokFisik,
      hargaBeliMasuk: _selectedProduct!.buyPrice,
      refNo: 'OPN-${DateTime.now().millisecondsSinceEpoch}',
      catatan: _catatanCtrl.text.isEmpty ? 'Koreksi Stok Opname Fisik' : _catatanCtrl.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koreksi Stok Opname Berhasil Disimpan!'), backgroundColor: Colors.amber));
      setState(() {
        _selectedProduct = null;
        _stokFisikCtrl.clear();
        _catatanCtrl.clear();
      });
    }
  }
}
