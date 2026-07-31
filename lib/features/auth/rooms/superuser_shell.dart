import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/dashboard_owner_page.dart';
import '../pages/manage_users_page.dart';
import '../pages/audit_fraud_page.dart';
import '../pages/master_data_page.dart';
import '../../auth/providers/auth_provider.dart';

class SuperuserShell extends ConsumerStatefulWidget {
  const SuperuserShell({super.key});
  @override
  ConsumerState<SuperuserShell> createState() => _SuperuserShellState();
}

class _SuperuserShellState extends ConsumerState<SuperuserShell> {
  int _index = 0;

  final _pages = const [
    DashboardOwnerPage(),      // Tab 0: Omset + Indikator Hijau/Kuning/Merah
    ManageUsersPage(),         // Tab 1: Kelola User + Checklist Hak Akses
    AuditFraudPage(),          // Tab 2: Audit Trail Salesman
    MasterDataPage(),          // Tab 3: Produk, Kategori, Supplier
    Center(child: Text('Laporan & Tutup Buku')), // Tab 4: Nanti
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('SUPERUSER: ${user?.name ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            ref.read(authNotifierProvider.notifier).logout();
            Navigator.pushReplacementNamed(context, '/login');
          })
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people), label: 'User & Akses'),
          NavigationDestination(icon: Icon(Icons.security), label: 'Audit'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Master'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}