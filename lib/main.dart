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
    // 1. CEK SESSION PERSISTEN DULU SAAT STARTUP
    final sessionAsync = ref.watch(authSessionProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Loading awal cek SharedPreferences
    if (sessionAsync.isLoading || authState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    // 2. TENTUKAN USER AKTIF (dari session atau dari login baru)
    final activeUser = currentUser ?? sessionAsync.value;

    // 3. BELUM LOGIN
    if (activeUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          title: const Text('PUTRA SURABAYA - iPOS 5',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black)),
        ),
        body: const LoginMainPage(),
      );
    }

    // 4. SUDAH LOGIN - SEKALI LOGIN UNTUK SETERUSNYA KECUALI LOGOUT
    switch (activeUser.appRole) {
      case AppRole.superuser:
        return const SuperuserShell();
      case AppRole.admin:
      case AppRole.kasir:
        return const AdminShell();
      case AppRole.salesman:
        return SalesmanShell(user: activeUser);
    }
  }
}