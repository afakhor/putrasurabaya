import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/product_form_provider.dart';
import '../../core/database/local_database.dart';

class QuartFabProduct extends ConsumerStatefulWidget {
  final Function(BuildContext context, {ProductData? product})? onOpenProductForm;

  const QuartFabProduct({
    super.key,
    this.onOpenProductForm,
  });

  @override
  ConsumerState<QuartFabProduct> createState() => _QuartFabProductState();
}

class _QuartFabProductState extends ConsumerState<QuartFabProduct>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // --- ITEM SUB-MENU / SHORTCUTS (Dapat di-expand) ---
        if (_isOpen) ...[
          _buildShortcutItem(
            icon: Icons.qr_code_scanner,
            label: 'Scan Barcode Cepat',
            color: Colors.purple,
            onTap: () {
              _toggle();
              // TODO: Aksi Scan Barcode Instan
            },
          ),
          const SizedBox(height: 10),
          _buildShortcutItem(
            icon: Icons.flash_on,
            label: 'Stok Darurat / Adjust',
            color: Colors.orange,
            onTap: () {
              _toggle();
              // TODO: Aksi Stok Darurat
            },
          ),
          const SizedBox(height: 10),
          _buildShortcutItem(
            icon: Icons.style,
            label: 'Buat Varian Cepat',
            color: Colors.blue,
            onTap: () {
              _toggle();
              ref.read(productFormProvider.notifier).generateVariants(
                warnaList: ['Merah', 'Hitam'],
                ukuranList: ['S', 'M', 'L'],
              );
              widget.onOpenProductForm?.call(context);
            },
          ),
          const SizedBox(height: 12),
        ],

        // --- TOMBOL UTAMA (+) & TOGGLE SHORTCUT ---
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Toggle Shortcut (Menu Tambahan)
            FloatingActionButton.small(
              heroTag: 'fab_shortcut_toggle',
              backgroundColor: _isOpen ? Colors.grey.shade700 : Colors.grey.shade200,
              foregroundColor: _isOpen ? Colors.white : Colors.black87,
              elevation: 2,
              onPressed: _toggle,
              child: Icon(_isOpen ? Icons.close : Icons.tune),
            ),
            const SizedBox(width: 10),

            // Tombol Utama (+) -> Buka Form Input Barang Lengkap
            FloatingActionButton.extended(
              heroTag: 'fab_main_add_product',
              backgroundColor: const Color(0xFF00A65A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('TAMBAH ITEM', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_isOpen) _toggle(); // Tutup menu jika sedang terbuka
                widget.onOpenProductForm?.call(context); // Buka Form Lengkap
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _expandAnimation,
      child: ScaleTransition(
        scale: _expandAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'shortcut_$label',
              backgroundColor: color,
              foregroundColor: Colors.white,
              onPressed: onTap,
              child: Icon(icon, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
