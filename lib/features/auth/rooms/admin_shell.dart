import 'package:flutter/material.dart';
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('ADMIN MODE')), body: const Center(child: Text('Halaman Roleplay Admin')));
  }
}