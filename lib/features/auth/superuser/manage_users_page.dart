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
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (c,i) {
            final u = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.black, foregroundColor: Colors.white, child: Text(u.name.isNotEmpty? u.name[0].toUpperCase() : '?')),
                title: Text(u.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                subtitle: Text('${u.role.toUpperCase()} | ${u.status} | ${u.apiKey?? 'No API Key'}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (u.role == UserRole.salesman)
                    IconButton(icon: const Icon(Icons.qr_code, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: u)))),
                  IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagePermissionPage(user: u)))),
                ]),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.black))),
      ),
    );
  }

  void _showAddSalesmanDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Tambah Salesman Baru', style: TextStyle(color: Colors.black)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Salesman')),
        TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN 6 Digit'), maxLength: 6, keyboardType: TextInputType.number),
        TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area Sales')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: () async {
          final dao = ref.read(userDaoProvider);
          final newUser = await dao.createSalesmanWithApiKey(name: nameCtrl.text, pin: pinCtrl.text, salesArea: areaCtrl.text);
          Navigator.pop(ctx);
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => DetailSalesmanPage(user: newUser)));
        }, child: const Text('Buat + Generate QR')),
      ],
    ));
  }
}