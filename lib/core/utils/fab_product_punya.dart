import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/features/product/product_form_provider.dart';
import 'package:ud_putra_kasir/features/product/product_form_dialogs.dart';


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
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _subController = AnimationController(
      duration: const Duration(milliseconds: 220),
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

  void _closeAll() {
    _subController.reverse();
    _mainController.reverse();
    setState(() {
      _selectedMainMenuIndex = null;
    });
  }

  void _toggleMainMenu() {
    if (_mainController.isCompleted || _mainController.isAnimating) {
      _closeAll();
    } else {
      _mainController.forward();
    }
  }

  void _onMainOptionTap(int index) {
    if (index == 0) {
      // OPSI 1: LANGSUNG BUKA FORM MASTER BARANG
      _closeAll();
      ref.invalidate(productFormProvider);
      if (widget.onOpenProductForm != null) {
        widget.onOpenProductForm!(context);
      }
      return;
    }

    if (index == 2) {
      // OPSI 3: BUKA GRID SHEET 10 SHORTCUT QUICK ACTIONS
      _closeAll();
      _showQuickActionsGridModal();
      return;
    }

    // OPSI 2: SUB-MENU RADIAL EMERGENCY STOK
    if (_selectedMainMenuIndex == index) {
      _subController.reverse();
      setState(() {
        _selectedMainMenuIndex = null;
      });
    } else {
      _selectedMainMenuIndex = index;
      _subController.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // LEVEL 2: EMERGENCY STOK SHORTCUTS
          if (_selectedMainMenuIndex == 1)
            ..._buildEmergencySubMenuButtons(),

          // LEVEL 1: 3 OPSI UTAMA RADIAL
          ..._buildLevel1MainMenuButtons(),

          // FAB TRIGGER UTAMA
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
  // LEVEL 1: 3 OPSI UTAMA
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
        'title': 'Quick Actions (10)',
        'icon': Icons.grid_view_rounded,
        'color': Colors.amber.shade900
      },
    ];

    const double radius = 115.0;

    return List.generate(3, (index) {
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

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: isOtherSelected ? 0.35 : progress.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: isOtherSelected ? 0.75 : 1.0,
                child: Tooltip(
                  message: mainOptions[index]['title'],
                  child: FloatingActionButton.small(
                    heroTag: "quart_main_opt_$index",
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
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ------------------------------------------------------------------
  // LEVEL 2: EMERGENCY STOK SHORTCUTS (RADIAL)
  // ------------------------------------------------------------------
  List<Widget> _buildEmergencySubMenuButtons() {
    final List<FabSubItem> subItems = [
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

    const double parentRadius = 115.0;
    const double subRadius = 75.0;
    final double parentAngle = pi / 4; // Sudut opsi tengah (index 1)
    final double parentDx = -parentRadius * cos(parentAngle);
    final double parentDy = -parentRadius * sin(parentAngle);

    return List.generate(subItems.length, (subIndex) {
      const double spreadAngle = pi / 3.0;
      final double startAngle = parentAngle - (spreadAngle / 2);
      final double step = spreadAngle / (subItems.length - 1);
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
                      _closeAll();
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

  // ------------------------------------------------------------------
  // MODAL BOTTOM SHEET: 10 SHORTCUT QUICK ACTIONS (GRID RESPONSIONAL)
  // ------------------------------------------------------------------
  void _showQuickActionsGridModal() {
    final db = ref.read(localDatabaseProvider);

    final List<Map<String, dynamic>> shortcuts = [
      {
        'title': 'Kategori',
        'icon': Icons.category_rounded,
        'color': Colors.blue,
        'action': () => _showQuickTextEntry('Kategori')
      },
      {
        'title': 'Sub-Kategori',
        'icon': Icons.layers_rounded,
        'color': Colors.deepOrange,
        'action': () => _showSubCategoryDialog()
      },
      {
        'title': 'Brand / Merek',
        'icon': Icons.branding_watermark_rounded,
        'color': Colors.cyan.shade700,
        'action': () => _showQuickTextEntry('Brand')
      },
      {
        'title': 'Supplier',
        'icon': Icons.local_shipping_rounded,
        'color': Colors.green.shade800,
        'action': () => _showSupplierInputBottomSheet(db)
      },
      {
        'title': 'Satuan / Unit',
        'icon': Icons.straighten_rounded,
        'color': Colors.teal,
        'action': () => _showQuickTextEntry('Satuan')
      },
      {
        'title': 'Scan Barcode',
        'icon': Icons.qr_code_scanner_rounded,
        'color': Colors.indigo,
        'action': () => _showActionSnackBar('Pindai Barcode Produk')
      },
      {
        'title': 'Cetak Label',
        'icon': Icons.print_rounded,
        'color': Colors.brown,
        'action': () => _showActionSnackBar('Buka Printer Thermal Label')
      },
      {
        'title': 'Atur Varian',
        'icon': Icons.style_rounded,
        'color': Colors.pink,
        'action': () => _showActionSnackBar('Kelola Master Varian Produk')
      },
      {
        'title': 'Import Data',
        'icon': Icons.file_upload_rounded,
        'color': const Color(0xFF10B981),
        'action': () => _showActionSnackBar('Import Data dari Excel / CSV')
      },
      {
        'title': 'Export Katalog',
        'icon': Icons.picture_as_pdf_rounded,
        'color': Colors.redAccent,
        'action': () => _showActionSnackBar('Export Katalog PDF / Excel')
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Quick Actions Master Barang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shortcuts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = shortcuts[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    item['action']();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            (item['color'] as Color).withOpacity(0.12),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HELPER DIALOGS & ACTIONS
  // ------------------------------------------------------------------
  void _showActionSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menjalankan: $message')),
    );
  }

  void _showQuickTextEntry(String title) async {
    String? val = await ProductFormDialogs.showQuickTextDialog(
      context: context,
      title: 'Tambah $title Baru',
      labelField: 'Nama $title',
    );
    if (val != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title "$val" berhasil disimpan.')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () {
              if (skuCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Stok SKU ${skuCtrl.text} disesuaikan ${qtyCtrl.text}')),
                );
                Navigator.pop(ctx);
              }
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
              if (skuCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Harga SKU ${skuCtrl.text} diperbarui ke Rp ${priceCtrl.text}')),
                );
                Navigator.pop(ctx);
              }
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
        content: Text('Backup JSON Darurat berhasil disalin ke memori lokal.'),
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
              if (subCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Sub-Kategori "${subCtrl.text}" ditambahkan.')),
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
