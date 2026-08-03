import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/daos/user_dao.dart';
import 'manage_permission_page.dart';
import 'detail_salesman_page.dart';

final allUsersProvider = StreamProvider<List<UserData>>((ref) {
  final dao = ref.watch(userDaoProvider);
  return dao.watchAllUsers();
});

class ManageUsersPage extends ConsumerWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSalesmanDialog(context, ref),
        child: const Icon(Icons.person_add, color : Colors.white),
      ),
      body: usersAsync.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final u = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 70),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  child: Text(u.name.isNotEmpty? u.name[0].toUpperCase() : '?'),
                ),
                title: Text(u.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.role.toUpperCase()} | ${u.status} | ${u.username?? "-"}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('API: ${u.apiKey?? "No API Key"} | Disc Max: ${u.maxDiscountPercent}%', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                    Text('Akses: ${u.canManageStock? "Master " : ""}${u.canCreateCustomer? "Cust " : ""}${u.canCollectPayment? "Tagih " : ""}${u.canVoidTransaction? "Void" : ""}', style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  // 1. GENERATOR LAMA TETAP (QR)
                  if (u.role == UserRole.salesman)
                    IconButton(
                      tooltip: 'QR API Key',
                      icon: const Icon(Icons.qr_code, color: Colors.black),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: u))),
                    ),
                  // 2. KELOLA CHECKLIST HALAMAN + UBAH USERNAME/PASSWORD
                  IconButton(
                    tooltip: 'Kelola Akses & Login',
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () => _showFullEditDialog(context, ref, u),
                  ),
                ]),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.black))),
      ),
    );
  }

  // DIALOG TAMBAH SALESMAN BARU (LAMA TETAP)
  void _showAddSalesmanDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Tambah Salesman Baru', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Salesman')),
        TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN 6 Digit'), maxLength: 6, keyboardType: TextInputType.number),
        TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area Sales')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: () async {
            final dao = ref.read(userDaoProvider);
            final newUser = await dao.createSalesmanWithApiKey(name: nameCtrl.text, pin: pinCtrl.text, salesArea: areaCtrl.text);
            Navigator.pop(ctx);
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: newUser)));
          },
          child: const Text('Buat + Generate QR'),
        ),
      ],
    ));
  }

  // DIALOG EDIT LENGKAP: UBAH USERNAME/PASSWORD + CHECKLIST HALAMAN + KELOLA PENTING + GENERATOR
  void _showFullEditDialog(BuildContext context, WidgetRef ref, UserData u) {
    final nameC = TextEditingController(text: u.name);
    final usernameC = TextEditingController(text: u.username?? '');
    final passC = TextEditingController(text: u.passwordHash?? '');
    final pinC = TextEditingController(text: u.pinCode?? '');
    final maxDiscC = TextEditingController(text: u.maxDiscountPercent.toString());
    final areaC = TextEditingController(text: u.salesArea?? '');

    bool canOverride = u.canOverridePrice;
    bool canDiscount = u.canGiveDiscount;
    bool canVoid = u.canVoidTransaction;
    bool canStock = u.canManageStock;
    bool canCreateCust = u.canCreateCustomer;
    bool canCollect = u.canCollectPayment;
    bool canReturn = u.canProcessReturn;
    String status = u.status;
    String role = u.role;

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Kelola: ${u.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- UBAH USERNAME & PASSWORD ---
                const Text('1. UBAH USERNAME & PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                TextField(controller: usernameC, decoration: const InputDecoration(labelText: 'Username (login)')),
                TextField(controller: passC, decoration: const InputDecoration(labelText: 'Password Baru')),
                TextField(controller: pinC, decoration: const InputDecoration(labelText: 'PIN 6 digit')),
                TextField(controller: areaC, decoration: const InputDecoration(labelText: 'Area / Alamat')),
                DropdownButton<String>(value: role, isExpanded: true, items: const [DropdownMenuItem(value: 'salesman', child: Text('Salesman')), DropdownMenuItem(value: 'kasir', child: Text('Kasir/Admin')), DropdownMenuItem(value: 'owner', child: Text('Owner'))], onChanged: (v) => setSt(() => role = v!)),
                DropdownButton<String>(value: status, isExpanded: true, items: const [DropdownMenuItem(value: 'aktif', child: Text('Aktif')), DropdownMenuItem(value: 'non_aktif', child: Text('Non Aktif')), DropdownMenuItem(value: 'suspended', child: Text('Suspended'))], onChanged: (v) => setSt(() => status = v!)),
                const Divider(),
                // --- CHECKLIST HALAMAN SALESMAN ---
                const Text('2. CHECKLIST HALAMAN SALESMAN', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(value: canCreateCust, dense: true, title: const Text('Boleh Buat Customer', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canCreateCust = v!)),
                CheckboxListTile(value: canCollect, dense: true, title: const Text('Boleh Tagih Piutang', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canCollect = v!)),
                CheckboxListTile(value: canReturn, dense: true, title: const Text('Boleh Proses Retur', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canReturn = v!)),
                const Divider(),
                // --- KELOLA PENTING LAINNYA ---
                const Text('3. KELOLA PENTING LAINNYA', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(value: canStock, dense: true, title: const Text('Kelola Stok & Master', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canStock = v!)),
                CheckboxListTile(value: canVoid, dense: true, title: const Text('Boleh Void Transaksi', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canVoid = v!)),
                CheckboxListTile(value: canOverride, dense: true, title: const Text('Boleh Override Harga', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canOverride = v!)),
                CheckboxListTile(value: canDiscount, dense: true, title: const Text('Boleh Kasih Diskon', style: TextStyle(fontSize: 13)), onChanged: (v) => setSt(() => canDiscount = v!)),
                TextField(controller: maxDiscC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Diskon %')),
                const Divider(),
                // --- GENERATOR LAMA TETAP ---
                const Text('4. GENERATOR API KEY (LAMA)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text('Key saat ini: ${u.apiKey?? "-"}', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () async { final dao = ref.read(userDaoProvider); final newKey = await dao.regenerateApiKey(u.id); setSt(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New Key: $newKey'))); }, icon: const Icon(Icons.refresh), label: const Text('Regenerate Key'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: u))), icon: const Icon(Icons.qr_code), label: const Text('Lihat QR'))),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagePermissionPage(user: u))), icon: const Icon(Icons.tune), label: const Text('Buka ManagePermissionPage Lama')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () async {
                final dao = ref.read(userDaoProvider);
                await dao.updateUserFull(u.id, nameC.text, usernameC.text, passC.text, pinC.text, role, status, canOverride, canDiscount, canVoid, canStock, canCreateCust, canCollect, canReturn, double.tryParse(maxDiscC.text)?? 0.0);
                // update area juga
                await dao.updateUserProfile(userId: u.id, name: nameC.text, username: usernameC.text, salesArea: areaC.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('SIMPAN SEMUA'),
            ),
          ],
        );
      });
    });
  }
}