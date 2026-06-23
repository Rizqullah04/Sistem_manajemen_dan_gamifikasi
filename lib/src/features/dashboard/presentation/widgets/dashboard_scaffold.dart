import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/admin_sidebar.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';

class DashboardScaffold extends ConsumerWidget {
  const DashboardScaffold({
    required this.title,
    required this.body,
    required this.onLogout,
    super.key,
  });

  final String title;
  final Widget body;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final width = MediaQuery.sizeOf(context).width;
    final showFixedSidebar = DashboardResponsive.shouldShowFixedSidebar(width);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 2,
        actions: [
          const DashboardHomeAction(),
          if (!showFixedSidebar && user?.role == UserRole.ormawaAccount)
            IconButton(
              onPressed: () => context.push('/ormawa/members'),
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Anggota Ormawa',
            ),
          if (!showFixedSidebar && user?.role == UserRole.adminFaculty)
            IconButton(
              onPressed: () => context.push('/admin/ormawas'),
              icon: const Icon(Icons.apartment_rounded),
              tooltip: 'Data Ormawa',
            ),
          if (!showFixedSidebar)
            IconButton(
              onPressed: () => context.push('/activities'),
              icon: const Icon(Icons.event_note_outlined),
              tooltip: 'Kegiatan',
            ),
          if (!showFixedSidebar && title != 'Leaderboard')
            IconButton(
              onPressed: () => context.push('/leaderboard'),
              icon: const Icon(Icons.leaderboard_outlined),
              tooltip: 'Leaderboard',
            ),
          if (!showFixedSidebar)
            IconButton(
              onPressed: () => context.push('/voting'),
              icon: const Icon(Icons.how_to_vote_rounded),
              tooltip: 'Voting',
            ),
        ],
      ),
      drawer: showFixedSidebar
          ? null
          : Drawer(
              child: AdminSidebar(
                user: user,
                onLogout: onLogout,
                onEditProfile: () => _showEditProfileDialog(context, ref, user),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: showFixedSidebar
              ? Row(
                  children: [
                    // Fixed Sidebar for Desktop
                    SizedBox(
                      width: DashboardResponsive.sidebarWidth,
                      child: Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: AdminSidebar(
                          user: user,
                          onLogout: onLogout,
                          onEditProfile: () =>
                              _showEditProfileDialog(context, ref, user),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Main Content
                    Expanded(child: body),
                  ],
                )
              : body, // Mobile/Tablet: Just body with drawer
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, User? user) {
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                ref
                    .read(authControllerProvider.notifier)
                    .updateProfile(name: nameController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
