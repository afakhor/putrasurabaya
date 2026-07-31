import 'package:flutter/material.dart';
import 'dart:math';
import 'core/utils/config.dart'; // sesuaikan path kamu

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // PICK RANDOM TEMA SETIAP KALI APP DIBUKA
  final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
  
  // Print buat debug biar tau dapet tema apa
  debugPrint('✨ Tema hari ini: ${randomTheme.name}');

  runApp(MyApp(initialTheme: randomTheme));
}

class MyApp extends StatelessWidget {
  final AppTheme initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Viral',
      theme: initialTheme.themeData,
      home: initialTheme.backgroundBuilder(
        child: const MyHomePage(),
      ),
    );
  }
}

// CONTOH HALAMAN UTAMA
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // WAJIB transparan biar background keliatan
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.6),
        elevation: 0,
        title: const Text('Halo, Cantik! ✨', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tema random aktif!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tutup & buka lagi aplikasinya untuk ganti tema lain.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}