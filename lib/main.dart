import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_option.dart';
import 'core/services/sync_service.dart';
import 'features/pos/pos_page.dart';
import 'features/product/product_page.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncServiceProvider).startListening());
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UD. Putra Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A65A)), useMaterial3: true),
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

    // 0=POS (Beranda), 1=Mutasi, 2=Katalog, 3=Laporan
    final List<Widget> pages = [
      const POSPage(), // <-- BERANDA LANGSUNG POS
      const StockMutationPage(),
      const ProductPage(),
      const Center(child: Text('Laporan Keuangan (Owner Only)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('UD. PUTRA SURABAYA IPOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        backgroundColor: const Color(0xFF007F00),
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: pages[selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 72, height: 72,
        margin: const EdgeInsets.only(top: 10),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF00A65A),
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: () {
            // Tombol QRIS tengah - langsung ke dialog bayar QRIS
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QRIS Scanner - hubungkan ke payment gateway kamu'), backgroundColor: Color(0xFF007F00)));
            // Kalau mau langsung buka POSPage fokus QR, cukup:
            ref.read(navbarIndexProvider.notifier).state = 0;
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
              Text('QRIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF007F00),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, ref, icon: Icons.point_of_sale, label: 'POS', index: 0, selectedIndex: selectedIndex),
              _buildNavItem(context, ref, icon: Icons.history, label: 'Mutasi', index: 1, selectedIndex: selectedIndex),
              const SizedBox(width: 40), // space untuk FAB tengah
              _buildNavItem(context, ref, icon: Icons.storefront, label: 'Katalog', index: 2, selectedIndex: selectedIndex),
              _buildNavItem(context, ref, icon: Icons.analytics, label: 'Laporan', index: 3, selectedIndex: selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, {required IconData icon, required String label, required int index, required int selectedIndex}) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => ref.read(navbarIndexProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected? Colors.amber : Colors.white, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected? FontWeight.bold : FontWeight.normal, color: isSelected? Colors.amber : Colors.white)),
        ],
      ),
    );
  }
}