import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/daos/user_dao.dart';
import '../../../core/utils/config.dart'; // untuk GlassCard
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
      body: usersAsync.when(
        data: (list) => Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
              itemCount: list.length,
              itemBuilder: (c, i) {
                final u = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.black, foregroundColor: Colors.white, child: Text(u.name.isNotEmpty? u.name[0].toUpperCase() : '?')),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${u.role.toUpperCase()} | ${u.status} | ${u.username?? "-"}', style: const TextStyle(fontSize: 11)),
                        Text('Key: ${u.apiKey?? "-"}', style: const TextStyle(fontSize: 9, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        // PANGGILAN LENGKAP 1: DetailSalesmanPage
                        IconButton(
                          tooltip: 'Lihat QR',
                          icon: const Icon(Icons.qr_code_2_rounded),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: u)));
                          },
                        ),
                        // PANGGILAN LENGKAP 2: ManagePermissionPage
                        IconButton(
                          tooltip: 'Kelola Hak Akses',
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ManagePermissionPage(user: u)));
                          },
                        ),
                        IconButton(
                          tooltip: 'Edit Lengkap',
                          icon: const Icon(Icons.settings_rounded, size: 20),
                          onPressed: () => _showFullEditDialog(context, ref, u),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              right: 16, bottom: 85,
              child: FloatingActionButton(
                backgroundColor: Colors.black, foregroundColor: Colors.white,
                onPressed: () => _showAddSalesmanDialog(context, ref),
                child: const Icon(Icons.person_add),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddSalesmanDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tambah Salesman', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
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
            if(ctx.mounted) Navigator.pop(ctx);
            if(context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: newUser)));
          },
          child: const Text('Buat + Generate QR'),
        ),
      ],
    ));
  }

  void _showFullEditDialog(BuildContext context, WidgetRef ref, UserData u) {
    //... isi dialog edit lengkap punyamu, tetap sama, tidak usah diubah
    // di dalamnya kamu sudah ada tombol ke ManagePermissionPage dan DetailSalesmanPage juga
  }
}