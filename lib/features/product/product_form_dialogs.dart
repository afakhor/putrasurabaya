import 'package:flutter/material.dart';

class ProductFormDialogs {
  /// Dialog Cepat Input Teks (Kategori, Brand, Satuan, Rak)
  static Future<String?> showQuickTextDialog({
    required BuildContext context,
    required String title,
    required String labelField,
  }) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelField,
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A65A))),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Form wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Dialog Multi-Satuan Grosir & Konversi
  static Future<Map<String, dynamic>?> showUnitConversionDialog({
    required BuildContext context,
    required double baseBuyPrice,
    required double baseSellPrice,
  }) {
    final unitController = TextEditingController();
    final qtyController = TextEditingController(text: '12');
    final buyController = TextEditingController(text: (baseBuyPrice * 12).toStringAsFixed(0));
    final sellController = TextEditingController(text: (baseSellPrice * 12).toStringAsFixed(0));
    final barcodeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Satuan Multi-Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Satuan (Contoh: Dus, Karton)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib isi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Isi Konversi (Jumlah Pcs di dalam)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => int.tryParse(val ?? '') == null ? 'Wajib angka bulat' : null,
                  onChanged: (val) {
                    final factor = int.tryParse(val) ?? 1;
                    buyController.text = (baseBuyPrice * factor).toStringAsFixed(0);
                    sellController.text = (baseSellPrice * factor).toStringAsFixed(0);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: buyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Harga HPP Beli Satuan',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: sellController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Harga Jual Satuan',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode Khusus Satuan Ini (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, {
                  'unitName': unitController.text.trim(),
                  'conversion': int.parse(qtyController.text),
                  'buyPriceUnit': double.tryParse(buyController.text) ?? 0,
                  'sellPriceUnit': double.tryParse(sellController.text) ?? 0,
                  'barcode': barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                });
              }
            },
            child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
