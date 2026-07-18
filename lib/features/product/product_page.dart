import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import utilitas terpadu yang baru saja digabungkan
import '../../utils/format_rupiah.dart'; 

// Properti tema warna konstan kasir putra sby
const Color primaryColor = Color(0xFF00A65A); 

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Contoh mengambil data real-time langsung dari Firestore
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Terjadi kesalahan data.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada produk. Klik tombol + untuk menambah.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['name'] ?? '-';
              final double stock = (data['stock'] ?? 0).toDouble();
              final double buyPrice = (data['buyPrice'] ?? 0).toDouble();
              final double sellPrice = (data['sellPrice'] ?? 0).toDouble();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Stok: $stock | Modal: ${buyPrice.toRupiah()}'), // <-- Penggunaan Extension .toRupiah()
                  ],
                ),
                trailing: Text(
                  sellPrice.toRupiah(), // <-- Penggunaan Extension .toRupiah()
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tampilkan form dialog input produk baru
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const _ProductFormDialog(),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// ==================================================
/// KASUR KUSTOM: DIALOG FORM INPUT PRODUK BARU
/// ==================================================
class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog();

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Fungsi krusial untuk membersihkan tanda titik ribuan sebelum masuk ke database
  double _parseRawPrice(String formattedPrice) {
    if (formattedPrice.isEmpty) return 0;
    final cleanString = formattedPrice.replaceAll('.', ''); 
    return double.tryParse(cleanString) ?? 0;
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String nama = _nameController.text.trim();
      final double stok = double.tryParse(_stockController.text) ?? 0;
      
      // Ambil nilai numerik bersih yang sudah di-parse dari format rupiah teks inputan
      final double hargaBeli = _parseRawPrice(_buyPriceController.text);
      final double hargaJual = _parseRawPrice(_sellPriceController.text);

      // Simpan langsung ke Firebase Cloud Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': nama,
        'stock': stok,
        'buyPrice': hargaBeli,
        'sellPrice': hargaJual,
        'unitBase': 'pcs',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil disimpan!'), backgroundColor: primaryColor),
        );
        Navigator.pop(context); // Tutup dialog form jika berhasil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Produk Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              // 1. FORM INPUT NAMA
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 2. FORM INPUT STOK AWAL
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], // Izinkan desimal untuk stok
                validator: (val) => val == null || val.isEmpty ? 'Stok awal wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 3. FORM INPUT HARGA BELI MODAL
              TextFormField(
                controller: _buyPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, 
                  RupiahInputFormatter(), // <-- Menggunakan formatter otomatis titik saat diketik
                ],
                decoration: const InputDecoration(
                  labelText: 'Harga Beli (Modal)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Harga modal wajib diisi';
                  if (_parseRawPrice(val) <= 0) return 'Harga harus di atas Rp 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. FORM INPUT HARGA JUAL TOKO
              TextFormField(
                controller: _sellPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, 
                  RupiahInputFormatter(), // <-- Menggunakan formatter otomatis titik saat diketik
                ],
                decoration: const InputDecoration(
                  labelText: 'Harga Jual',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Harga jual wajib diisi';
                  
                  final modal = _parseRawPrice(_buyPriceController.text);
                  final jual = _parseRawPrice(val);
                  
                  if (jual < modal) {
                    return 'Peringatan: Harga jual di bawah modal toko!'; // Validasi silang cerdas
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitData,
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
