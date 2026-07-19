import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/local_database.dart';
import 'core/firebase/firebase_option.dart'; 
import 'core/services/sync_service.dart';
import 'features/pos/pos_page.dart';
import 'features/product/product_page.dart';
import 'features/stock/stock_mutation_page.dart'; // Menghubungkan modul mutasi stock baru

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return {
    'uid': 'kasir_01',
    'name': 'Ahmad Fauzi',
    'role': 'owner',        // Ubah string ke 'salesman' untuk mensimulasikan uji batas RBAC aman
    'canEditPrice': true,
    'canDeleteTransaction': false
  };
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // List Halaman Aplikasi Komplit Terintegrasi Tab Bar
    final List<Widget> pages = [
      const Center(child: Text('Dashboard Toko (Home)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const StockMutationPage(), // Index 1 Dialokasikan Untuk Modul Mutasi & Kartu Stok Inventaris
      const ProductPage(), 
      const Center(child: Text('Laporan Keuangan (Owner Only)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const POSPage(), 
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIndex == 4 ? 'KASIR UTAMA POS' : 'UD. PUTRA SURABAYA IPOS',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007F00),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF00A65A),
        foregroundColor: Colors.white,
        onPressed: () => ref.read(navbarIndexProvider.notifier).state = 4,
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                  icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.amber : Colors.white, size: 26),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 0,
                ),
                const SizedBox(width: 20),
                IconButton(
                  tooltip: 'Mutasi Stok',
                  icon: Icon(Icons.history_toggle_off, color: selectedIndex == 1 ? Colors.amber : Colors.white, size: 26),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 1,
                ),
              ],
            ),
            const SizedBox(width: 40), 
            Row(
              children: [
                IconButton(
                  tooltip: 'Katalog Produk',
                  icon: Icon(Icons.storefront, color: selectedIndex == 2 ? Colors.amber : Colors.white, size: 26),
                  onPressed: () => ref.read(navbarIndexProvider.notifier).state = 2,
                ),
                const SizedBox(width: 20),
                IconButton(
                  tooltip: 'Analisa Laporan',
                  icon: Icon(Icons.analytics, color: selectedIndex == 3 ? Colors.amber : Colors.white, size: 26),
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
