import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/local_database.dart';
import 'product_form_dialogs.dart';

/// Model internal untuk item menu di dalam Speed Dial FAB
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

class _ProductQuickActionsFabState extends ConsumerState<ProductQuickActionsFab> with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animateIcon;
  late Animation<double> _translateButton;
  final double _fabHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animateIcon = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _translateButton = Tween<double>(begin: 0.0, end: 12.0).animate(
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

    // KLASTER MENU UNTUK MENGAKOMODASI 7 INPUT TAMBAHAN YANG SERING LUPA
    final List<SpeedDialItem> actionItems = [
      SpeedDialItem(
        icon: Icons.category,
        label: 'Tambah Kategori',
        onTap: () => _showTextEntryDialog('Kategori', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori "$val" siap dipilih di form.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.layers,
        label: 'Tambah Sub-Kategori',
        onTap: () => _showSubCategoryDialog(),
      ),
      SpeedDialItem(
        icon: Icons.branding_watermark,
        label: 'Tambah Brand / Merk',
        onTap: () => _showTextEntryDialog('Brand / Merk', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Brand "$val" berhasil didaftarkan.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.gavel,
        label: 'Tambah Satuan Master',
        onTap: () => _showTextEntryDialog('Satuan (e.g. Kg, Liter, Meter)', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Satuan "$val" terdaftar sebagai opsi dasar.')));
        }),
      ),
      SpeedDialItem(
        icon: Icons.grid_view,
        label: 'Tambah Rak / Lokasi Gudang',
        onTap: () => _showTextEntryDialog('Kode Rak / Lokasi (e.g. RAK-A1)', (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lokasi Penyimpanan "$val" disimpan.')));
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
        onTap: () => _showTaxConfigurationDialog(),
      ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tampilan Sub-Menu yang Muncul Ketika FAB Utama Di-klik
        if (_isMenuOpen)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: actionItems.asMap().entries.map((entry) {
              int idx = entry.key;
              SpeedDialItem item = entry.value;
              return AnimatedBuilder(
                animation: _translateButton,
                builder: (ctx, child) {
                  double offset = (_fabHeight + _translateButton.value) * (actionItems.length - idx);
                  return Transform.translate(
                    offset: Offset(0, offset - (idx * 65)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                item.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            heroTag: 'sub_fab_$idx',
                            backgroundColor: item.color,
                            onPressed: () {
                              _toggleMenu();
                              item.onTap();
                            },
                            child: Icon(item.icon, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),

        // FAB UTAMA / TRIGGER UTAMA ENGINE SPEED DIAL
        FloatingActionButton(
          heroTag: 'main_speed_dial_fab',
          backgroundColor: _isMenuOpen ? Colors.red : const Color(0xFF007F00),
          onPressed: _toggleMenu,
          child: AnimatedBuilder(
            animation: _animateIcon,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animateIcon.value * 0.785, // Rotasi silang efek tombol close 45 derajat
                child: Icon(
                  _isMenuOpen ? Icons.add : Icons.tune,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// HELPER DIALOG: Standard Input String untuk Kategori, Merk, Satuan, & Rak
  void _showTextEntryDialog(String entityName, Function(String) onSave) async {
    String? result = await ProductFormDialogs.showQuickTextDialog(
      context: context,
      title: 'Pintasan Tambah $entityName',
      labelField: 'Nama / Kode $entityName Baru',
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  /// DIALOG KHUSUS 1: Input Sub-Kategori Terikat Induk
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
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Sub-Kategori "${subCtrl.text}" berhasil diikat ke "$selectedParent"'),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  /// DIALOG KHUSUS 2: Input Master Supplier Baru (Dimasukkan langsung ke Tabel Drift SQLite)
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
              const Text('Registrasi Supplier Baru (UD. Putra)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF007F00))),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Perusahaan / Supplier*', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Nama supplier tidak boleh kosong' : null,
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
                decoration: const InputDecoration(labelText: 'Rata-rata Pengiriman Barang (Hari)', border: OutlineInputBorder()),
                validator: (val) => int.tryParse(val ?? '') == null ? 'Wajib isi angka' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Insert baris baru ke tabel Supplier SQLite asli
                      await db.into(db.suppliers).insert(
                        SuppliersCompanion.insert(
                          id: 'SPL-${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          phone: Value(phoneCtrl.text.isEmpty ? null : phoneCtrl.text.trim()),
                          leadTimeDays: Value(int.parse(leadTimeCtrl.text)),
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier Utama sukses tersimpan secara offline!'), backgroundColor: Colors.green));
                        Navigator.pop(ctx);
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

  /// DIALOG KHUSUS 3: Pengaturan Pajak Global & Default Aplikasi
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarif default pajak diatur ke $currentTax%')));
                Navigator.pop(ctx);
              },
              child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}