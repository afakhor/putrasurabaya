import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/config.dart';
import '../auth_provider.dart';
import '../login_main_page.dart';
import '../superuser/dashboard_owner_page.dart';
import '../superuser/manage_users_page.dart';
import '../superuser/audit_fraud_page.dart';
import '../superuser/master_data_page.dart';
import '../superuser/owner_settings_page.dart';
import '../superuser/report_page.dart'; // bikin file baru untuk laporan

class SuperuserShell extends ConsumerStatefulWidget {
  const SuperuserShell({super.key});
  @override
  ConsumerState<SuperuserShell> createState() => _SuperuserShellState();
}

class _SuperuserShellState extends ConsumerState<SuperuserShell> {
  int _index = 0;

  // 5 TAB UTAMA SAJA
  final List<Widget> _pages = const [
    DashboardOwnerPage(),
    ManageUsersPage(), // di dalamnya ada akses ke DetailSalesman & ManagePermission
    AuditFraudPage(),
    MasterDataPage(),
    ReportPage(), // ganti placeholder-mu
  ];

  Future<void> _doLogout() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari sistem superuser?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginMainPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: surfaceColor.withOpacity(isDark ? 0.6 : 0.75),
              elevation: 0,
              title: Row(children: [
                const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SUPERUSER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: isDark? Colors.white70: Colors.black54)),
                  Text(user?.name ?? 'Owner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins', color: isDark? Colors.white: Colors.black87)),
                ])
              ]),
              actions: [
                // 6. OWNER SETTING ADA DI SINI
                IconButton(icon: Icon(Icons.settings_outlined, color: iconColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerSettingsPage()))),
                IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _doLogout),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(color: surfaceColor.withOpacity(isDark ? 0.7 : 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white12 : Colors.black12)),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0, height: 65, selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                  NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Akses'),
                  NavigationDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security), label: 'Audit'),
                  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Master'),
                  NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Laporan'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}