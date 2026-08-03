import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';

class OwnerSettingsPage extends ConsumerStatefulWidget {
  const OwnerSettingsPage({super.key});
  @override ConsumerState<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends ConsumerState<OwnerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _passLamaC = TextEditingController();
  final _passBaruC = TextEditingController();
  final _passUlangC = TextEditingController();
  bool _loading = false;
  UserData? _owner;

  @override void initState() { super.initState(); _loadOwner(); }
  Future<void> _loadOwner() async {
    final db = ref.read(localDatabaseProvider);
    final owner = await db.userDao.getUserByRole('owner');
    if (owner!= null) setState(() { _owner = owner; _usernameC.text = owner.username?? 'owner'; });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Setting Owner', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: _owner == null? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          GlassCard(child: Column(children: [
            TextFormField(controller: _usernameC, decoration: const InputDecoration(labelText: 'Username Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty? 'Wajib isi' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _passLamaC, obscureText: true, decoration: const InputDecoration(labelText: 'Password Lama', border: OutlineInputBorder()), validator: (v) => v!.isEmpty? 'Wajib' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _passBaruC, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru (kosongkan jika tidak ganti)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextFormField(controller: _passUlangC, obscureText: true, decoration: const InputDecoration(labelText: 'Ulang Password Baru', border: OutlineInputBorder())),
          ])),
          const SizedBox(height: 20),
          SizedBox(height: 50, child: ElevatedButton(onPressed: _loading? null : () async {
            if (!_formKey.currentState!.validate()) return;
            if (_owner!.passwordHash!= _passLamaC.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password lama salah!'))); return; }
            setState(() => _loading = true);
            final db = ref.read(localDatabaseProvider);
            await db.userDao.updateUserProfile(userId: _owner!.id, name: _owner!.name, username: _usernameC.text.trim());
            if (_passBaruC.text.isNotEmpty) await db.userDao.updateUserPassword(_owner!.id, _passBaruC.text.trim());
            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan'))); Navigator.pop(context); }
            setState(() => _loading = false);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), child: _loading? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN PERUBAHAN'))),
        ]),
      ),
    );
  }
}