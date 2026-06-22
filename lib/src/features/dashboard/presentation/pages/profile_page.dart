import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/ormawa_members_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>('/logout');
      ref.read(dioProvider).options.headers.remove('Authorization');
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    } on DioException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Logout gagal. Periksa koneksi API.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final membersAsync = user?.role == UserRole.ormawaAccount
        ? ref.watch(ormawaMembersProvider)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: const [DashboardHomeAction()],
      ),
      body: user == null
          ? const Center(
              child: Text('Tidak ada data profil. Silakan login kembali.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final contentWidth = isWide ? 920.0 : double.infinity;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileHero(user: user),
                            const SizedBox(height: 16),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _AccountInfoCard(user: user)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ProfileSummaryCard(
                                      user: user,
                                      membersAsync: membersAsync,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _AccountInfoCard(user: user),
                              const SizedBox(height: 16),
                              _ProfileSummaryCard(
                                user: user,
                                membersAsync: membersAsync,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _QuickActionsCard(
                              user: user,
                              onLogout: () => _logout(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _initials(user.name);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primary,
              child: Text(
                initials,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                        label: Text(_roleLabel(user.role)),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (user.role == UserRole.ormawaAccount)
                        const Chip(
                          avatar: Icon(Icons.apartment_rounded, size: 16),
                          label: Text('Akun Organisasi'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
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

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              icon: Icons.manage_accounts_outlined,
              title: 'Informasi Akun',
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Nama', value: user.name),
            _InfoRow(label: 'Email', value: user.studentStaffId),
            _InfoRow(label: 'Peran', value: _roleLabel(user.role)),
            if (user.ormawaId != null && user.ormawaId!.isNotEmpty)
              _InfoRow(label: 'ID Ormawa', value: user.ormawaId!),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.user,
    required this.membersAsync,
  });

  final User user;
  final AsyncValue<List<OrmawaMember>>? membersAsync;

  @override
  Widget build(BuildContext context) {
    final memberCount = membersAsync?.maybeWhen(
      data: (members) => members.length.toString(),
      loading: () => '...',
      orElse: () => '-',
    );

    final items = [
      _MetricData(
        label: 'Poin',
        value: '${user.points}',
        icon: Icons.stars_outlined,
      ),
      _MetricData(
        label: 'Level',
        value: '${user.level}',
        icon: Icons.trending_up_rounded,
      ),
      if (user.role == UserRole.ormawaAccount)
        _MetricData(
          label: 'Anggota',
          value: memberCount ?? '-',
          icon: Icons.groups_outlined,
        ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              icon: Icons.insights_outlined,
              title: user.role == UserRole.ormawaAccount
                  ? 'Ringkasan Ormawa'
                  : 'Ringkasan Profil',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map((item) => _MetricTile(data: item))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.user,
    required this.onLogout,
  });

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (user.role == UserRole.ormawaAccount)
              FilledButton.icon(
                onPressed: () => context.push('/ormawa/members'),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Lihat Anggota'),
              ),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Pengaturan'),
            ),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(data.label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  if (parts.isEmpty) return 'U';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _roleLabel(UserRole role) {
  switch (role) {
    case UserRole.adminFaculty:
      return 'Admin';
    case UserRole.ormawaAccount:
      return 'Ormawa';
    case UserRole.memberAccount:
      return 'Anggota';
  }
}
