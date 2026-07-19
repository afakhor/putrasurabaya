import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_form_provider.dart'; // File state utuh milikmu

class FormProductPage extends ConsumerStatefulWidget {
  const FormProductPage({super.key});

  @override
  ConsumerState<FormProductPage> createState() => _FormProductPageState();
}

class _FormProductPageState extends ConsumerState<FormProductPage> {
  // Inisialisasi controller lokal untuk semua field teks di modelmu
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _warehouseCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  // Controller Finansial & Stok
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _tier1Ctrl = TextEditingController();
  final _tier2Ctrl = TextEditingController();
  final _tier3Ctrl = TextEditingController();
  final _baseStockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose(); _shortNameCtrl.dispose(); _barcodeCtrl.dispose();
    _descCtrl.dispose(); _brandCtrl.dispose(); _warehouseCtrl.dispose();
    _tagsCtrl.dispose(); _buyPriceCtrl.dispose(); _sellPriceCtrl.dispose();
    _tier1Ctrl.dispose(); _tier2Ctrl.dispose(); _tier3Ctrl.dispose();
    _baseStockCtrl.dispose(); _minStockCtrl.dispose();
    super.dispose();
  }

  // Dialog input Multi-Satuan (UnitConversionModel)
  void _showAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final convCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Satuan Bertingkat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Satuan (Dus/Karton)')),
              TextField(controller: convCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Isi Konversi (Pcs)')),
              TextField(controller: buyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli Satuan')),
              TextField(controller: sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual Satuan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && convCtrl.text.isNotEmpty) {
                ref.read(productFormProvider.notifier).addUnit(
                  UnitConversionModel(
                    id: 'UNIT-${DateTime.now().millisecondsSinceEpoch}',
                    unitName: nameCtrl.text,
                    conversion: int.tryParse(convCtrl.text) ?? 1,
                    buyPrice: double.tryParse(buyCtrl.text) ?? 0,
                    sellPrice: double.tryParse(sellCtrl.text) ?? 0,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  // Dialog input Matriks Varian (VariantMatrixModel)
  void _showAddVariantDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Varian Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Varian (Ukuran/Warna)')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual Varian')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(productFormProvider.notifier).addVariantAutoSku(
                  variantName: nameCtrl.text,
                  sellPrice: double.tryParse(priceCtrl.text) ?? 0,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jembatan Listener: Memastikan Sinkronisasi Saat "Load Contoh Data" / "ResetForm" Dipanggil
    ref.listen<ProductFormState>(productFormProvider, (prev, next) {
      if (next.name != _nameCtrl.text) _nameCtrl.text = next.name;
      if (next.shortName != _shortNameCtrl.text) _shortNameCtrl.text = next.shortName;
      if (next.barcode != _barcodeCtrl.text) _barcodeCtrl.text = next.barcode;
      if (next.description != _descCtrl.text) _descCtrl.text = next.description;
      if (next.brand != _brandCtrl.text) _brandCtrl.text = next.brand;
      if (next.warehouseLocation != _warehouseCtrl.text) _warehouseCtrl.text = next.warehouseLocation;
      if (next.tags != _tagsCtrl.text) _tagsCtrl.text = next.tags;

      // Sinkronisasi data angka/double ke String Controller
      _buyPriceCtrl.text = next.buyPrice == 0 ? '' : next.buyPrice.toStringAsFixed(0);
      _sellPriceCtrl.text = next.sellPriceGeneral == 0 ? '' : next.sellPriceGeneral.toStringAsFixed(0);
      _tier1Ctrl.text = next.sellPriceTier1 == 0 ? '' : next.sellPriceTier1.toStringAsFixed(0);
      _tier2Ctrl.text = next.sellPriceTier2 == 0 ? '' : next.sellPriceTier2.toStringAsFixed(0);
      _tier3Ctrl.text = next.sellPriceTier3 == 0 ? '' : next.sellPriceTier3.toStringAsFixed(0);
      _baseStockCtrl.text = next.baseStock == 0 ? '' : next.baseStock.toStringAsFixed(0);
      _minStockCtrl.text = next.minStock == 0 ? '' : next.minStock.toStringAsFixed(0);
    });

    // Watcher parsial untuk me-render perubahan list objek & metadata atas
    final formState = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Form SKU: ${formState.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber, size: 28),
            tooltip: 'Load Data Mock Toko Bangunan',
            onPressed: () => notifier.loadContohPerkakasBangunan(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ==========================================
          // DETAIL IDENTITAS BARANG
          // ==========================================
          const Text('1. Identitas Master Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Lengkap Produk', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(name: v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Deskripsi Produk', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(description: v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shortNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Cetak Struk', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(shortName: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(barcode: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand / Merk', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(brand: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _warehouseCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasi Rak Gudang', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(warehouseLocation: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(labelText: 'Tags Proyek (Pisahkan dengan koma)', border: OutlineInputBorder()),
            onChanged: (v) => notifier.updateFields(tags: v),
          ),
          
          const Divider(height: 32),

          // ==========================================
          // MANAJEMEN FINANSIAL & HARGA BERTINGKAT
          // ==========================================
          const Text('2. Struktur HPP & Harga Grosir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buyPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Beli (HPP)', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(buyPrice: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sellPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Jual Umum', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceGeneral: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Margin Keuntungan Eceran: ${formState.marginGeneralPercent.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tier1Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 1', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier1: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tier2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 2', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier2: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tier3Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Grosir Tier 3', prefixText: 'Rp ', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(sellPriceTier3: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // ==========================================
          // CONTROL UNIT STOK & MINIMUM
          // ==========================================
          const Text('3. Kontrol Batas Stok Pcs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _baseStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(baseStock: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Minimum Kritis', border: OutlineInputBorder()),
                  onChanged: (v) => notifier.updateFields(minStock: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // ==========================================
          // RENDER SUB-SATUAN (MULTI-UNITS)
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4. Konversi Multi-Satuan (${formState.multiUnits.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(onPressed: _showAddUnitDialog, icon: const Icon(Icons.add), label: const Text('Tambah Satuan')),
            ],
          ),
          ...formState.multiUnits.map((unit) => Card(
                child: ListTile(
                  title: Text('${unit.unitName} (1 ${unit.unitName} = ${unit.conversion} Pcs)'),
                  subtitle: Text('Modal: Rp ${unit.buyPrice.toStringAsFixed(0)} | Jual: Rp ${unit.sellPrice.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => notifier.removeUnit(unit.id),
                  ),
                ),
              )),

          const Divider(height: 32),

          // ==========================================
          // RENDER MATRIKS VARIAN (VARIANTS)
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5. Matriks Varian Barang (${formState.variantMatrix.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(onPressed: _showAddVariantDialog, icon: const Icon(Icons.add_box), label: const Text('Buat Varian')),
            ],
          ),
          ...formState.variantMatrix.map((varData) => Card(
                color: Colors.orange.withOpacity(0.04),
                child: ListTile(
                  leading: Text(varData.sku, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.orange)),
                  title: Text(varData.name),
                  subtitle: Text('Harga Jual Varian: Rp ${varData.sellPrice.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => notifier.removeVariant(varData.id),
                  ),
                ),
              )),

          const SizedBox(height: 40),

          // BUTTON SUBMIT SIMPAN KE DB
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A65A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formState.name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Nama master barang tidak boleh kosong!')),
                );
                return;
              }
              // Data siap dilempar ke Fungsi Repository Drift DB kamu kemarin
              Navigator.pop(context);
            },
            child: const Text('SIMPAN MASTER UTAMA BARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
