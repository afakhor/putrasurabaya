import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/pos/pos_page.dart';
import 'core/database/app_database.dart';

// Provider database global
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// PROVIDER SIMULASI USER LOGIN (Hubungkan ke Firebase Auth & Firestore nanti)
// Nilai Peran: 'owner' atau 'salesman'
// Nilai Status: 'active' atau 'suspended'
final currentUserProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'name': 'Ahmad Salesman',
  'role': 'salesman', 
  'status': 'active', // Ubah ke 'suspended' untuk tes fitur blokir otomatis
  'canEditPrice': false, // Batasan harga bagi sales
  'canDeleteTransaction': false,
});

// Provider Index Navbar aktif
final navbarIndexProvider = StateProvider<int>((ref) => 0);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UD. Putra Surabaya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[800]!),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// HARAPAN ANDA: NAVBAR SIMPEL UNTUK MENGONTROL SELURUH HALAMAN
class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(navbarIndexProvider);

    // KONTROL 1: JIKA USER DI-SUSPEND, KUNCI TOTAL APLIKASI SAAT ITU JUGA
    if (user['status'] == 'suspended') {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.red, size: 80),
                SizedBox(height: 16),
                Text(
                  'AKSES DITOLAK',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  'Akun Anda telah dinonaktifkan oleh Owner.\nSilakan hubungi Owner UD. Putra untuk mengaktifkan kembali.',
                  textAlign: Center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // DAFTAR HALAMAN FITUR APLIKASI
    final List<Widget> pages = [
      const POSPage(), // Halaman Utama Kasir
      const Center(child: Text('Halaman Kelola Produk & Satuan')), // placeholder product
      const Center(child: Text('Halaman Riwayat Transaksi')), // placeholder transaction
      // KONTROL 2: Hanya Tampilkan halaman Management Staff jika Login Sebagai Owner
      if (user['role'] == 'owner')
        const Center(child: Text('Halaman Kelola & Suspend Salesman (Owner Only)')),
    ];

    return Scaffold(
      body: pages[currentIndex >= pages.length ? 0 : currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(navbarIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'POS Kasir'),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          if (user['role'] == 'owner') // NAVBAR KELOLA HANYA MUNCUL DI HP OWNER
            const BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Kelola Sales'),
        ],
      ),
    );
  }
}
