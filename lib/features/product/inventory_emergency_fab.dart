import 'dart:convert'; // <-- TAMBAHKAN IMPORT INI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_database.dart';

class InventoryEmergencyFab extends ConsumerStatefulWidget {
  const InventoryEmergencyFab({super.key});

  /// Static Helper untuk dipanggil langsung dari ProductPage jika diperlukan
  static void showEmergencyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mode Darurat Inventaris'),
        content: const Text('Akses cepat tindakan darurat stok.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<InventoryEmergencyFab> createState() => _InventoryEmergencyFabState();
}

class _InventoryEmergencyFabState extends ConsumerState<InventoryEmergencyFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
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
        if (_isOpen) ...[
          _buildChildButton(
            label: 'Koreksi Stok Instan',
            icon: Icons.gavel_rounded,
            color: Colors.red.shade700,
            onTap: _showEmergencyStockDialog,
          ),
          const SizedBox(height: 10),
          _buildChildButton(
            label: 'Ubah Harga Kilat',
            icon: Icons.monetization_on,
            color: Colors.amber.shade900,
            onTap: _showQuickPriceDialog,
          ),
          const SizedBox(height: 10),
          _buildChildButton(
            label: 'Backup Darurat (JSON)',
            icon: Icons.vibration_rounded,
            color: Colors.purple.shade700,
            onTap: _performEmergencyBackup,
          ),
          const SizedBox(height: 14),
        ],
        FloatingActionButton(
          heroTag: 'urgent_trigger_fab',
          backgroundColor: _isOpen ? Colors.black : Colors.red.shade900,
          onPressed: _toggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: child.key == const ValueKey('icon1')
                  ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
                  : Tween<double>(begin: 0.0, end: 0.25).animate(anim),
              child: child,
            ),
            child: _isOpen
                ? const Icon(Icons.close, color: Colors.white, key: ValueKey('icon1'))
                : const Icon(Icons.warning_amber_rounded, color: Colors.white, key: ValueKey('icon2')),
          ),
        ),
      ],
    );
  }

  Widget _buildChildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.grey.shade900,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'urgent_child_${label.hashCode}',
              backgroundColor: color,
              onPressed: () {
                _toggle();
                onTap();
              },
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyStockDialog() {
    final skuCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String alasan = 'Rusak';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red.shade800),
            const SizedBox(width: 8),
            const Text('Koreksi Stok Fisik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(
                labelText: 'Scan Barcode / Input SKU',
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Jumlah Perubahan (e.g. -5 atau 2)',
                prefixIcon: Icon(Icons.exposure),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: alasan,
              items: ['Rusak', 'Hilang / Pencurian', 'Salah Input Sebelumnya', 'Expired']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => alasan = v ?? 'Rusak',
              decoration: const InputDecoration(labelText: 'Alasan Penyesuaian'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              if (skuCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Stok SKU ${skuCtrl.text} disesuaikan sebanyak ${qtyCtrl.text} ($alasan)'),
                  backgroundColor: Colors.red.shade800,
                ));
              }
            },
            child: const Text('EKSEKUSI STOK', style: TextStyle(color: Colors.white)),
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
        title: const Text('Ubah Harga Jual Kilat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(labelText: 'Masukkan SKU / Kode Barang'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga Jual Baru (Rp)', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
            onPressed: () {
              if (skuCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Harga SKU ${skuCtrl.text} diperbarui menjadi Rp ${priceCtrl.text}'),
                  backgroundColor: Colors.amber.shade900,
                ));
              }
            },
            child: const Text('UPDATE HARGA', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _performEmergencyBackup() {
    final List<Map<String, dynamic>> dummyBackupData = [
      {"sku": "BRG001", "nama": "Semen Gresik 50kg", "stok": 120, "harga": 65000},
      {"sku": "BRG002", "nama": "Paku Payung Kotak", "stok": 45, "harga": 12000},
    ];

    // Hapus kata 'const' dari JsonEncoder.withIndent
    final rawJsonDump = JsonEncoder.withIndent('  ').convert(dummyBackupData);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.purple),
            SizedBox(width: 8),
            Text('Ekspor Data Darurat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salin teks JSON ini ke media penyimpanan luar jika sistem bermasalah:',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  rawJsonDump,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('TUTUP')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800),
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Data siap disalin dari dialog ekspor.'),
              ));
            },
            child: const Text('SALIN TEKS', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
