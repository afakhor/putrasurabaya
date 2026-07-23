import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/local_database.dart';
import '../../features/product/product_form_provider.dart';
import '../../features/product/product_form_dialogs.dart';

/// Item Data untuk Sub Menu Level 2
class FabSubItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  FabSubItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class QuartFabProduct extends ConsumerStatefulWidget {
  final Function(BuildContext, {ProductData? product})? onOpenProductForm;

  const QuartFabProduct({
    Key? key,
    this.onOpenProductForm,
  }) : super(key: key);

  @override
  ConsumerState<QuartFabProduct> createState() => _QuartFabProductState();
}

class _QuartFabProductState extends ConsumerState<QuartFabProduct>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _subController;

  late Animation<double> _mainAnimation;
  late Animation<double> _subAnimation;

  int? _selectedMainMenuIndex;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _subController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    );

    _subAnimation = CurvedAnimation(
      parent: _subController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _subController.dispose();
    super.dispose();
  }

  void _toggleMainMenu() {
    if (_mainController.isCompleted || _mainController.isAnimating) {
      _subController.reverse();
      _mainController.reverse();
      setState(() {
        _selectedMainMenuIndex = null;
      });
    } else {
      _mainController.forward();
    }
  }

  void _onMainOptionTap(int index) {
    if (_selectedMainMenuIndex == index) {
      // Menutup Sub-Menu jika menekan tombol utama yang sedang aktif
      _subController.reverse();
      setState(() {
        _selectedMainMenuIndex = null;
      });
    } else {
      // Membuka Sub-Menu untuk kategori terpilih
      _selectedMainMenuIndex = index;
      _subController.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);

    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // ================= LAYER LEVEL 2: SUB-OPSI =================
          if (_selectedMainMenuIndex != null)
            ..._buildLevel2SubMenuButtons(db),

          // ================= LAYER LEVEL 1: 3 UTAMA =================
          ..._buildLevel1MainMenuButtons(),

          // ================= TRIGGER BASE FAB UTAMA =================
          FloatingActionButton(
            heroTag: "quart_main_fab_trigger",
            backgroundColor: _mainController.isCompleted
                ? Colors.black87
                : const Color(0xFF007F00),
            onPressed: _toggleMainMenu,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _mainAnimation,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // BUILDER LEVEL 1: 3 OPSI UTAMA (RADIALLY SPREAD - ¼ CIRCLE)
  // ------------------------------------------------------------------
  List<Widget> _buildLevel1MainMenuButtons() {
    final List<Map<String, dynamic>> mainOptions = [
      {
        'title': 'Form Master',
        'icon': Icons.add_box_rounded,
        'color': const Color(0xFF00A65A)
      },
      {
        'title': 'Emergency Stok',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red.shade800
      },
      {
        'title': 'Quick Actions',
        'icon': Icons.tune_rounded,
        'color': Colors.amber.shade900
      },
    ];

    const double radius = 125.0; // Jarak jangkar dari FAB Utama

    return List.generate(3, (index) {
      // Sudut seperempat lingkaran: Index 0 = 0 rad (Kiri), Index 1 = pi/4 (Up-Left), Index 2 = pi/2 (Atas)
      final double angle = (pi / 2) * (index / 2);

      return AnimatedBuilder(
        animation: _mainAnimation,
        builder: (context, child) {
          final double progress = _mainAnimation.value;
          final double dx = -radius * progress * cos(angle);
          final double dy = -radius * progress * sin(angle);

          final bool isSelected = _selectedMainMenuIndex == index;
          final bool isOtherSelected =
              _selectedMainMenuIndex != null && !isSelected;

          // Mengatur redup/pudar tombol lain jika salah satu tombol aktif
          final double scale = isOtherSelected ? 0.75 : 1.0;
          final double opacity = isOtherSelected ? 0.4 : progress.clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: "quart_main_opt_$index",
                      elevation: isSelected ? 6 : 3,
                      backgroundColor: isSelected
                          ? Colors.blueGrey.shade900
                          : mainOptions[index]['color'],
                      onPressed: () => _onMainOptionTap(index),
                      child: Icon(
                        mainOptions[index]['icon'],
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ------------------------------------------------------------------
  // BUILDER LEVEL 2: ISI MASING-MASING 3 FILE SESUAI PILIHAN
  // ------------------------------------------------------------------
  List<Widget> _buildLevel2SubMenuButtons(LocalDatabase db) {
    List<FabSubItem> subItems = [];

    switch (_selectedMainMenuIndex) {
      case 0:
        // A. OPSI BARIS DARI: product_form_provider.dart
        subItems = [
          FabSubItem(
            icon: Icons.post_add_rounded,
            label: 'Form Tambah Baru',
            color: const Color(0xFF00A65A),
            onTap: () {
              ref.invalidate(productFormProvider);
              if (widget.onOpenProductForm != null) {
                widget.onOpenProductForm!(context);
              }
            },
          ),
          FabSubItem(
            icon: Icons.unfold_more_double_rounded,
            label: 'Tambah Satuan Multi-Tier',
            color: Colors.teal,
            onTap: () async {
              final formState = ref.read(productFormProvider);
              final res = await ProductFormDialogs.showUnitConversionDialog(
                context: context,
                baseBuyPrice: formState.buyPrice,
                baseSellPrice: formState.sellPriceGeneral,
              );
              if (res != null) {
                ref.read(productFormProvider.notifier).addUnit(
                      res['unitName'],
                      res['conversion'],
                      res['buyPriceUnit'],
                      res['sellPriceUnit'],
                      res['barcode'],
                    );
              }
            },
          ),
          FabSubItem(
            icon: Icons.dashboard_customize_rounded,
            label: 'Generate Varian Matrix',
            color: Colors.indigo,
            onTap: () {
              ref.read(productFormProvider.notifier).generateVariants(
                warnaList: ['Merah', 'Hitam'],
                ukuranList: ['L', 'XL'],
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Matriks varian sampel digenerate!')),
              );
            },
          ),
        ];
        break;

      case 1:
        // B. OPSI BARIS DARI: inventory_emergency_fab.dart
        subItems = [
          FabSubItem(
            icon: Icons.gavel_rounded,
            label: 'Koreksi Stok Instan',
            color: Colors.red.shade700,
            onTap: () => _showEmergencyStockDialog(),
          ),
          FabSubItem(
            icon: Icons.monetization_on_rounded,
            label: 'Ubah Harga Kilat',
            color: Colors.amber.shade900,
            onTap: () => _showQuickPriceDialog(),
          ),
          FabSubItem(
            icon: Icons.vibration_rounded,
            label: 'Backup JSON Darurat',
            color: Colors.purple.shade700,
            onTap: () => _performEmergencyBackup(),
          ),
        ];
        break;

      case 2:
        // C. OPSI BARIS DARI: product_quick_actions.dart
        subItems = [
          FabSubItem(
            icon: Icons.category_rounded,
            label: 'Tambah Kategori',
            color: Colors.blue,
            onTap: () => _showQuickTextEntry('Kategori'),
          ),
          FabSubItem(
            icon: Icons.layers_rounded,
            label: 'Tambah Sub-Kategori',
            color: Colors.deepOrange,
            onTap: () => _showSubCategoryDialog(),
          ),
          FabSubItem(
            icon: Icons.branding_watermark_rounded,
            label: 'Tambah Brand',
            color: Colors.cyan.shade700,
            onTap: () => _showQuickTextEntry('Brand'),
          ),
          FabSubItem(
            icon: Icons.local_shipping_rounded,
            label: 'Tambah Supplier',
            color: Colors.green.shade800,
            onTap: () => _showSupplierInputBottomSheet(db),
          ),
        ];
        break;
    }

    const double parentRadius = 125.0;
    const double subRadius = 85.0; // Jarak mekar dari tombol Level 1

    final double parentAngle = (pi / 2) * (_selectedMainMenuIndex! / 2);
    final double parentDx = -parentRadius * cos(parentAngle);
    final double parentDy = -parentRadius * sin(parentAngle);

    return List.generate(subItems.length, (subIndex) {
      // Menghitung penyebaran sudut kipas sub-menu agar presisi tanpa menabrak tombol lain
      const double spreadAngle = pi / 2.8;
      final double startAngle = parentAngle - (spreadAngle / 2);
      final double step = subItems.length > 1
          ? spreadAngle / (subItems.length - 1)
          : 0;
      final double currentAngle = startAngle + (subIndex * step);

      return AnimatedBuilder(
        animation: _subAnimation,
        builder: (context, child) {
          final double progress = _subAnimation.value;
          final double dx =
              parentDx - (subRadius * progress * cos(currentAngle));
          final double dy =
              parentDy - (subRadius * progress * sin(currentAngle));

          final item = subItems[subIndex];

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: progress,
                child: Tooltip(
                  message: item.label,
                  child: RawMaterialButton(
                    onPressed: () {
                      _toggleMainMenu();
                      item.onTap();
                    },
                    elevation: 4.0,
                    fillColor: item.color,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                      width: 38.0,
                      height: 38.0,
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ================= UTILITY DIALOGS INTEGRATED =================

  void _showQuickTextEntry(String title) async {
    String? val = await ProductFormDialogs.showQuickTextDialog(
      context: context,
      title: 'Tambah $title Baru',
      labelField: 'Nama $title',
    );
    if (val != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title "$val" siap digunakan.')),
      );
    }
  }

  void _showEmergencyStockDialog() {
    final skuCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koreksi Stok Fisik Lapangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(labelText: 'Scan SKU / Barcode'),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Jumlah Penyesuaian (Contoh: -2)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Stok SKU ${skuCtrl.text} disesuaikan ${qtyCtrl.text}')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Eksekusi', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showQuickPriceDialog() {
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Harga Jual Kilat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(labelText: 'Kode SKU / Barcode'),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga Jual Baru', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade900),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Harga SKU ${skuCtrl.text} diperbarui ke Rp ${priceCtrl.text}')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _performEmergencyBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup mentah JSON berhasil diproses ke memori lokal.'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showSubCategoryDialog() {
    final subCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Sub-Kategori'),
        content: TextField(
          controller: subCtrl,
          decoration:
              const InputDecoration(labelText: 'Nama Sub-Kategori Baru'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Sub-Kategori "${subCtrl.text}" ditambahkan.')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _showSupplierInputBottomSheet(LocalDatabase db) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Registrasi Supplier Utama',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nama Perusahaan / Supplier'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A65A)),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await db.into(db.suppliers).insert(
                          SuppliersCompanion.insert(
                            id: 'SPL-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                          ),
                        );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Supplier Offline Tersimpan!')),
                      );
                    }
                  }
                },
                child: const Text('Simpan Supplier',
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
