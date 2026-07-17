import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==========================================
// 1. DATA MODEL (PRODUK & VARIAN)
// ==========================================
class ProductVariant {
  String name;
  double costPrice;
  double sellPrice;
  int stock;

  ProductVariant({
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.stock,
  });
}

class Product {
  final String id;
  final String name;
  final String category;
  final double costPrice;
  final double sellPrice;
  final String? barcode;
  final int stock;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellPrice,
    this.barcode,
    required this.stock,
    required this.variants,
  });

  Product copyWith({
    String? name,
    String? category,
    double? costPrice,
    double? sellPrice,
    String? barcode,
    int? stock,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      barcode: barcode ?? this.barcode,
      stock: stock ?? this.stock,
      variants: variants ?? this.variants,
    );
  }
}

// ==========================================
// 2. STATE MANAGEMENT (RIVERPOD)
// ==========================================
class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([
    // Contoh Data Awal
    Product(
      id: '1',
      name: 'Semen Gresik 50kg',
      category: 'Semen',
      costPrice: 60000,
      sellPrice: 68000,
      barcode: '899123456789',
      stock: 120,
      variants: [
        ProductVariant(name: 'Eceran per Kg', costPrice: 1500, sellPrice: 2000, stock: 50),
        ProductVariant(name: 'Grosir (Min 10 Sak)', costPrice: 59000, sellPrice: 65000, stock: 70),
      ],
    ),
  ]);

  void addProduct(Product product) {
    state = [...state, product];
  }

  void updateProduct(Product updatedProduct) {
    state = [
      for (final p in state)
        if (p.id == updatedProduct.id) updatedProduct else p
    ];
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier();
});

// Provider Filter & Search
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'Semua Kategori');

// ==========================================
// 3. UI SCREEN - DAFTAR PRODUK
// ==========================================
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Filter Logic
    final filteredProducts = products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (product.barcode != null && product.barcode!.contains(searchQuery));
      final matchesCategory = selectedCategory == 'Semua Kategori' || product.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Header & Tab Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DATA PRODUK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A65A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddEditProductForm()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('TAMBAH'),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Search & Barcode Scan Bar
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.grey[300]),
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      onPressed: () {
                        // Mockup Barcode scan
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka Kamera Barcode Scanner...')),
                        );
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Dropdown Kategori
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: ['Semua Kategori', 'Semen', 'Besi', 'Pasir', 'Lainnya']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) ref.read(selectedCategoryProvider.notifier).state = val;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List Produk Cards
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan.'))
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image Mockup
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.image, size: 40, color: Colors.blue[300]),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info Ringkas
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Pokok: Rp ${product.costPrice.toStringAsFixed(0)}'),
                                            Text(
                                              'Jual : Rp ${product.sellPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              product.stock > 0 ? 'Stok: ${product.stock}' : 'Tanpa Stok',
                                              style: TextStyle(color: product.stock > 0 ? Colors.black54 : Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Tampilan Varian jika ada
                                  if (product.variants.isNotEmpty) ...[
                                    const Divider(),
                                    const Text(
                                      'Varian Harga Jual:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: product.variants.map((v) {
                                        return Chip(
                                          labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                          backgroundColor: Colors.grey[100],
                                          label: Text(
                                            '${v.name} (Rp ${v.sellPrice.toStringAsFixed(0)})',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const Divider(),
                                  // Tombol Aksi Bawah Card
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AddEditProductForm(product: product),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              ref.read(productProvider.notifier).deleteProduct(product.id);
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              side: const BorderSide(color: Colors.green),
                                            ),
                                            onPressed: () {},
                                            child: const Text('Histori Jual', style: TextStyle(color: Colors.green, fontSize: 12)),
                                          ),
                                          const SizedBox(width: 4),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            onPressed: () {},
                                            child: const Text('Kelola Stok', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. UI FORM - TAMBAH / EDIT PRODUK + VARIAN
// ==========================================
class AddEditProductForm extends ConsumerStatefulWidget {
  final Product? product;
  const AddEditProductForm({super.key, this.product});

  @override
  ConsumerState<AddEditProductForm> createState() => _AddEditProductFormState();
}

class _AddEditProductFormState extends ConsumerState<AddEditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _sellCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _stockCtrl;
  String _selectedCategory = 'Lainnya';

  // List Dinamis Penampung Varian Baru
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _costCtrl = TextEditingController(text: p?.costPrice.toString() ?? '');
    _sellCtrl = TextEditingController(text: p?.sellPrice.toString() ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _selectedCategory = p?.category ?? 'Lainnya';
    _variants = p != null ? List.from(p.variants) : [];
  }

  void _addNewVariant() {
    setState(() {
      _variants.add(ProductVariant(name: '', costPrice: 0, sellPrice: 0, stock: 0));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProd = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text,
        category: _selectedCategory,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        sellPrice: double.tryParse(_sellCtrl.text) ?? 0,
        barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        variants: _variants,
      );

      if (widget.product == null) {
        ref.read(productProvider.notifier).addProduct(newProd);
      } else {
        ref.read(productProvider.notifier).updateProduct(newProd);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'TAMBAH PRODUK' : 'EDIT PRODUK'),
        backgroundColor: const Color(0xFF00A65A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama Produk
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Produk *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori Produk', border: OutlineInputBorder()),
              items: ['Semen', 'Besi', 'Pasir', 'Lainnya']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),

            // Barcode
            TextFormField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(
                labelText: 'Kode Produk (Barcode)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 12),

            // Harga Pokok & Harga Jual Utama
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Pokok (Rp) *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Jual (Rp) *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Jumlah Stok Utama
            TextFormField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Stok Utama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // BAGIAN SEKSI VARIAN DINAMIS
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VARIAN HARGA JUAL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                TextButton.icon(
                  onPressed: _addNewVariant,
                  icon: const Icon(Icons.add, color: Color(0xFF00A65A)),
                  label: const Text('Tambah Varian', style: TextStyle(color: Color(0xFF00A65A))),
                )
              ],
            ),
            const Divider(),

            _variants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Tidak ada varian. Klik Tambah Varian jika ada perbedaan ukuran/kemasan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _variants.length,
                    itemBuilder: (context, idx) {
                      return Card(
                        color: Colors.amber[50],
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () => _removeVariant(idx),
                              ),
                              TextFormField(
                                initialValue: _variants[idx].name,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Varian (Contoh: Per Sak, Per Meter)',
                                  backgroundColor: Colors.white,
                                  filled: true,
                                ),
                                onChanged: (val) => _variants[idx].name = val,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variants[idx].costPrice.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Hrg Pokok', backgroundColor: Colors.white, filled: true),
                                      onChanged: (val) => _variants[idx].costPrice = double.tryParse(val) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variants[idx].sellPrice.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Hrg Jual', backgroundColor: Colors.white, filled: true),
                                      onChanged: (val) => _variants[idx].sellPrice = double.tryParse(val) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variants[idx].stock.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Stok', backgroundColor: Colors.white, filled: true),
                                      onChanged: (val) => _variants[idx].stock = int.tryParse(val) ?? 0,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A65A),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _saveProduct,
              child: const Text('SIMPAN PRODUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
