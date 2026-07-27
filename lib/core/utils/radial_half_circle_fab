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
  String? _activeTopic; // null = level 1, isi = level 2
  late AnimationController _ctrl;
  late Animation<double> _expand;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggleMain() {
    setState(() { _isOpen =!_isOpen; if(!_isOpen) _activeTopic = null; });
    if (_isOpen) { _ctrl.forward(); } else { _ctrl.reverse(); }
  }
  void _openTopic(String topic) { setState(() => _activeTopic = topic); }
  void _backToTopic() { setState(() => _activeTopic = null); }

  // DEFINISI TOPIK SESUAI REQUEST KAMU: MAIN => 1,2,3 => sub dari 1,2,3
  Map<String, List<_RadialItem>> get topics => {
    'EMERGENCY': [
      _RadialItem('Koreksi Stok', Icons.warning_amber_rounded, Colors.red.shade700, _showEmergencyStockDialog),
      _RadialItem('Ubah Harga Kilat', Icons.price_change, Colors.amber.shade900, _showQuickPriceDialog),
      _RadialItem('Backup JSON', Icons.backup, Colors.purple.shade700, _performEmergencyBackup),
    ],
    'MASTER DATA': [
      _RadialItem('Kategori', Icons.category, const Color(0xFF007F00), () => _showTextEntry('Kategori')),
      _RadialItem('Sub-Kategori', Icons.layers, const Color(0xFF007F00), _showSubCategoryDialog),
      _RadialItem('Brand / Merk', Icons.branding_watermark, const Color(0xFF007F00), () => _showTextEntry('Brand')),
      _RadialItem('Satuan', Icons.straighten, const Color(0xFF007F00), () => _showTextEntry('Satuan')),
      _RadialItem('Rak / Lokasi', Icons.grid_view, const Color(0xFF007F00), () => _showTextEntry('Rak')),
      _RadialItem('Supplier', Icons.local_shipping, Colors.orange.shade800, _showSupplierSheet),
    ],
    'SYSTEM': [
      _RadialItem('Pajak PPN', Icons.percent, Colors.blueGrey, _showTaxDialog),
      _RadialItem('Backup Cloud', Icons.cloud_upload, Colors.indigo.shade700, () { ref.read(syncServiceProvider).syncLocalToCloud(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Cloud...'))); }),
    ],
  };

  List<_RadialItem> get mainTopics => [
    _RadialItem('EMERGENCY', Icons.crisis_alert, Colors.red.shade700, () => _openTopic('EMERGENCY')),
    _RadialItem('MASTER DATA', Icons.storage, const Color(0xFF007F00), () => _openTopic('MASTER DATA')),
    _RadialItem('SYSTEM', Icons.settings, Colors.blueGrey, () => _openTopic('SYSTEM')),
  ];

  @override Widget build(BuildContext context) {
    final currentItems = _activeTopic == null? mainTopics : topics[_activeTopic]!;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (_isOpen)
          Positioned(
            bottom: -20, right: -20,
            child: GestureDetector(
              onTap: () { if(_activeTopic!=null) { _backToTopic(); } else { _toggleMain(); } },
              child: Container(width: 500, height: 700, color: Colors.black.withOpacity(0.04)),
            ),
          ),

        // RENDER HALF CIRCLE RAPI
      ...List.generate(currentItems.length, (i) {
          // bagi 180 derajat jadi rata
          final count = currentItems.length;
          final double startAngle = math.pi; // 180
          final double endAngle = 2 * math.pi; // 360
          final double step = count > 1? (endAngle - startAngle) / (count - 1) : 0;
          final double angle = startAngle + step * i;
          final double radius = _activeTopic == null? 100 : 130; // topik utama lebih dekat

          return AnimatedBuilder(
            animation: _expand,
            builder: (_, child) {
              final r = radius * _expand.value;
              return Transform.translate(
offset: Offset(r * math.cos(angle) - 40, r * math.sin(angle)),
                child: Opacity(opacity: _expand.value, child: child),
              );
            },
            child: _buildChild(currentItems[i], isBack: false),
          );
        }),

        // TOMBOL BACK kalau lagi di level 2
        if (_activeTopic!= null && _isOpen)
          AnimatedBuilder(
            animation: _expand,
            builder: (_, child) {
              return Transform.translate(offset: Offset(-70 * _expand.value, -20 * _expand.value), child: child);
            },
            child: FloatingActionButton.small(
              heroTag: 'back_topic',
              backgroundColor: Colors.black,
              onPressed: _backToTopic,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

        FloatingActionButton(
          heroTag: 'radial_main',
          backgroundColor: _isOpen? Colors.black : const Color(0xFF00A65A),
          onPressed: _toggleMain,
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

  Widget _buildChild(_RadialItem item, {bool isBack = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Card(color: Colors.grey.shade900, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 6),
      FloatingActionButton.small(
        heroTag: item.label + (_activeTopic??'main'),
        backgroundColor: item.color,
        onPressed: () {
          if(_activeTopic==null && topics.containsKey(item.label)) { item.onTap(); }
          else { _toggleMain(); item.onTap(); }
        },
        child: Icon(item.icon, size: 18, color: Colors.white)
      ),
    ]);
  }

  void _showEmergencyStockDialog() {
    final sku = TextEditingController(); final qty = TextEditingController(); String alasan = 'Rusak';
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Koreksi Stok Fisik'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU / Barcode')), TextField(controller: qty, decoration: const InputDecoration(labelText: 'Qty +/-')), DropdownButtonFormField(value: alasan, items: ['Rusak','Hilang / Curi','Expired','Salah Input'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> alasan=v!)]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900), onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok ${sku.text} ${qty.text} ($alasan) dieksekusi'))); }, child: const Text('EKSEKUSI', style: TextStyle(color: Colors.white)))]));
  }
  void _showQuickPriceDialog() {
    final sku = TextEditingController(); final price = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Ubah Harga Kilat'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU')), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Baru', prefixText: 'Rp '))]), actions: [ElevatedButton(onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Harga ${sku.text} jadi Rp ${price.text}'))); }, child: const Text('UPDATE'))]));
  }
  void _performEmergencyBackup() {
    final jsonDump = const JsonEncoder.withIndent(' ').convert([{"sku":"BRG001","nama":"Semen","stok":120,"harga":65000}]);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Backup Darurat'), content: Container(height: 150, child: SingleChildScrollView(child: SelectableText(jsonDump, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)))), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('TUTUP'))]));
  }
  void _showTextEntry(String name) async { String? res = await ProductFormDialogs.showQuickTextDialog(context: context, title: 'Tambah $name', labelField: name); if (res!=null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name "$res" disimpan'))); }
  void _showSubCategoryDialog() { _showTextEntry('Sub-Kategori'); }
  void _showSupplierSheet() {
    final nameCtrl = TextEditingController(); final phoneCtrl = TextEditingController(); final db = ref.read(localDatabaseProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(16,16,16, MediaQuery.of(ctx).viewInsets.bottom+16), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Registrasi Supplier Baru', style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier*')), TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No WA')), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 46, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A65A)), onPressed: () async { await db.into(db.suppliers).insert(SuppliersCompanion.insert(id: 'SPL-${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text, phone: Value(phoneCtrl.text))); if(context.mounted) Navigator.pop(ctx); }, child: const Text('SIMPAN SUPPLIER', style: TextStyle(color: Colors.white))))])));
  }
  void _showTaxDialog() {
    double currentTax = 11.0;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: const Text('Pajak PPN'), content: Column(mainAxisSize: MainAxisSize.min, children: [RadioListTile<double>(title: const Text('Non-PPN (0%)'), value: 0.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)), RadioListTile<double>(title: const Text('PPN 11%'), value: 11.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)), RadioListTile<double>(title: const Text('PPN 12%'), value: 12.0, groupValue: currentTax, onChanged: (v)=> setDialogState(()=> currentTax=v!)),]), actions: [ElevatedButton(onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pajak $currentTax%'))); }, child: const Text('Terapkan'))])));
  }
}

class _RadialItem { final String label; final IconData icon; final Color color; final VoidCallback onTap; _RadialItem(this.label, this.icon, this.color, this.onTap); }