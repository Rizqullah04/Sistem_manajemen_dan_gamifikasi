import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({
    required this.user,
    required this.onLogout,
    required this.onEditProfile,
    super.key,
  });

  final User? user;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = user?.name ?? 'Pengguna';
    final roleLabel = _roleLabel(user?.role);
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.studentStaffId,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onEditProfile,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profil'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              // Menu Items
              Text(
                'Menu',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (dashboardHomeRoute(user?.role) != null)
                _buildMenuItem(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Dashboard',
                  onTap: () {
                    final route = dashboardHomeRoute(user?.role);
                    if (route == null) return;
                    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    context.go(route);
                  },
                ),
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                label: 'Profil',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/profile');
                },
              ),
              if (user?.role == UserRole.ormawaAccount)
                _buildMenuItem(
                  context,
                  icon: Icons.groups_outlined,
                  label: 'Anggota Ormawa',
                  onTap: () {
                    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    context.push('/ormawa/members');
                  },
                ),
              if (user?.role == UserRole.adminFaculty)
                _buildMenuItem(
                  context,
                  icon: Icons.apartment_rounded,
                  label: 'Data Ormawa',
                  onTap: () {
                    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    context.push('/admin/ormawas');
                  },
                ),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/settings');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.event_note_outlined,
                label: 'Kegiatan',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/activities');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.leaderboard_outlined,
                label: 'Leaderboard',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/leaderboard');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.emoji_events_outlined,
                label: 'Achievement',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/achievement');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.how_to_vote_outlined,
                label: 'Voting',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/voting');
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, size: 20),
        title: Text(label, style: Theme.of(context).textTheme.labelLarge),
        onTap: onTap,
      ),
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.adminFaculty:
        return 'Admin';
      case UserRole.ormawaAccount:
        return 'Ormawa';
      case UserRole.memberAccount:
        return 'Student';
      case null:
        return 'Belum login';
    }
  }
}
