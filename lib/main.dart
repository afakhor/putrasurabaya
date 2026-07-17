import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/pos/pos_page.dart';
import 'core/database/app_database.dart';

void main() {
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

// State Provider untuk mengontrol index halaman aktif
final navbarIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navbarIndexProvider);

    // List Halaman Aplikasi (Tanpa Side Drawer)
    final List<Widget> pages = [
      const Center(child: Text('Dashboard Toko (Home)', style: TextStyle(fontSize: 20))),
      const Center(child: Text('Transaksi Penjualan', style: TextStyle(fontSize: 20))),
      const ProductPage(), // Halaman Produk Utama Terintegrasi di sini
      const Center(child: Text('Laporan Keuangan', style: TextStyle(fontSize: 20))),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      // 1. DOCKED FAB DI TENGAH BOTTOM BAR (Untuk Aksi Cepat / Menu Kasir POS)
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF00A65A),
        foregroundColor: Colors.white,
        onPressed: () {
          // Aksi cepat: misal langsung buka Kamera scanner kasir / POS Baru
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Membuka Kamera POS Scanner Kasir...')),
          );
        },
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 2. NOTCHED BOTTOM APP BAR (Desain melengkung di tempat FAB bersandar)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF007F00), // Warna hijau gelap khas UD. Putra
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bagian Kiri FAB (Tab 0 dan 1)
            Row(
              children: [
                IconButton(
                  tooltip: 'Beranda',
                  icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 0,
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: 'Transaksi',
                  icon: Icon(Icons.receipt_long, color: selectedIndex == 1 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 1,
                ),
              ],
            ),
            
            // Spacer untuk memberi ruang lekukan FAB di tengah
            const SizedBox(width: 48),

            // Bagian Kanan FAB (Tab 2 dan 3)
            Row(
              children: [
                IconButton(
                  tooltip: 'Data Produk',
                  icon: Icon(Icons.storefront, color: selectedIndex == 2 ? Colors.amber : Colors.white, size: 28),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 2,
                ),
                const SizedBox(width: 16),
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
