import 'package:flutter/material.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
class SalesmanShell extends StatelessWidget {
  final UserData user;
  const SalesmanShell({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('SALESMAN: ${user.name}')), body: Center(child: Text('Hak Akses: ${user.canVoidTransaction ? "Bisa Void" : "Tidak Bisa Void"}')));
  }
}