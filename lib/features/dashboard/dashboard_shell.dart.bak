import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/features/auth/auth_page.dart';
import 'package:ud_putra_kasir/features/auth/auth_provider.dart';

/// Item Navigasi Internal dengan Batas Hak Akses
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final bool isVisible;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
    required this.isVisible,
  });
}

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // 1. JIKA BELUM AUTHENTICATED -> TAMPILKAN AUTH PAGE DIRECTLY
    if (!authState.isAuthenticated) {
      return const AuthPage();
    }

    final currentUser = authState.currentUser!;
    final role = authState.role;

    // 2. DAFTAR MENU DINAMIS BERDASARKAN HAK AKSES (ROLE PERMISSIONS)
    final List<NavItem> navItems = [
      // Tab 1: Kasir POS (Semua Role: Owner, Admin, Salesman)
      NavItem(
        label: 'Kasir POS',
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded,
        page: const _PlaceholderPage(
          title: 'Halaman Kasir POS',
          icon: Icons.point_of_sale_rounded,
          description: 'Area transaksi penjualan, scan barcode, dan cetak nota.',
        ),
        isVisible: authState.canAccessPos,
      ),

      // Tab 2: Katalog & Stok (Owner & Admin)
      NavItem(
        label: 'Katalog & Stok',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        page: const _PlaceholderPage(
          title: 'Manajemen Stok & Produk',
          icon: Icons.inventory_2_rounded,
          description: 'Tambah/edit barang, atur harga tier 1-3, dan cek stok opname.',
        ),
        isVisible: authState.canManageMasterData,
      ),

      // Tab 3: Laporan Penjualan & Omset (Owner & Admin)
      NavItem(
        label: 'Laporan',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        page: const _PlaceholderPage(
          title: 'Laporan Omset & Keuangan',
          icon: Icons.bar_chart_rounded,
          description: 'Review omset bulanan, piutang pelanggan, dan laba kotor.',
        ),
        isVisible: authState.canReviewOmsetAndSales,
      ),

      // Tab 4: Kelola User & API Key (Khusus Owner)
      NavItem(
        label: 'Akses Staf',
        icon: Icons.key_outlined,
        activeIcon: Icons.key_rounded,
        page: const _PlaceholderPage(
          title: 'Kelola Pengguna & API Key',
          icon: Icons.key_rounded,
          description: 'Generate API Key untuk Admin/Salesman dan atur hak akses.',
        ),
        isVisible: authState.canGenerateApiKeys,
      ),

      // Tab 5: Profil & Switch User (Semua Role)
      NavItem(
        label: 'Akun / Switch',
        icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts_rounded,
        page: const AuthPage(),
        isVisible: true,
      ),
    ];

    // Filter hanya menu yang diizinkan untuk role pengguna saat ini
    final visibleItems = navItems.where((item) => item.isVisible).toList();

    // Pencegahan Index Out of Bounds jika user berpindah role
    if (_selectedIndex >= visibleItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      // =======================================================================
      // APP BAR ATAS: BRANDING & IDENTITAS AKUN
      // =======================================================================
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'UD. Putra Surabaya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          // Indicator Status Koneksi Offline/Online
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.green.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline DB Ready',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // User Info & Role Badge
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      role.toFormattedString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getRoleColor(role).withOpacity(0.2),
                  child: Icon(
                    _getRoleIcon(role),
                    size: 18,
                    color: _getRoleColor(role),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // =======================================================================
      // BODY RESPONSIF (NAVIGATION RAIL vs BOTTOM NAV BAR)
      // =======================================================================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 720;

          if (isWideScreen) {
            // Tampilan Tablet / Layar Lebar dengan NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: Colors.blue.shade800),
                  selectedLabelTextStyle: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                  destinations: visibleItems.map((item) {
                    return NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: visibleItems.map((e) => e.page).toList(),
                  ),
                ),
              ],
            );
          } else {
            // Tampilan Mobile / HP dengan BottomNavigationBar
            return IndexedStack(
              index: _selectedIndex,
              children: visibleItems.map((e) => e.page).toList(),
            );
          }
        },
      ),

      // Bottom Nav Bar hanya untuk Layar Sempit / HP
      bottomNavigationBar: MediaQuery.of(context).size.width < 720
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              indicatorColor: Colors.blue.shade100,
              destinations: visibleItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.amber.shade900;
      case UserRole.admin:
        return Colors.indigo.shade700;
      case UserRole.salesman:
        return Colors.teal.shade700;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.admin_panel_settings_rounded;
      case UserRole.admin:
        return Icons.supervisor_account_rounded;
      case UserRole.salesman:
        return Icons.point_of_sale_rounded;
    }
  }
}

/// Widget Placeholder Temp untuk Halaman Modul
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
