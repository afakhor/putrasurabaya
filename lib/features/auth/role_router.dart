import 'package:flutter/material.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/features/superuser/presentation/superuser_shell.dart';
import 'package:ud_putra_kasir/features/admin/presentation/admin_shell.dart';
import 'package:ud_putra_kasir/features/salesman/presentation/salesman_shell.dart';

Widget getHomeByRole(UserData user) {
  final role = user.role.toLowerCase();
  if (role == 'superuser' || role == 'owner') return const SuperuserShell();
  if (role == 'admin') return const AdminShell();
  return SalesmanShell(user: user);
}