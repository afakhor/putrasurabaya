import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';

class OwnerSettingsPage extends ConsumerStatefulWidget {
  const OwnerSettingsPage({super.key});
  @override
  ConsumerState<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends ConsumerState<OwnerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _passLamaC = TextEditingController();
  final _passBaruC = TextEditingController();
  final _passUlangC = TextEditingController();
  bool _loading = false;
  UserData? _owner;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final db = ref.read(localDatabaseProvider);
    final owner = await db.userDao.getUserByRole('owner');
    if (owner != null) {
      setState(() {
        _owner = owner;
        _usernameC.text = owner.username ?? 'owner';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_owner == null) return;

    // validasi password lama
    if (_owner!.passwordHash != _passLamaC.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password lama salah!')));
      return;
    }
    if (_passBaruC.text != _passUlangC.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru tidak cocok!')));
      return;
    }

    setState(() => _loading = true);
    final db = ref.read(localDatabaseProvider);

    try {
      // 1. Update username
      await db.userDao.updateUserProfile(
        userId: _owner!.id,
        name: _owner!.name,
        username: _usernameC.text.trim(),
      );
      // 2. Update password kalau diisi
      if (_passBaruC.text.isNotEmpty) {
        await db.userDao.updateUserPassword(_owner!.id, _passBaruC.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil! Login baru: ${_usernameC.text} / ${_passBaruC.text.isEmpty ? _passLamaC.text : _passBaruC.text}')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Username & Password Owner')),
      body: _owner == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _usernameC,
                      decoration: const InputDecoration(labelText: 'Username Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.isEmpty ? 'Wajib isi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passLamaC,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password Lama (wajib)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock)),
                      validator: (v) => v!.isEmpty ? 'Wajib isi password lama' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passBaruC,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                      validator: (v) => v!.isNotEmpty && v.length < 4 ? 'Minimal 4 karakter' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passUlangC,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Ulang Password Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: _loading ? const CircularProgressIndicator() : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Text('Login saat ini: ${_owner!.username} / ${_owner!.passwordHash}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
    );
  }
}