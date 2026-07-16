import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/settings_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(dashboardSettingsProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: const [DashboardHomeAction()],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (settings) {
          final controller = ref.read(dashboardSettingsProvider.notifier);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsHeader(userName: user?.name ?? 'Pengguna'),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Notifikasi',
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: controller.setNotificationsEnabled,
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Notifikasi aktif'),
                    subtitle: const Text(
                      'Tampilkan pemberitahuan kegiatan, anggota, dan voting.',
                    ),
                  ),
                  SwitchListTile(
                    value: settings.discussionNotificationsEnabled,
                    onChanged: settings.notificationsEnabled
                        ? controller.setDiscussionNotificationsEnabled
                        : null,
                    secondary: const Icon(Icons.forum_outlined),
                    title: const Text('Notifikasi diskusi'),
                    subtitle: const Text(
                      'Ikuti komentar baru pada diskusi kegiatan.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Tampilan',
                children: [
                  SwitchListTile(
                    value: !settings.darkModeEnabled,
                    onChanged: (lightMode) =>
                        controller.setDarkModeEnabled(!lightMode),
                    secondary: Icon(
                      settings.darkModeEnabled
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Mode terang'),
                    subtitle: const Text(
                      'Gunakan tampilan terang yang nyaman di ruangan bercahaya.',
                    ),
                  ),
                  SwitchListTile(
                    value: settings.compactDashboardEnabled,
                    onChanged: controller.setCompactDashboardEnabled,
                    secondary: const Icon(Icons.view_agenda_outlined),
                    title: const Text('Dashboard ringkas'),
                    subtitle: const Text(
                      'Simpan preferensi tampilan untuk sesi dashboard.',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Bahasa'),
                    subtitle: Text(settings.language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguagePicker(
                      context,
                      controller,
                      settings.language,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Akun',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profil'),
                    subtitle: Text(_profileSubtitle(user?.role)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Ubah kata sandi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPasswordDialog(context),
                  ),
                  if (user?.role == UserRole.ormawaAccount)
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: const Text('Kelola anggota ormawa'),
                      subtitle: const Text('Review dan verifikasi pendaftar.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/ormawa/members'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Sesi',
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Keluar'),
                    subtitle: const Text('Akhiri sesi akun saat ini.'),
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _profileSubtitle(UserRole? role) {
    switch (role) {
      case UserRole.ormawaAccount:
        return 'Atur identitas akun ormawa.';
      case UserRole.memberAccount:
        return 'Atur identitas anggota.';
      case UserRole.adminFaculty:
        return 'Atur identitas admin fakultas.';
      case null:
        return 'Data profil akun.';
    }
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    DashboardSettingsController controller,
    String selectedLanguage,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Pilih Bahasa'),
                subtitle: Text('Preferensi ini disimpan untuk akun di perangkat ini.'),
              ),
              for (final language in const ['Indonesia', 'English'])
                RadioListTile<String>(
                  value: language,
                  groupValue: selectedLanguage,
                  onChanged: (value) => Navigator.pop(context, value),
                  title: Text(language),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    await controller.setLanguage(selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bahasa diubah ke $selected.')),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Kata Sandi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi lama',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi baru',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Wajib diisi';
                      if (value.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi kata sandi',
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Konfirmasi tidak sama';
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Form kata sandi valid. Endpoint API belum tersedia.',
                    ),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (!context.mounted) return;
      context.go('/login');
    } on DioException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout gagal. Periksa koneksi API.')),
      );
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(userName.isEmpty ? 'U' : userName[0].toUpperCase()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola preferensi dashboard dan akun.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
