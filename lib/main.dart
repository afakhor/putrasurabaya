import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/local_database.dart';
import 'core/firebase/firebase_option.dart';
import 'core/services/sync_service.dart';
import 'features/pos/pos_page.dart';
import 'features/product/product_page.dart';
import 'features/product/product_form_provider.dart';
import 'features/stock/stock_mutation_page.dart';

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return {
    'uid': 'kasir_01',
    'name': 'Ahmad Fauzi',
    'role': 'owner',
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
    final List<Widget> pages = [
      const DashboardPage(),
      const StockMutationPage(),
      const ProductPage(),
      const Center(child: Text('Laporan Keuangan (Owner Only)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('UD. PUTRA SURABAYA IPOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF007F00),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(navbarIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF007F00),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off), label: 'Mutasi Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Katalog'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Laporan'),
        ],
      ),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat Datang,', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('UD. Putra Surabaya Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Menu Utama Kasir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const POSPage())),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(color: const Color(0xFF00A65A), borderRadius: BorderRadius.circular(12)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 38, color: Colors.white),
                      SizedBox(height: 8),
                      Text('Scan QRIS Bayar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              _buildMenuShortcut(icon: Icons.storefront, label: 'Kelola Katalog', onTap: () => ref.read(navbarIndexProvider.notifier).state = 2),
              _buildMenuShortcut(icon: Icons.history_toggle_off, label: 'Kartu Stok', onTap: () => ref.read(navbarIndexProvider.notifier).state = 1),
              _buildMenuShortcut(icon: Icons.analytics, label: 'Cek Laporan', onTap: () => ref.read(navbarIndexProvider.notifier).state = 3),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildMenuShortcut({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 34, color: const Color(0xFF007F00)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))],
        ),
      ),
    );
  }
}