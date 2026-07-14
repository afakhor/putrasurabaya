import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UD. Putra Surabaya',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ProductFormPage(),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();

  // Satuan default buat toko bangunan
  String _satuanDasar = 'pcs';
  final List<String> _listSatuan = [
    'pcs', 'sak', 'dus', 'kg', 'meter', 'liter', 'batang', 'lembar', 'rol', 'kaleng', 'set'
  ];

  void _simpanProduk() {
    if (_formKey.currentState!.validate()) {
      // Nanti disini simpan ke database SQLite
      final nama = _namaController.text;
      final hargaJual = double.parse(_hargaJualController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk $nama berhasil disimpan. Harga: Rp $hargaJual/$_satuanDasar')),
      );

      // Reset form
      _formKey.currentState!.reset();
      _namaController.clear();
      _hargaBeliController.clear();
      _hargaJualController.clear();
      _stokController.clear();
      setState(() => _satuanDasar = 'pcs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UD. Putra Surabaya - Input Produk'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Produk', hintText: 'Contoh: Semen Gresik 50kg'),
                validator: (val) => val!.isEmpty? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _satuanDasar,
                decoration: const InputDecoration(labelText: 'Satuan Dasar di Gudang'),
                items: _listSatuan.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _satuanDasar = newValue!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaBeliController,
                      decoration: const InputDecoration(labelText: 'Harga Beli'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hargaJualController,
                      decoration: const InputDecoration(labelText: 'Harga Jual Ecer'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(labelText: 'Stok Awal', suffixText: _satuanDasar),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _simpanProduk,
                icon: const Icon(Icons.save),
                label: const Text('SIMPAN PRODUK'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catatan: Setelah ini kita tambahin fitur "Satuan Jual Lain". Misal stok gudang = sak, tapi bisa dijual per kg.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
