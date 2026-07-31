import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';

class ManagePermissionPage extends ConsumerStatefulWidget {
  final UserData user;
  const ManagePermissionPage({super.key, required this.user});
  @override
  ConsumerState<ManagePermissionPage> createState() => _ManagePermissionPageState();
}
class _ManagePermissionPageState extends ConsumerState<ManagePermissionPage> {
  late bool canOverridePrice, canGiveDiscount, canVoid, canStock, canCustomer, canCollect, canReturn;
  late double maxDiscount;
  @override
  void initState() {
    super.initState();
    canOverridePrice = widget.user.canOverridePrice; canGiveDiscount = widget.user.canGiveDiscount; canVoid = widget.user.canVoidTransaction;
    canStock = widget.user.canManageStock; canCustomer = widget.user.canCreateCustomer; canCollect = widget.user.canCollectPayment; canReturn = widget.user.canProcessReturn;
    maxDiscount = widget.user.maxDiscountPercent;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Hak Akses: ${widget.user.name}', style: const TextStyle(color: Colors.black)), backgroundColor: Colors.white.withOpacity(0.85)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          _check('Bisa Ubah Harga Jual', canOverridePrice, (v) => setState(() => canOverridePrice = v)),
          _check('Bisa Kasih Diskon', canGiveDiscount, (v) => setState(() => canGiveDiscount = v)),
          _check('Bisa Void Transaksi', canVoid, (v) => setState(() => canVoid = v)),
          _check('Bisa Kelola Stok', canStock, (v) => setState(() => canStock = v)),
          _check('Bisa Buat Customer Baru', canCustomer, (v) => setState(() => canCustomer = v)),
          _check('Bisa Tagih Piutang', canCollect, (v) => setState(() => canCollect = v)),
          _check('Bisa Proses Retur', canReturn, (v) => setState(() => canReturn = v)),
          const Divider(),
          ListTile(title: Text('Max Diskon: ${maxDiscount.toInt()}%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), subtitle: Slider(value: maxDiscount, min: 0, max: 100, divisions: 20, label: '${maxDiscount.toInt()}%', onChanged: (v) => setState(() => maxDiscount = v))),
        ])),
        const SizedBox(height: 20),
        SizedBox(height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: () async {
          final db = ref.read(localDatabaseProvider);
          await db.userDao.updateUserPermissions(userId: widget.user.id, canOverridePrice: canOverridePrice, canGiveDiscount: canGiveDiscount, canCreateCustomer: canCustomer, canCollectPayment: canCollect, canProcessReturn: canReturn, canVoidTransaction: canVoid, canManageStock: canStock, maxDiscountPercent: maxDiscount);
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hak akses disimpan!'))); Navigator.pop(context); }
        }, child: const Text('SIMPAN PERUBAHAN'))),
      ]),
    );
  }
  Widget _check(String title, bool value, Function(bool) onChanged) => CheckboxListTile(title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 13)), value: value, activeColor: Colors.black, onChanged: (v) => onChanged(v?? false));
}