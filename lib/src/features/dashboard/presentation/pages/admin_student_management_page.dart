import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final adminStudentsProvider =
    FutureProvider.autoDispose<List<ManagedStudent>>((ref) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>(
        '/users',
        queryParameters: {'role': 'anggota'},
      );

  final responseData = response.data ?? <String, dynamic>{};
  final data = responseData['data'];
  if (data is! List) return const <ManagedStudent>[];

  return data
      .whereType<Map<String, dynamic>>()
      .map(ManagedStudent.fromJson)
      .toList();
});

class AdminStudentManagementPage extends ConsumerWidget {
  const AdminStudentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Manajemen Mahasiswa',
      onLogout: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (!context.mounted) return;
        context.go('/login');
      },
      body: const _AdminStudentManagementContent(),
    );
  }
}

class _AdminStudentManagementContent extends ConsumerStatefulWidget {
  const _AdminStudentManagementContent();

  @override
  ConsumerState<_AdminStudentManagementContent> createState() =>
      _AdminStudentManagementContentState();
}

class _AdminStudentManagementContentState
    extends ConsumerState<_AdminStudentManagementContent> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _updatingBemMemberId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final studentsAsync = ref.watch(adminStudentsProvider);

    if (user?.role != UserRole.adminFaculty) {
      return const EmptyState(
        title: 'Akses khusus admin',
        subtitle:
            'Manajemen mahasiswa lintas Ormawa hanya tersedia untuk admin.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Gagal memuat mahasiswa',
        subtitle: _errorMessage(error),
        icon: Icons.error_outline_rounded,
      ),
      data: (students) {
        final keyword = _query.toLowerCase();
        final filtered = students.where((student) {
          return student.name.toLowerCase().contains(keyword) ||
              student.nim.toLowerCase().contains(keyword) ||
              student.email.toLowerCase().contains(keyword) ||
              student.ormawaName.toLowerCase().contains(keyword);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = DashboardResponsive.getContentPadding(width);
            final spacing = DashboardResponsive.getSpacing(width);
            final isWide = width >= DashboardResponsive.tabletMinWidth;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminStudentsProvider);
                await ref.read(adminStudentsProvider.future);
              },
              child: ListView(
                padding: padding,
                children: [
                  _StudentsHeader(
                    totalStudents: students.length,
                    activeStudents:
                        students.where((student) => student.isActive).length,
                    pendingStudents:
                        students.where((student) => student.isPending).length,
                    representedOrmawaCount: students
                        .map((student) => student.ormawaName)
                        .where((name) => name != '-')
                        .toSet()
                        .length,
                    isWide: isWide,
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIM, email, atau asal Ormawa',
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
                  if (students.isEmpty)
                    const EmptyState(
                      title: 'Belum ada mahasiswa',
                      subtitle:
                          'Mahasiswa dari seluruh Ormawa akan tampil di sini setelah terdaftar.',
                      icon: Icons.school_outlined,
                    )
                  else if (filtered.isEmpty)
                    const EmptyState(
                      title: 'Mahasiswa tidak ditemukan',
                      subtitle: 'Coba gunakan kata kunci lain.',
                      icon: Icons.search_off_rounded,
                    )
                  else if (isWide)
                    _StudentDataTable(
                      students: filtered,
                      updatingBemMemberId: _updatingBemMemberId,
                      onBemMembershipChanged: _updateBemMembership,
                    )
                  else
                    ...filtered.map(
                      (student) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _StudentCard(
                          student: student,
                          isUpdatingBem: _updatingBemMemberId == student.id,
                          onBemMembershipChanged: _updateBemMembership,
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

  Future<void> _updateBemMembership(
    ManagedStudent student,
    bool shouldBeMember,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _updatingBemMemberId = student.id);
    try {
      final dio = ref.read(dioProvider);
      if (shouldBeMember) {
        await dio.post<Map<String, dynamic>>(
          '/bem/members',
          data: {'id_user': student.id},
        );
      } else {
        await dio.delete<Map<String, dynamic>>('/bem/members/${student.id}');
      }

      ref.invalidate(adminStudentsProvider);
      await ref.read(adminStudentsProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            shouldBeMember
                ? '${student.name} ditambahkan ke BEM.'
                : '${student.name} dikeluarkan dari BEM.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _updatingBemMemberId = null);
    }
  }
}

class _StudentsHeader extends StatelessWidget {
  const _StudentsHeader({
    required this.totalStudents,
    required this.activeStudents,
    required this.pendingStudents,
    required this.representedOrmawaCount,
    required this.isWide,
  });

  final int totalStudents;
  final int activeStudents;
  final int pendingStudents;
  final int representedOrmawaCount;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryPill(
        label: 'Total Mahasiswa',
        value: '$totalStudents',
        icon: Icons.school_outlined,
      ),
      _SummaryPill(
        label: 'Aktif',
        value: '$activeStudents',
        icon: Icons.verified_user_outlined,
      ),
      _SummaryPill(
        label: 'Menunggu',
        value: '$pendingStudents',
        icon: Icons.hourglass_top_rounded,
      ),
      _SummaryPill(
        label: 'Asal Ormawa',
        value: '$representedOrmawaCount',
        icon: Icons.apartment_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitoring Mahasiswa',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau seluruh akun mahasiswa dari semua Ormawa yang terdaftar.',
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

class _StudentDataTable extends StatelessWidget {
  const _StudentDataTable({
    required this.students,
    required this.updatingBemMemberId,
    required this.onBemMembershipChanged,
  });

  final List<ManagedStudent> students;
  final String? updatingBemMemberId;
  final void Function(ManagedStudent student, bool shouldBeMember)
  onBemMembershipChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nama Mahasiswa')),
            DataColumn(label: Text('NIM')),
            DataColumn(label: Text('Asal Ormawa')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('BEM')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Poin'), numeric: true),
          ],
          rows: students
              .map(
                (student) => DataRow(
                  cells: [
                    DataCell(Text(student.name)),
                    DataCell(Text(student.nim)),
                    DataCell(Text(student.ormawaName)),
                    DataCell(Text(student.email)),
                    DataCell(
                      _BemMembershipButton(
                        student: student,
                        isUpdating: updatingBemMemberId == student.id,
                        onChanged: onBemMembershipChanged,
                      ),
                    ),
                    DataCell(_StatusChip(student: student)),
                    DataCell(Text('${student.points}')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.isUpdatingBem,
    required this.onBemMembershipChanged,
  });

  final ManagedStudent student;
  final bool isUpdatingBem;
  final void Function(ManagedStudent student, bool shouldBeMember)
  onBemMembershipChanged;

  @override
  Widget build(BuildContext context) {
    final initials = student.initials;

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
          student.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StudentMeta(
                icon: Icons.apartment_rounded,
                label: student.ormawaName,
              ),
              const SizedBox(height: 4),
              _StudentMeta(
                icon: Icons.badge_outlined,
                label: student.nim,
              ),
              const SizedBox(height: 4),
              _StudentMeta(
                icon: Icons.mail_outline_rounded,
                label: student.email,
              ),
              const SizedBox(height: 4),
              _StudentMeta(
                icon: Icons.account_balance_outlined,
                label: student.isBemMember ? 'Anggota BEM' : 'Belum masuk BEM',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _BemMembershipButton(
                  student: student,
                  isUpdating: isUpdatingBem,
                  onChanged: onBemMembershipChanged,
                ),
              ),
              const SizedBox(height: 4),
              _StudentMeta(
                icon: Icons.stars_outlined,
                label: '${student.points} poin',
              ),
            ],
          ),
        ),
        trailing: _StatusChip(student: student),
      ),
    );
  }
}

class _StudentMeta extends StatelessWidget {
  const _StudentMeta({required this.icon, required this.label});

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

class _BemMembershipButton extends StatelessWidget {
  const _BemMembershipButton({
    required this.student,
    required this.isUpdating,
    required this.onChanged,
  });

  final ManagedStudent student;
  final bool isUpdating;
  final void Function(ManagedStudent student, bool shouldBeMember) onChanged;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => onChanged(student, !student.isBemMember),
      icon: Icon(
        student.isBemMember
            ? Icons.person_remove_alt_1_outlined
            : Icons.person_add_alt_1_rounded,
        size: 18,
      ),
      label: Text(student.isBemMember ? 'Keluarkan' : 'Tambah BEM'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.student});

  final ManagedStudent student;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(student.statusLabel),
      visualDensity: VisualDensity.compact,
      backgroundColor: student.statusColor(context),
      side: BorderSide.none,
    );
  }
}

class ManagedStudent {
  const ManagedStudent({
    required this.id,
    required this.name,
    required this.nim,
    required this.email,
    required this.ormawaName,
    required this.isBemMember,
    required this.points,
    required this.status,
  });

  final String id;
  final String name;
  final String nim;
  final String email;
  final String ormawaName;
  final bool isBemMember;
  final int points;
  final String status;

  bool get isActive => status == 'aktif';
  bool get isPending => status == 'pending';

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '-') return 'M';

    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

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
        return status.isEmpty ? '-' : status;
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

  factory ManagedStudent.fromJson(Map<String, dynamic> json) {
    final ormawa = json['ormawa'];

    return ManagedStudent(
      id: json['id_user']?.toString() ?? '',
      name: json['nama']?.toString() ?? '-',
      nim:
          json['nim']?.toString() ??
          json['student_staff_id']?.toString() ??
          json['nomor_induk']?.toString() ??
          '-',
      email: json['email']?.toString() ?? '-',
      ormawaName: ormawa is Map<String, dynamic>
          ? ormawa['nama_ormawa']?.toString() ?? '-'
          : '-',
      isBemMember:
          json['bem_membership'] is Map<String, dynamic> &&
          (json['bem_membership'] as Map<String, dynamic>)['status']
                  ?.toString() ==
              'aktif',
      points: int.tryParse(json['poin']?.toString() ?? '0') ?? 0,
      status: json['status_akun']?.toString() ?? '-',
    );
  }
}
