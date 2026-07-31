import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/config.dart';
import 'features/auth/presentation/pages/login_main_page.dart';
import 'core/database/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // RANDOM 20 TEMA DARI config.dart
  final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
  debugPrint('✨ Tema hari ini: ${randomTheme.name} [${AppThemes.allThemes.length} tema]');

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // AppBar otomatis ngikutin tema gelap/terang biar font kebaca
        backgroundColor: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.75),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PUTRA SURABAYA - iPOS 5',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      // INI PINTU UTAMA 3 ROLE: OWNER / ADMIN / SALESMAN
      body: const LoginMainPage(),
    );
  }
}