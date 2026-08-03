import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/config.dart';
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
      builder: (context, child) {
        // INI KUNCI: Background di apply di level MaterialApp builder, jadi semua Scaffold transparent bisa tembus
        return initialTheme.backgroundBuilder(child: child?? const SizedBox());
      },
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (sessionAsync.isLoading || authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final activeUser = currentUser?? sessionAsync.value;
    if (activeUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: const LoginMainPage()),
      );
    }
    switch (activeUser.appRole) {
      case AppRole.superuser: return const SuperuserShell();
      case AppRole.admin: case AppRole.kasir: return const AdminShell();
      case AppRole.salesman: return SalesmanShell(user: activeUser);
    }
  }
}