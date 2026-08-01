import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/config.dart';
import 'core/database/tables/user_table.dart'; // <-- INI WAJIB BIAR UserData & UserRole KEDETEK
import 'features/auth/login_main_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/rooms/superuser_shell.dart';
import 'features/auth/rooms/admin_shell.dart';
import 'features/auth/rooms/salesman_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
  debugPrint('✨ Tema hari ini: ${randomTheme.name} | Total: ${AppThemes.allThemes.length} tema');

  runApp(
    ProviderScope(
      child: MyApp(initialTheme: randomTheme),
    ),
  );
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
      home: initialTheme.backgroundBuilder(
        child: const AppEntry(),
      ),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.75),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          currentUser == null ? 'PUTRA SURABAYA - iPOS 5' : '${currentUser.role.toUpperCase()}: ${currentUser.name}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Icon(Icons.logout, color: isDark ? Colors.white : Colors.black),
              onPressed: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
        ],
      ),
      body: _buildBody(authState, currentUser),
    );
  }

 
Widget _buildBody(AsyncValue<UserData?> authState, UserData? user) {
  if (authState.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (user == null) {
    return const LoginMainPage();
  }
  switch (user.role) {
    case UserRole.owner:
    case UserRole.superuser:
      return const SuperuserShell();
    case UserRole.admin:
    case UserRole.kasir:
      return const AdminShell();
    case UserRole.salesman:
      return SalesmanShell(user: user);
    default:
      return const LoginMainPage();
  }
}