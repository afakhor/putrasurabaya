import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/local_database.dart';
import '../../core/services/sync_service.dart';
import '../../features/product/product_form_dialogs.dart';

class RadialHalfCircleFab extends ConsumerStatefulWidget {
  final VoidCallback onAddProduct;
  const RadialHalfCircleFab({super.key, required this.onAddProduct});
  @override ConsumerState<RadialHalfCircleFab> createState() => _RadialHalfCircleFabState();
}

class _RadialHalfCircleFabState extends ConsumerState<RadialHalfCircleFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _ctrl;
  late Animation<double> _expand;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() { _isOpen =!_isOpen; });
    if (_isOpen) { _ctrl.forward(); } else { _ctrl.reverse(); }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _RadialItem('Koreksi Stok', Icons.gavel_rounded, Colors.red.shade700, _showEmergencyStockDialog),
      _RadialItem('Ubah Harga Kilat', Icons.monetization_on, Colors.amber.shade900, _showQuickPriceDialog),
      _RadialItem('Backup JSON', Icons.vibration_rounded, Colors.purple.shade700, _performEmergencyBackup),
      _RadialItem('Backup Cloud', Icons.cloud_upload, Colors.red.shade900, () { ref.read(syncServiceProvider).syncLocalToCloud(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Cloud...'))); }),
      _RadialItem('Tambah Kategori', Icons.category, const Color(0xFF007F00), () => _showTextEntry('Kategori')),
      _RadialItem('Sub-Kategori', Icons.layers, const Color(0xFF007F00), _showSubCategoryDialog),
      _RadialItem('Brand / Merk', Icons.branding_watermark, const Color(0xFF007F00), () => _showTextEntry('Brand / Merk')),
      _RadialItem('Satuan Master', Icons.straighten, const Color(0xFF007F00), () => _showTextEntry('Satuan (Kg, Pcs)')),
      _RadialItem('Rak / Lokasi', Icons.grid_view, const Color(0xFF007F00), () => _showTextEntry('Rak / Lokasi Gudang')),
      _RadialItem('Supplier', Icons.local_shipping, Colors.amber.shade800, _showSupplierSheet),
      _RadialItem('Pajak PPN 11/12%', Icons.percent, Colors.blueGrey, _showTaxDialog),
    ];

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // FIX BLINK: background tap untuk close, bukan Overlay
        if (_isOpen)
          Positioned(
            bottom: -20, right: -20,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(width: 400, height: 600, color: Colors.black.withOpacity(0.05)),
            ),
          ),

        // FIX BLINK: hitungan half circle yang bener pakai cos sin
       ...List.generate(items.length, (i) {
          // half circle dari 180 derajat ke 360 derajat (di atas FAB)
          final double startAngle = math.pi; // 180
          final double endAngle = 2 * math.pi; // 360
          final double angle = startAngle + (endAngle - startAngle) * i / (items.length - 1);
          final double radius = 110 + (i % 3) * 35; // biar gak numpuk, 3 ring

          return AnimatedBuilder(
            animation: _expand,
            builder: (_, child) {
              final r = radius * _expand.value;
              final x = r * math.cos(angle);
              final y = r * math.sin(angle);
              return Transform.translate(
                offset: Offset(x, y),
                child: Opacity(opacity: _expand.value, child: child),
              );
            },
            child: _buildChild(items[i]),
          );
        }),

        FloatingActionButton(
          heroTag: 'radial_main',
          backgroundColor: _isOpen? Colors.black : const Color(0xFF00A65A),
          onPressed: _toggle,
          child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _ctrl, color: Colors.white),
        ),
        if (!_isOpen)
          Positioned(
            bottom: 70, right: 0,
            child: FloatingActionButton.small(
              heroTag: 'add_product_main',
              backgroundColor: const Color(0xFF00A65A),
              onPressed: widget.onAddProduct,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          )
      ],
    );
  }

  Widget _buildChild(_RadialItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Card(
          color: Colors.grey.shade900,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
        ),
        const SizedBox(width: 6),
        FloatingActionButton.small(heroTag: item.label, backgroundColor: item.color, onPressed: () { _toggle(); item.onTap(); }, child: Icon(item.icon, size: 18, color: Colors.white)),
      ]),
    );
  }

  // ===== LOGIC LAMA TETAP - TIDAK DIUBAH =====
  void _showEmergencyStockDialog() {
    final sku = TextEditingController(); final qty = TextEditingController(); String alasan = 'Rusak';
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Koreksi Stok Fisik'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU / Barcode')), TextField(controller: qty, decoration: const InputDecoration(labelText: 'Qty +/-')), DropdownButtonFormField(value: alasan, items: ['Rusak','Hilang / Curi','Expired','Salah Input'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> alasan=v!)]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900), onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok ${sku.text} ${qty.text} ($alasan) dieksekusi'))); }, child: const Text('EKSEKUSI', style: TextStyle(color: Colors.white)))]));
  }
  void _showQuickPriceDialog() {
    final sku = TextEditingController(); final price = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Ubah Harga Kilat'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU')), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Baru', prefixText: 'Rp '))]), actions: [ElevatedButton(onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Harga ${sku.text} jadi Rp ${price.text}'))); }, child: const Text('UPDATE'))]));
  }
  void _performEmergencyBackup() {
    final jsonDump = const JsonEncoder.withIndent(' ').convert([{"sku":"BRG001","nama":"Semen","stok":120,"harga":65000},{"sku":"BRG002","nama":"Paku","stok":45}]);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Row(children: [Icon(Icons.security, color: Colors.purple), SizedBox(width: 8), Text('Backup Darurat')]), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Salin JSON ini ke WA jika error:', style: TextStyle(fontSize: 11)), const SizedBox(height: 8), Container(height: 150, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)), child: SingleChildScrollView(child: SelectableText(jsonDump, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))))]), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('TUTUP'))]));
  }
  void _showTextEntry(String name) async { String? res = await ProductFormDialogs.showQuickTextDialog(context: context, title: 'Tambah $name', labelField: name); if (res!=null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name "$res" disimpan'))); }
  void _showSubCategoryDialog() { _showTextEntry('Sub-Kategori'); }
  void _showSupplierSheet() {
    final nameCtrl = TextEditingController(); final phoneCtrl = TextEditingController(); final db = ref.read(localDatabaseProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(16,16,16, MediaQuery.of(ctx).viewInsets.bottom+16), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Registrasi Supplier Baru', style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier*')), TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No WA')), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 46, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { await db.into(db.suppliers).insert(SuppliersCompanion.insert(id: 'SPL-${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text, phone: Value(phoneCtrl.text))); if(context.mounted) Navigator.pop(ctx); }, child: const Text('SIMPAN SUPPLIER', style: TextStyle(color: Colors.white))))])));
  }
  void _showTaxDialog() {
    double currentTax = 11.0;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Pengaturan Pajak PPN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile<double>(title: const Text('Non-PPN (0%)'), value: 0.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)),
        RadioListTile<double>(title: const Text('PPN 11% Indonesia'), value: 11.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)),
        RadioListTile<double>(title: const Text('PPN 12% Baru'), value: 12.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)),
      ]),
      actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pajak default $currentTax% diterapkan'))); }, child: const Text('Terapkan', style: TextStyle(color: Colors.white)))],
    )));
  }
}

class _RadialItem { final String label; final IconData icon; final Color color; final VoidCallback onTap; _RadialItem(this.label, this.icon, this.color, this.onTap); }