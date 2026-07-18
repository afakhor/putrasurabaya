import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/firebase/firebase_options.dart'; 
import 'core/sync/sync_service.dart';
import 'features/pos/pos_page.dart';
import 'features/product/product_page.dart';

// Provider RBAC Pengguna Aktif (Simulasi login / Realtime Role dari Firestore)
final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return {
    'uid': 'kasir_01',
    'name': 'Ahmad Fauzi',
    'role': 'owner',        // Opsi: 'owner', 'salesman', 'kasir'
    'canEditPrice': true,
    'canDeleteTransaction': false
  };
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menginisialisasi Firebase Server sebelum aplikasi dirender
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jalankan auto-listener konektivitas internet untuk background sync
    ref.read(syncServiceProvider).startListening();

    return MaterialApp(
      title: 'UD. Putra Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A65A)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

final navbarIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navbarIndexProvider);

    // List Halaman Terintegrasi (Index 4 dikhususkan untuk POS Kasir Utama)
    final List<Widget> pages = [
      const Center(child: Text('Dashboard Toko (Home)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const Center(child: Text('Riwayat Transaksi Penjualan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const ProductPage(), 
      const Center(child: Text('Laporan Keuangan (Owner Only)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const POSPage(), 
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIndex == 4 ? 'Kasir Kasir Utama' : 'UD. Putra Surabaya',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007F00),
        centerTitle: true,
      ),
      body: pages[selectedIndex],

      // DOCKED NOTCHED FAB: Akses langsung ke POS Utama dengan ikon QR/Scanner
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF00A65A),
        foregroundColor: Colors.white,
        onPressed: () {
          // Mengalihkan view aktif langsung ke halaman Kasir Utama POS (Index 4)
          ref.read(navbarIndexProvider.notifier).state = 4;
        },
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // NOTCHED BOTTOM BAR: Lengkungan presisi mengapit tombol kasir utama
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF007F00), 
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Beranda',
                  icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 0,
                ),
                const SizedBox(width: 24),
                IconButton(
                  tooltip: 'Transaksi',
                  icon: Icon(Icons.receipt_long, color: selectedIndex == 1 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 1,
                ),
              ],
            ),
            const SizedBox(width: 48), // Ruang kosong untuk Notch FAB
            Row(
              children: [
                IconButton(
                  tooltip: 'Data Produk',
                  icon: Icon(Icons.storefront, color: selectedIndex == 2 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 2,
                ),
                const SizedBox(width: 24),
                IconButton(
                  tooltip: 'Laporan',
                  icon: Icon(Icons.analytics, color: selectedIndex == 3 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
