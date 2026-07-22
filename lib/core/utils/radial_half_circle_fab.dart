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
  int _level = 0; // 0 tutup, 1 main, 2 darurat, 3 cepat, 4 master
  final double innerRadius = 95; // Orbit 1 - Topik
  final double outerRadius = 175; // Orbit 2 - Sub Topik
  final List<double> innerAngles = [190, 235, 280]; // 3 topik
  final List<double> outerAngles = [165, 200, 235, 275]; // 3 sub + back/close
  final double closeAngle = 285;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _changeLevel(int newLevel) async {
    if (_level!= 0) {
      await _controller.reverse();
      if (!mounted) return;
    }
    if (newLevel == 0) {
      setState(() => _level = 0);
      return;
    }
    setState(() => _level = newLevel);
    _controller.forward(from: 0);
  }

  Widget _orbitItem({
    required int index,
    required double angleDeg,
    required double radius,
    required bool show,
    required Color color,
    required IconData icon,
    required VoidCallback tap,
    required String tag,
    double delay = 0,
    bool dimmed = false,
  }) {
    if (!show) return const SizedBox.shrink();
    final start = (delay + index * 0.08).clamp(0.0, 0.6);
    final end = (0.6 + start).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInBack,
    );
    final rad = angleDeg * math.pi / 180;

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final p = anim.value;
        return IgnorePointer(
          ignoring: p < 0.3,
          child: Transform.translate(
            offset: Offset(math.cos(rad) * radius * p, math.sin(rad) * radius * p),
            child: Transform.scale(scale: p, child: Opacity(opacity: dimmed? p * 0.5 : p, child: child)),
          ),
        );
      },
      child: SizedBox(
        width: 50, height: 50,
        child: FloatingActionButton.small(
          heroTag: tag,
          backgroundColor: color,
          elevation: dimmed? 2 : 6,
          onPressed: tap,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMain = _level == 1;
    final isSub = _level == 2 || _level == 3 || _level == 4;

    return SizedBox(
      width: 380, height: 380,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // ===== ORBIT 1 DALAM - TOPIK UTAMA =====
          // Selalu muncul pas level 1, dan tetap muncul redup pas di sub topik biar bisa pindah topik cepat
          _orbitItem(index: 0, angleDeg: innerAngles[0], radius: innerRadius, show: isMain || isSub, color: Colors.red.shade900, icon: Icons.warning_amber_rounded, tag: 't_darurat', dimmed: isSub && _level!= 2, tap: () => _changeLevel(2)),
          _orbitItem(index: 1, angleDeg: innerAngles[1], radius: innerRadius, show: isMain || isSub, color: const Color(0xFF007F00), icon: Icons.flash_on, tag: 't_cepat', dimmed: isSub && _level!= 3, tap: () => _changeLevel(3)),
          _orbitItem(index: 2, angleDeg: innerAngles[2], radius: innerRadius, show: isMain || isSub, color: const Color(0xFF00A65A), icon: Icons.add_box_rounded, tag: 't_master', dimmed: isSub && _level!= 4, tap: () => _changeLevel(4)),
          _orbitItem(index: 3, angleDeg: closeAngle, radius: innerRadius, show: isMain, color: Colors.black87, icon: Icons.close, tag: 't_close', tap: () => _changeLevel(0)),

          // ===== ORBIT 2 LUAR - SUB TOPIK =====
          // Muncul cuma pas level 2,3,4 - radius lebih jauh jadi gak ketimpa
          // LEVEL 2 - SUB DARURAT
          _orbitItem(index: 0, angleDeg: outerAngles[0], radius: outerRadius, show: _level == 2, color: Colors.red.shade700, icon: Icons.gavel_rounded, tag: 's2_1', tap: () { _changeLevel(0); widget.onEmergencyStock(); }),
          _orbitItem(index: 1, angleDeg: outerAngles[1], radius: outerRadius, show: _level == 2, color: Colors.amber.shade900, icon: Icons.monetization_on, tag: 's2_2', tap: () { _changeLevel(0); widget.onEmergencyPrice(); }),
          _orbitItem(index: 2, angleDeg: outerAngles[2], radius: outerRadius, show: _level == 2, color: Colors.purple.shade700, icon: Icons.backup_rounded, tag: 's2_3', tap: () { _changeLevel(0); widget.onEmergencyBackup(); }),
          _orbitItem(index: 3, angleDeg: outerAngles[3], radius: outerRadius, show: _level == 2, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's2_back', tap: () => _changeLevel(1)),

          // LEVEL 3 - SUB CEPAT
          _orbitItem(index: 0, angleDeg: outerAngles[0], radius: outerRadius, show: _level == 3, color: const Color(0xFF007F00), icon: Icons.qr_code_scanner, tag: 's3_1', tap: () { _changeLevel(0); widget.onScan(); }),
          _orbitItem(index: 1, angleDeg: outerAngles[1], radius: outerRadius, show: _level == 3, color: const Color(0xFF007F00), icon: Icons.edit_note, tag: 's3_2', tap: () { _changeLevel(0); widget.onQuickStock(); }),
          _orbitItem(index: 2, angleDeg: outerAngles[2], radius: outerRadius, show: _level == 3, color: const Color(0xFF007F00), icon: Icons.print, tag: 's3_3', tap: () { _changeLevel(0); widget.onPrintLabel(); }),
          _orbitItem(index: 3, angleDeg: outerAngles[3], radius: outerRadius, show: _level == 3, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's3_back', tap: () => _changeLevel(1)),

          // LEVEL 4 - SUB MASTER
          _orbitItem(index: 0, angleDeg: outerAngles[0], radius: outerRadius, show: _level == 4, color: const Color(0xFF00A65A), icon: Icons.inventory_2, tag: 's4_1', tap: () { _changeLevel(0); widget.onAddProduct(); }),
          _orbitItem(index: 1, angleDeg: outerAngles[1], radius: outerRadius, show: _level == 4, color: Colors.blueGrey, icon: Icons.category, tag: 's4_2', tap: () { _changeLevel(0); widget.onAddCategory(); }),
          _orbitItem(index: 2, angleDeg: outerAngles[2], radius: outerRadius, show: _level == 4, color: Colors.amber.shade800, icon: Icons.local_shipping, tag: 's4_3', tap: () { _changeLevel(0); }),
          _orbitItem(index: 3, angleDeg: outerAngles[3], radius: outerRadius, show: _level == 4, color: Colors.orange.shade900, icon: Icons.arrow_back, tag: 's4_back', tap: () => _changeLevel(1)),

          // MASTER BUTTON
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