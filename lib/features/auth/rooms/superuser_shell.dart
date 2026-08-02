import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_provider.dart';
import '../login_main_page.dart';
import '../superuser/audit_fraud_page.dart';
import '../superuser/dashboard_owner_page.dart';
import '../superuser/manage_users_page.dart';
import '../superuser/master_data_page.dart';
import '../superuser/owner_settings_page.dart';

class SuperuserShell extends ConsumerStatefulWidget {
  const SuperuserShell({super.key});

  @override
  ConsumerState<SuperuserShell> createState() => _SuperuserShellState();
}

class _SuperuserShellState extends ConsumerState<SuperuserShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardOwnerPage(),
    ManageUsersPage(),
    AuditFraudPage(),
    MasterDataPage(),
    Center(
      child: Text(
        'Laporan & Tutup Buku',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  ];

  Future<void> _doLogout() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Logout',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sistem superuser?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Menyesuaikan warna berdasarkan mode terang/gelap dari tema acak
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final primaryColor = theme.primaryColor != Colors.blue
        ? theme.primaryColor
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: Colors.transparent, // Penting agar latar animasi blob terlihat
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: surfaceColor.withOpacity(isDark ? 0.65 : 0.75),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SUPERUSER',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          user?.name ?? 'Owner',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: iconColor, size: 22),
                  tooltip: 'Pengaturan Akun',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OwnerSettingsPage()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                  tooltip: 'Logout',
                  onPressed: _doLogout,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(isDark ? 0.70 : 0.80),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: primaryColor,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white54 : Colors.black54),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 22,
                      color: selected
                          ? (primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : iconColor,
                    );
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 65,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: 'Akses',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.security_outlined),
                      selectedIcon: Icon(Icons.security),
                      label: 'Audit',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: 'Master',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'Laporan',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
