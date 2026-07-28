import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'auth_provider.dart';

/// Stream Provider untuk memuat daftar seluruh user aktif dari SQLite
final usersListProvider = StreamProvider.autoDispose<List<UserData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return (db.select(db.users)
        ..where((tbl) => tbl.status.equals('aktif')))
      .watch();
});

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final usersAsync = ref.watch(usersListProvider);

    // Listener untuk menampilkan error snackbar & penanganan setelah login
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===========================================================
                  // HEADER BRANDING
                  // ===========================================================
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // ===========================================================
                  // BANNER AKUN AKTIF (JIKA SUDAH LOGIN)
                  // ===========================================================
                  if (authState.isAuthenticated) ...[
                    _buildActiveUserCard(context, ref, authState),
                    const SizedBox(height: 24),
                  ],

                  // ===========================================================
                  // DAFTAR PILIH AKUN / SWITCH USER
                  // ===========================================================
                  const Text(
                    'Pilih Akun Pengguna / Switch User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: usersAsync.when(
                      data: (users) {
                        if (users.isEmpty) {
                          return _buildEmptyUserView();
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsif Grid/List berdasarkan lebar layar (Tablet/HP)
                            final isWide = constraints.maxWidth > 550;
                            return GridView.builder(
                              itemCount: users.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 2 : 1,
                                childAspectRatio: isWide ? 2.8 : 3.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final isCurrent = authState.currentUser?.id == user.id;

                                return _buildUserCard(
                                  context: context,
                                  ref: ref,
                                  user: user,
                                  isCurrent: isCurrent,
                                  isLoading: authState.isLoading,
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(
                        child: Text('Gagal memuat pengguna: $err'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header Toko UD. Putra Surabaya
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'UD. PUTRA SURABAYA',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Color(0xFF1E293B),
          ),
        ),
        const Text(
          'Sistem Kasir POS & Inventaris Grosir',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  /// Card Pengguna yang sedang Aktif Login
  Widget _buildActiveUserCard(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    final user = authState.currentUser!;
    final role = authState.role;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getRoleColor(role).withOpacity(0.15),
            child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sesi Aktif • ID: ${user.id}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
            ),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  /// Card Item Pengguna dalam Grid/List
  Widget _buildUserCard({
    required BuildContext context,
    required WidgetRef ref,
    required UserData user,
    required bool isCurrent,
    required bool isLoading,
  }) {
    final role = UserRole.fromString(user.role);
    final roleColor = _getRoleColor(role);

    return Card(
      elevation: isCurrent ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      color: isCurrent ? Colors.blue.shade50.withOpacity(0.5) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading || isCurrent
            ? null
            : () async {
                final success = await ref
                    .read(authNotifierProvider.notifier)
                    .loginWithUser(user.id);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil masuk sebagai ${user.name} (${role.toFormattedString()})'),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withOpacity(0.12),
                child: Icon(_getRoleIcon(role), color: roleColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.toFormattedString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const Chip(
                  label: Text('Aktif', style: TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              else
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUserView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Belum ada akun terdaftar.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Custom Badge Role
  Widget _buildRoleBadge(UserRole role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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
