import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/config.dart';
import 'core/database/local_database.dart';
import 'core/database/tables/user_table.dart';
import 'features/auth/login_main_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/rooms/superuser_shell.dart';
import 'features/auth/rooms/admin_shell.dart';
import 'features/auth/rooms/salesman_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
  runApp(ProviderScope(child: MyApp(initialTheme: randomTheme)));
}

class MyApp extends StatelessWidget {
  final AppTheme initialTheme;
  const MyApp({super.key, required this.initialTheme});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UD PUTRA KASIR',
      theme: initialTheme.themeData,
      home: initialTheme.backgroundBuilder(child: const AppEntry()),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Loading
    if (authState.isLoading) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    }

    // BELUM LOGIN - tampilkan Login + AppBar Putra Surabaya
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          title: const Text('PUTRA SURABAYA - iPOS 5', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        ),
        body: const LoginMainPage(),
      );
    }

    // SUDAH LOGIN - langsung ke Shell masing2, JANGAN pakai Scaffold lagi
    // Biar AppBar settings & logout di Shell yang kepakai
    switch (currentUser.role) {
      case UserRole.owner:
      case UserRole.superuser:
        return const SuperuserShell();
      case UserRole.admin:
      case UserRole.kasir:
        return const AdminShell();
      case UserRole.salesman:
        return SalesmanShell(user: currentUser);
      default:
        return const LoginMainPage();
    }
  }
}