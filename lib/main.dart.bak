import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_option.dart';
import 'core/services/sync_service.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/pos/pos_page.dart';
import 'features/product/product_page.dart';
import 'features/stock/stock_mutation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Buat ProviderContainer manual untuk Riverpod
  final container = ProviderContainer();

  // 3. Jalankan listener sinkronisasi sebelum UI muncul
  container.read(syncServiceProvider).startListening();

  // 4. Jalankan aplikasi menggunakan UncontrolledProviderScope
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
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
    // Jalankan sinkronisasi awal saat aplikasi dibuka
    Future.microtask(() async {
      try {
        await ref.read(syncServiceProvider).syncLocalToCloud();
      } catch (e) {
        debugPrint('⚠️ Sinkronisasi awal gagal: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'UD. Putra Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A65A)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      // Gerbang Otentikasi: Jika belum login/sesi habis -> AuthPage, jika sudah -> MainNavigationScreen
      home: authState.isAuthenticated
          ? const MainNavigationScreen()
          : const AuthPage(),
    );
  }
}

/// Provider Index Navigasi Utama
final navbarIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navbarIndexProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.currentUser;
    final bool isHome = selectedIndex == 0;

    // Daftar Halaman Modul Utama
    final List<Widget> pages = [
      const PosPage(),
      const StockMutationPage(),
      const ProductPage(),
      // Halaman Laporan Keuangan dengan Pengecekan RBAC
      authState.canReviewOmsetAndSales
          ? const Center(
              child: Text(
                'Laporan Keuangan & Omset (Owner/Admin)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Akses Dibatasi!\nHanya Owner atau Admin yang dapat melihat Laporan Keuangan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'UD. PUTRA SURABAYA IPOS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            if (currentUser != null)
              Text(
                'Staf: ${currentUser.name} (${authState.role.name.toUpperCase()})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF007F00),
        centerTitle: true,
        toolbarHeight: 52,
        actions: [
          IconButton(
            tooltip: 'Switch User / Log Out',
            icon: const Icon(Icons.switch_account_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: pages[selectedIndex < pages.length ? selectedIndex : 0],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isHome
          ? Container(
              width: 68,
              height: 68,
              margin: const EdgeInsets.only(top: 10),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00A65A),
                shape: const CircleBorder(),
                elevation: 4,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pemindai QRIS Aktif'),
                      backgroundColor: Color(0xFF007F00),
                    ),
                  );
                },
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                    Text(
                      'QRIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomAppBar(
        shape: isHome ? const CircularNotchedRectangle() : null,
        notchMargin: isHome ? 8 : 0,
        color: const Color(0xFF007F00),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                ref,
                icon: Icons.point_of_sale,
                label: 'POS',
                index: 0,
                selectedIndex: selectedIndex,
              ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.history,
                label: 'Mutasi',
                index: 1,
                selectedIndex: selectedIndex,
              ),
              if (isHome) const SizedBox(width: 40),
              _buildNavItem(
                context,
                ref,
                icon: Icons.storefront,
                label: 'Katalog',
                index: 2,
                selectedIndex: selectedIndex,
              ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.analytics,
                label: 'Laporan',
                index: 3,
                selectedIndex: selectedIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => ref.read(navbarIndexProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.amber : Colors.white,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.amber : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
