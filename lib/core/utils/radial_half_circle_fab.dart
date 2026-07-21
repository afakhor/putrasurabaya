import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialHalfCircleFab extends StatefulWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onEmergencyStock;
  final VoidCallback onEmergencyPrice;
  final VoidCallback onEmergencyBackup;
  final VoidCallback onScan;
  final VoidCallback onQuickStock;
  final VoidCallback onPrintLabel;
  final VoidCallback onAddCategory;

  const RadialHalfCircleFab({
    super.key,
    required this.onAddProduct,
    required this.onEmergencyStock,
    required this.onEmergencyPrice,
    required this.onEmergencyBackup,
    required this.onScan,
    required this.onQuickStock,
    required this.onPrintLabel,
    required this.onAddCategory,
  });

  @override
  State<RadialHalfCircleFab> createState() => _RadialHalfCircleFabState();
}

class _RadialHalfCircleFabState extends State<RadialHalfCircleFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _level = 0; // 0 tutup, 1 main, 10 sub opsi-1, 20 sub opsi-2, 30 sub opsi-3
  final double radius = 125;
  final List<double> angles = [180, 212, 245, 275]; // setengah lingkaran kiri-atas

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _changeLevel(int newLevel) async {
    if (_level!= 0) {
      await _controller.reverse(); // tunggu animasi tutup dulu biar lancar
    }
    if (!mounted) return;
    setState(() => _level = newLevel);
    if (newLevel!= 0) {
      _controller.forward(from: 0);
    }
  }

  Widget _item({
    required int index,
    required double angleDeg,
    required bool show,
    required Color color,
    required IconData icon,
    required VoidCallback tap,
    required String tag,
  }) {
    if (!show) return const SizedBox.shrink();
    final start = (index * 0.09).clamp(0.0, 0.5);
    final interval = Interval(start, (0.6 + start).clamp(0.0, 1.0), curve: Curves.easeOutBack, reverseCurve: Curves.easeInBack);
    final anim = CurvedAnimation(parent: _controller, curve: interval);
    final rad = angleDeg * math.pi / 180;

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final p = anim.value;
        return IgnorePointer(
          ignoring: p < 0.3,
          child: Transform.translate(
            offset: Offset(math.cos(rad) * radius * p, math.sin(rad) * radius * p),
            child: Transform.scale(scale: p, child: Opacity(opacity: p.clamp(0.0, 1.0), child: child)),
          ),
        );
      },
      child: SizedBox(
        width: 48, height: 48,
        child: FloatingActionButton.small(
          heroTag: tag,
          backgroundColor: color,
          elevation: 6,
          onPressed: tap,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320, height: 320,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // LEVEL 1 : Menu Utama - 3 opsi + close tanpa label
          _item(index: 0, angleDeg: angles[0], show: _level == 1, color: Colors.red.shade900, icon: Icons.warning_amber_rounded, tag: 'm1', tap: () => _changeLevel(10)),
          _item(index: 1, angleDeg: angles[1], show: _level == 1, color: const Color(0xFF007F00), icon: Icons.flash_on, tag: 'm2', tap: () => _changeLevel(20)),
          _item(index: 2, angleDeg: angles[2], show: _level == 1, color: const Color(0xFF00A65A), icon: Icons.add_box_rounded, tag: 'm3', tap: () => _changeLevel(30)),
          _item(index: 3, angleDeg: angles[3], show: _level == 1, color: Colors.black87, icon: Icons.close, tag: 'mClose', tap: () => _changeLevel(0)),

          // LEVEL 10 : Sub opsi-1 Darurat (opsi-2 & 3 disembunyikan)
          _item(index: 0, angleDeg: angles[0], show: _level == 10, color: Colors.red.shade700, icon: Icons.gavel_rounded, tag: 's10_1', tap: () { _changeLevel(0); widget.onEmergencyStock(); }),
          _item(index: 1, angleDeg: angles[1], show: _level == 10, color: Colors.amber.shade900, icon: Icons.monetization_on, tag: 's10_2', tap: () { _changeLevel(0); widget.onEmergencyPrice(); }),
          _item(index: 2, angleDeg: angles[2], show: _level == 10, color: Colors.purple.shade700, icon: Icons.backup_rounded, tag: 's10_3', tap: () { _changeLevel(0); widget.onEmergencyBackup(); }),
          _item(index: 3, angleDeg: angles[3], show: _level == 10, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's10_back', tap: () => _changeLevel(1)),

          // LEVEL 20 : Sub opsi-2 Aksi Cepat (opsi-1 & 3 disembunyikan)
          _item(index: 0, angleDeg: angles[0], show: _level == 20, color: const Color(0xFF007F00), icon: Icons.qr_code_scanner, tag: 's20_1', tap: () { _changeLevel(0); widget.onScan(); }),
          _item(index: 1, angleDeg: angles[1], show: _level == 20, color: const Color(0xFF007F00), icon: Icons.edit_note, tag: 's20_2', tap: () { _changeLevel(0); widget.onQuickStock(); }),
          _item(index: 2, angleDeg: angles[2], show: _level == 20, color: const Color(0xFF007F00), icon: Icons.print, tag: 's20_3', tap: () { _changeLevel(0); widget.onPrintLabel(); }),
          _item(index: 3, angleDeg: angles[3], show: _level == 20, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's20_back', tap: () => _changeLevel(1)),

          // LEVEL 30 : Sub opsi-3 Master Barang (opsi-1 & 2 disembunyikan)
          _item(index: 0, angleDeg: angles[0], show: _level == 30, color: const Color(0xFF00A65A), icon: Icons.inventory_2, tag: 's30_1', tap: () { _changeLevel(0); widget.onAddProduct(); }),
          _item(index: 1, angleDeg: angles[1], show: _level == 30, color: Colors.blueGrey, icon: Icons.category, tag: 's30_2', tap: () { _changeLevel(0); widget.onAddCategory(); }),
          _item(index: 2, angleDeg: angles[2], show: _level == 30, color: Colors.amber.shade800, icon: Icons.local_shipping, tag: 's30_3', tap: () { _changeLevel(0); }),
          _item(index: 3, angleDeg: angles[3], show: _level == 30, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's30_back', tap: () => _changeLevel(1)),

          // MASTER TRIGGER 3-strip menu
          FloatingActionButton(
            heroTag: 'master_fab',
            backgroundColor: _level == 0? const Color(0xFF00A65A) : Colors.black,
            elevation: 8,
            onPressed: () => _level == 0? _changeLevel(1) : _changeLevel(0),
            child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _controller, color: Colors.white),
          ),
        ],
      ),
    );
  }
}