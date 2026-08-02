import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../superuser/dashboard_owner_page.dart';
import '../superuser/manage_users_page.dart';
import '../superuser/audit_fraud_page.dart';
import '../superuser/master_data_page.dart';
import '../superuser/owner_settings_page.dart';
import '../auth_provider.dart';
import '../login_main_page.dart';

class SuperuserShell extends ConsumerStatefulWidget {
  const SuperuserShell({super.key});
  @override
  ConsumerState<SuperuserShell> createState() => _SuperuserShellState();
}

class _SuperuserShellState extends ConsumerState<SuperuserShell> {
  int _index = 0;

  final _pages = const [
    DashboardOwnerPage(),
    ManageUsersPage(),
    AuditFraudPage(),
    MasterDataPage(),
    Center(child: Text('Laporan & Tutup Buku', style: TextStyle(color: Colors.black))),
  ];

  Future<void> _doLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Logout?', style: TextStyle(color: Colors.black)),
        content: const Text('Yakin mau keluar dari Superuser?', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text('SUPERUSER: ${user?.name ?? ''}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87, size: 26),
            tooltip: 'Ganti Username & Password',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerSettingsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 26),
            tooltip: 'Logout',
            onPressed: _doLogout,
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          border: const Border(top: BorderSide(color: Colors.black12)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.black,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined, color: Colors.black87, size: 26), selectedIcon: Icon(Icons.dashboard, color: Colors.white, size: 26), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.black87, size: 26), selectedIcon: Icon(Icons.people, color: Colors.white, size: 26), label: 'User & Akses'),
            NavigationDestination(icon: Icon(Icons.security_outlined, color: Colors.black87, size: 26), selectedIcon: Icon(Icons.security, color: Colors.white, size: 26), label: 'Audit'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined, color: Colors.black87, size: 26), selectedIcon: Icon(Icons.inventory_2, color: Colors.white, size: 26), label: 'Master'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined, color: Colors.black87, size: 26), selectedIcon: Icon(Icons.bar_chart, color: Colors.white, size: 26), label: 'Laporan'),
          ],
        ),
      ),
    );
  }
}