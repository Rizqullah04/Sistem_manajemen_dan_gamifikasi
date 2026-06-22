import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final ormawaMembersProvider = FutureProvider<List<OrmawaMember>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user?.role != UserRole.ormawaAccount || user?.ormawaId == null) {
    return const <OrmawaMember>[];
  }

  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>(
        '/ormawa/members',
      );

  final responseData = response.data ?? <String, dynamic>{};
  final data = responseData['data'];
  if (data is! List) return const <OrmawaMember>[];

  return data
      .whereType<Map<String, dynamic>>()
      .map(OrmawaMember.fromJson)
      .toList();
});

class OrmawaMembersPage extends ConsumerWidget {
  const OrmawaMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Anggota Ormawa',
      onLogout: () {
        ref.read(authControllerProvider.notifier).logout();
        context.go('/login');
      },
      body: const _OrmawaMembersContent(),
    );
  }
}

class _OrmawaMembersContent extends ConsumerStatefulWidget {
  const _OrmawaMembersContent();

  @override
  ConsumerState<_OrmawaMembersContent> createState() =>
      _OrmawaMembersContentState();
}

class _OrmawaMembersContentState extends ConsumerState<_OrmawaMembersContent> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _updatingMemberId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final membersAsync = ref.watch(ormawaMembersProvider);

    if (user?.role != UserRole.ormawaAccount) {
      return const EmptyState(
        title: 'Akses khusus Ormawa',
        subtitle: 'Halaman ini hanya tersedia untuk akun Ormawa.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Gagal memuat anggota',
        subtitle: _errorMessage(error),
        icon: Icons.error_outline_rounded,
      ),
      data: (members) {
        final filteredMembers = members.where((member) {
          final keyword = _query.toLowerCase();
          return member.name.toLowerCase().contains(keyword) ||
              member.email.toLowerCase().contains(keyword);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = DashboardResponsive.getContentPadding(width);
            final spacing = DashboardResponsive.getSpacing(width);
            final isWide = width >= DashboardResponsive.desktopMinWidth;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ormawaMembersProvider);
                await ref.read(ormawaMembersProvider.future);
              },
              child: ListView(
                padding: padding,
                children: [
                  _MembersHeader(
                    totalMembers: members.length,
                    activeMembers:
                        members.where((member) => member.isActive).length,
                    inactiveMembers:
                        members.where((member) => member.isInactive).length,
                    pendingMembers:
                        members.where((member) => member.isPending).length,
                    rejectedMembers:
                        members.where((member) => member.isRejected).length,
                    isWide: isWide,
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email anggota',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Bersihkan pencarian',
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: spacing),
                  if (members.isEmpty)
                    const EmptyState(
                      title: 'Belum ada anggota',
                      subtitle:
                          'Anggota yang mendaftar dan memilih Ormawa ini akan muncul otomatis di sini.',
                      icon: Icons.groups_outlined,
                    )
                  else if (filteredMembers.isEmpty)
                    const EmptyState(
                      title: 'Anggota tidak ditemukan',
                      subtitle: 'Coba gunakan kata kunci lain.',
                      icon: Icons.search_off_rounded,
                    )
                  else
                    ...filteredMembers.map(
                      (member) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _MemberCard(
                          member: member,
                          isUpdating: _updatingMemberId == member.id,
                          onStatusChanged: (status) => _updateMemberStatus(
                            member,
                            status,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      return 'Tidak dapat terhubung ke API.';
    }

    return error.toString();
  }

  Future<void> _updateMemberStatus(
    OrmawaMember member,
    String status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _updatingMemberId = member.id);
    try {
      await ref.read(dioProvider).patch<Map<String, dynamic>>(
        '/ormawa/members/${member.id}',
        data: {'status_akun': status},
      );
      ref.invalidate(ormawaMembersProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(realtimeDashboardSummaryProvider);
      await ref.read(ormawaMembersProvider.future);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Status ${member.name} diperbarui.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _updatingMemberId = null);
    }
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.pendingMembers,
    required this.rejectedMembers,
    required this.isWide,
  });

  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final int pendingMembers;
  final int rejectedMembers;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryPill(
        label: 'Total Anggota',
        value: '$totalMembers',
        icon: Icons.groups_outlined,
      ),
      _SummaryPill(
        label: 'Aktif',
        value: '$activeMembers',
        icon: Icons.verified_user_outlined,
      ),
      _SummaryPill(
        label: 'Menunggu',
        value: '$pendingMembers',
        icon: Icons.hourglass_top_rounded,
      ),
      _SummaryPill(
        label: 'Nonaktif',
        value: '$inactiveMembers',
        icon: Icons.person_off_outlined,
      ),
      _SummaryPill(
        label: 'Bukan Anggota',
        value: '$rejectedMembers',
        icon: Icons.block_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitoring Anggota',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau akun anggota yang memilih Ormawa Anda saat registrasi.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          )
        else
          Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isUpdating,
    required this.onStatusChanged,
  });

  final OrmawaMember member;
  final bool isUpdating;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final initials = member.name.trim().isEmpty
        ? 'A'
        : member.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          member.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemberMeta(icon: Icons.mail_outline_rounded, label: member.email),
              const SizedBox(height: 4),
              _MemberMeta(
                icon: Icons.stars_outlined,
                label: '${member.points} poin',
              ),
            ],
          ),
        ),
        trailing: isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                tooltip: 'Ubah status anggota',
                onSelected: onStatusChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'aktif',
                    child: Text('Aktifkan anggota'),
                  ),
                  PopupMenuItem(
                    value: 'nonaktif',
                    child: Text('Nonaktifkan anggota'),
                  ),
                  PopupMenuItem(
                    value: 'ditolak',
                    child: Text('Tandai bukan anggota'),
                  ),
                ],
                child: Chip(
                  label: Text(member.statusLabel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: member.statusColor(context),
                  side: BorderSide.none,
                ),
              ),
        ),
    );
  }
}

class _MemberMeta extends StatelessWidget {
  const _MemberMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class OrmawaMember {
  const OrmawaMember({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final int points;
  final String status;

  bool get isActive => status == 'aktif';
  bool get isInactive => status == 'nonaktif';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'ditolak';

  String get statusLabel {
    switch (status) {
      case 'aktif':
        return 'Aktif';
      case 'nonaktif':
        return 'Nonaktif';
      case 'pending':
        return 'Menunggu';
      case 'ditolak':
        return 'Bukan Anggota';
      default:
        return status;
    }
  }

  Color statusColor(BuildContext context) {
    switch (status) {
      case 'aktif':
        return const Color(0xFFE5F7EC);
      case 'pending':
        return const Color(0xFFFFF5D6);
      case 'ditolak':
        return const Color(0xFFFFE2E2);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  factory OrmawaMember.fromJson(Map<String, dynamic> json) {
    return OrmawaMember(
      id: json['id_user']?.toString() ?? '',
      name: json['nama']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      points: int.tryParse(json['poin']?.toString() ?? '0') ?? 0,
      status: json['status_akun']?.toString() ?? '-',
    );
  }
}
