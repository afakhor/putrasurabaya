import 'package:flutter/material.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/features/aut/rooms/superuser_shell.dart';
import 'package:ud_putra_kasir/features/auth/rooms/admin_shell.dart';
import 'package:ud_putra_kasir/features/auth/rooms/salesman_shell.dart';

Widget getHomeByRole(UserData user) {
  final role = user.role.toLowerCase();
  if (role == 'superuser' || role == 'owner') return const SuperuserShell();
  if (role == 'admin') return const AdminShell();
  return SalesmanShell(user: user);
}