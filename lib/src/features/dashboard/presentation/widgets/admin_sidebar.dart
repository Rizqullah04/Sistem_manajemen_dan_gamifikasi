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
    final currentPath = GoRouterState.of(context).uri.path;

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
                  selected:
                      dashboardHomeRoute(user?.role) == currentPath,
                  onTap: () {
                    final route = dashboardHomeRoute(user?.role);
                    if (route == null) return;
                    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    context.go(route);
                  },
                ),
              if (user?.role == UserRole.ormawaAccount)
                _buildMenuItem(
                  context,
                  icon: Icons.groups_outlined,
                  label: 'Anggota Ormawa',
                  selected: currentPath == '/ormawa/members',
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
                  selected: currentPath == '/admin/ormawas',
                  onTap: () {
                    _closeDrawerAndPush(context, '/admin/ormawas');
                  },
                ),
              if (user?.role == UserRole.adminFaculty)
                _buildMenuItem(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Manajemen Mahasiswa',
                  selected: currentPath == '/admin/students',
                  onTap: () {
                    _closeDrawerAndPush(context, '/admin/students');
                  },
                ),
              if (user != null) _buildGamificationMenu(context),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
                selected: currentPath == '/settings',
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
                selected: currentPath == '/activities',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/activities');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.how_to_vote_rounded,
                label: 'Voting',
                selected: currentPath == '/voting',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/voting');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                label: 'Profil',
                selected: currentPath == '/profile',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/profile');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.leaderboard_outlined,
                label: 'Leaderboard',
                selected: currentPath == '/leaderboard',
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  context.push('/leaderboard');
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

  Widget _buildGamificationMenu(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isAdmin = user?.role == UserRole.adminFaculty;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.workspace_premium_outlined, size: 20),
        title: Text(
          isAdmin ? 'Manajemen Gamifikasi' : 'Menu Gamifikasi',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        children: [
          if (!isAdmin)
            _buildSubMenuItem(
              context,
              icon: Icons.military_tech_outlined,
              label: 'Point dan Badge',
              selected: currentPath == '/gamification/points-badges',
              onTap: () =>
                  _closeDrawerAndPush(context, '/gamification/points-badges'),
            ),
          if (isAdmin)
            _buildSubMenuItem(
              context,
              icon: Icons.military_tech_outlined,
              label: 'Pengaturan Lencana (Badges)',
              selected: currentPath == '/admin/gamification/badges',
              onTap: () =>
                  _closeDrawerAndPush(context, '/admin/gamification/badges'),
            ),
          if (isAdmin)
            _buildSubMenuItem(
              context,
              icon: Icons.data_exploration_outlined,
              label: 'Audit Gamifikasi',
              selected: currentPath == '/admin/data-management',
              onTap: () =>
                  _closeDrawerAndPush(context, '/admin/data-management'),
            ),
          if (isAdmin)
            _buildSubMenuItem(
              context,
              icon: Icons.emoji_events_outlined,
              label: 'Penilaian Ormawa Awards',
              selected: currentPath == '/admin/ormawa-awards',
              onTap: () => _closeDrawerAndPush(context, '/admin/ormawa-awards'),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Card(
      color: selected ? const Color(0xFF6D28D9) : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedColor: Colors.white,
        iconColor: selected ? Colors.white : null,
        textColor: selected ? Colors.white : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, size: 20),
        title: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.w800 : null,
              ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      leading: Icon(icon, size: 18),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w800 : null,
            ),
      ),
      onTap: onTap,
    );
  }

  void _closeDrawerAndPush(BuildContext context, String route) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    context.push(route);
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
