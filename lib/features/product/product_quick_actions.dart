import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/local_database.dart';
import 'product_form_dialogs.dart';

/// Class Helper untuk pemanggilan statis dari ProductPage
class ProductQuickActions {
  static void scanBarcode(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuka Scanner Barcode...')),
    );
  }

  static void showQuickStockDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koreksi Stok Cepat'),
        content: const TextField(
          decoration: InputDecoration(labelText: 'Jumlah Stok Baru'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  static void showPrintLabelDialog(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan pencetakan label barcode...')),
    );
  }

  // === TARUH DI SINI, MASIH DI DALAM CLASS ===
  static void showEmergencyPrice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubah Harga Kilat...')));
  }
  
  static void showEmergencyBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON...')));
  }
} // <-- kurung tutup class ProductQuickActions

class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF007F00),
  });
}

class ProductQuickActionsFab extends ConsumerStatefulWidget {
  const ProductQuickActionsFab({super.key});

  @override
  ConsumerState<ProductQuickActionsFab> createState() => _ProductQuickActionsFabState();
}

class _ProductQuickActionsFabState extends ConsumerState<ProductQuickActionsFab>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animateIcon;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animateIcon = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    final List<SpeedDialItem> actionItems = [
      SpeedDialItem(
        icon: Icons.category,
        label: 'Tambah Kategori',
        onTap: () => _showTextEntryDialog('Kategori', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori "$val" tersimpan.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.layers,
        label: 'Tambah Sub-Kategori',
        onTap: _showSubCategoryDialog,
      ),
      SpeedDialItem(
        icon: Icons.branding_watermark,
        label: 'Tambah Brand / Merk',
        onTap: () => _showTextEntryDialog('Brand / Merk', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Brand "$val" tersimpan.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.straighten,
        label: 'Tambah Satuan Master',
        onTap: () => _showTextEntryDialog('Satuan (e.g. Kg, Liter)', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Satuan "$val" tersimpan.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.grid_view,
        label: 'Tambah Rak / Lokasi',
        onTap: () => _showTextEntryDialog('Kode Rak (e.g. RAK-A1)', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lokasi "$val" tersimpan.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.local_shipping,
        label: 'Tambah Supplier Utama',
        color: Colors.amber.shade800,
        onTap: () => _showSupplierInputBottomSheet(db),
      ),
      SpeedDialItem(
        icon: Icons.percent,
        label: 'Atur Kebijakan Pajak (PPN)',
        color: Colors.blueGrey,
        onTap: _showTaxConfigurationDialog,
      ),
    ];

    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isMenuOpen)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              reverse: true,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: actionItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text(
                                item.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            heroTag: 'sub_fab_${item.label.hashCode}',
                            backgroundColor: item.color,
                            onPressed: () {
                              _toggleMenu();
                              item.onTap();
                            },
                            child: Icon(item.icon, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'main_speed_dial_fab',
          backgroundColor: _isMenuOpen ? Colors.red : const Color(0xFF007F00),
          onPressed: _toggleMenu,
          child: RotationTransition(
            turns: _animateIcon,
            child: Icon(
              _isMenuOpen ? Icons.close : Icons.tune,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showTextEntryDialog(String entityName, Function(String) onSave) async {
    final result = await ProductFormDialogs.showQuickTextDialog(
      context: context,
      title: 'Pintasan Tambah $entityName',
      labelField: 'Nama / Kode $entityName Baru',
    );
    if (result != null && result.isNotEmpty && mounted) {
      onSave(result);
    }
  }

  void _showSubCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedParent = 'Umum';
    final subCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Sub-Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedParent,
                items: ['Umum', 'Makanan', 'Minuman', 'Otomotif']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => selectedParent = v ?? 'Umum',
                decoration: const InputDecoration(labelText: 'Pilih Kategori Induk', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subCtrl,
                decoration: const InputDecoration(labelText: 'Nama Sub-Kategori', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Sub-Kategori "${subCtrl.text}" diikat ke "$selectedParent"'),
                ));
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showSupplierInputBottomSheet(LocalDatabase db) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final leadTimeCtrl = TextEditingController(text: '3');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrasi Supplier Baru',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF007F00)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Perusahaan / Supplier*', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama supplier wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. Telepon / WhatsApp', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: leadTimeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rata-rata Pengiriman (Hari)', border: OutlineInputBorder()),
                validator: (val) => int.tryParse(val ?? '') == null ? 'Wajib berupa angka' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await db.into(db.suppliers).insert(
                        SuppliersCompanion.insert(
                          id: 'SPL-${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          phone: Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                          leadTimeDays: Value(int.parse(leadTimeCtrl.text)),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Supplier tersimpan ke database offline!'),
                          backgroundColor: Colors.green,
                        ));
                      }
                    }
                  },
                  child: const Text('SIMPAN SUPPLIER OFFLINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showTaxConfigurationDialog() {
    double currentTax = 11.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pengaturan Regulasi Pajak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih kebijakan PPN default untuk produk baru:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              RadioListTile<double>(
                title: const Text('Non-PPN (0%)'),
                value: 0.0,
                groupValue: currentTax,
                onChanged: (v) => setDialogState(() => currentTax = v!),
              ),
              RadioListTile<double>(
                title: const Text('PPN Imposisi Indonesia (11%)'),
                value: 11.0,
                groupValue: currentTax,
                onChanged: (v) => setDialogState(() => currentTax = v!),
              ),
              RadioListTile<double>(
                title: const Text('PPN Penyesuaian Baru (12%)'),
                value: 12.0,
                groupValue: currentTax,
                onChanged: (v) => setDialogState(() => currentTax = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
              onPressed: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Tarif default pajak diatur ke $currentTax%'),
                ));
              },
              child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
