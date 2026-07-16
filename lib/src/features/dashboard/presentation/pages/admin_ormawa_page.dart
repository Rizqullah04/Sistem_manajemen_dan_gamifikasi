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

final adminOrmawasProvider = FutureProvider.autoDispose<List<ManagedOrmawa>>((
  ref,
) async {
  final response = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>('/admin/ormawas');
  final responseData = response.data ?? <String, dynamic>{};
  final data = responseData['data'];
  if (data is! List) return const <ManagedOrmawa>[];

  return data
      .whereType<Map<String, dynamic>>()
      .map(ManagedOrmawa.fromJson)
      .toList();
});

class AdminOrmawaPage extends ConsumerWidget {
  const AdminOrmawaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Data Ormawa',
      onLogout: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (!context.mounted) return;
        context.go('/login');
      },
      body: const _AdminOrmawaContent(),
    );
  }
}

class _AdminOrmawaContent extends ConsumerStatefulWidget {
  const _AdminOrmawaContent();

  @override
  ConsumerState<_AdminOrmawaContent> createState() =>
      _AdminOrmawaContentState();
}

class _AdminOrmawaContentState extends ConsumerState<_AdminOrmawaContent> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _busyId;
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final ormawasAsync = ref.watch(adminOrmawasProvider);

    if (user?.role != UserRole.adminFaculty) {
      return const EmptyState(
        title: 'Akses khusus admin',
        subtitle: 'Halaman pengelolaan Ormawa hanya tersedia untuk admin.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return ormawasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Gagal memuat Ormawa',
        subtitle: _errorMessage(error),
        icon: Icons.error_outline_rounded,
      ),
      data: (ormawas) {
        final keyword = _query.toLowerCase();
        final filtered = ormawas.where((ormawa) {
          return ormawa.name.toLowerCase().contains(keyword) ||
              ormawa.description.toLowerCase().contains(keyword) ||
              ormawa.accountEmail.toLowerCase().contains(keyword);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = DashboardResponsive.getContentPadding(width);
            final spacing = DashboardResponsive.getSpacing(width);
            final isWide = width >= DashboardResponsive.desktopMinWidth;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminOrmawasProvider);
                await ref.read(adminOrmawasProvider.future);
              },
              child: ListView(
                padding: padding,
                children: [
                  _OrmawaHeader(
                    totalOrmawa: ormawas.length,
                    totalAccounts: ormawas
                        .where((item) => item.hasOrmawaAccount)
                        .length,
                    totalMembers: ormawas.fold<int>(
                      0,
                      (total, item) => total + item.memberCount,
                    ),
                    isWide: isWide,
                    isCreating: _isCreating,
                    onAdd: _showCreateDialog,
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, deskripsi, atau email akun Ormawa',
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
                  if (ormawas.isEmpty)
                    const EmptyState(
                      title: 'Belum ada Ormawa',
                      subtitle:
                          'Tambahkan Ormawa baru agar muncul otomatis pada pilihan register akun.',
                      icon: Icons.apartment_rounded,
                    )
                  else if (filtered.isEmpty)
                    const EmptyState(
                      title: 'Ormawa tidak ditemukan',
                      subtitle: 'Coba gunakan kata kunci lain.',
                      icon: Icons.search_off_rounded,
                    )
                  else
                    ...filtered.map(
                      (ormawa) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _OrmawaCard(
                          ormawa: ormawa,
                          isBusy: _busyId == ormawa.id,
                          onEdit: () => _showEditDialog(ormawa),
                          onDelete: () => _confirmDelete(ormawa),
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

  Future<void> _showCreateDialog() async {
    final result = await showDialog<_OrmawaFormResult>(
      context: context,
      builder: (context) =>
          const _OrmawaFormDialog(mode: _OrmawaFormMode.create),
    );
    if (result == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCreating = true);
    try {
      await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/ormawas',
            data: {
              'nama_ormawa': result.name,
              'deskripsi': result.description,
              'account_name': result.accountName,
              'account_email': result.accountEmail,
              'account_password': result.password,
              'account_password_confirmation': result.confirmPassword,
            },
          );
      _refreshDashboardData();
      await ref.read(adminOrmawasProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${result.name} berhasil ditambahkan.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _showEditDialog(ManagedOrmawa ormawa) async {
    final result = await showDialog<_OrmawaFormResult>(
      context: context,
      builder: (context) =>
          _OrmawaFormDialog(mode: _OrmawaFormMode.edit, initial: ormawa),
    );
    if (result == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = ormawa.id);
    try {
      await ref
          .read(dioProvider)
          .patch<Map<String, dynamic>>(
            '/ormawas/${ormawa.id}',
            data: {
              'nama_ormawa': result.name,
              'deskripsi': result.description,
              'account_name': result.accountName,
            },
          );
      _refreshDashboardData();
      await ref.read(adminOrmawasProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${result.name} berhasil diperbarui.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmDelete(ManagedOrmawa ormawa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ormawa'),
        content: Text(
          'Hapus ${ormawa.name}? Pilihan ini juga akan hilang dari register akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = ormawa.id);
    try {
      await ref
          .read(dioProvider)
          .delete<Map<String, dynamic>>('/ormawas/${ormawa.id}');
      _refreshDashboardData();
      await ref.read(adminOrmawasProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${ormawa.name} berhasil dihapus.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _refreshDashboardData() {
    ref.invalidate(adminOrmawasProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(realtimeDashboardSummaryProvider);
    ref.invalidate(ormawaLeaderboardProvider);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;

        final errors = data['data'];
        if (errors is Map<String, dynamic>) {
          final validation = errors['errors'];
          if (validation is Map<String, dynamic> && validation.isNotEmpty) {
            final firstError = validation.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      }
      return 'Tidak dapat terhubung ke API.';
    }

    return error.toString();
  }
}

class _OrmawaHeader extends StatelessWidget {
  const _OrmawaHeader({
    required this.totalOrmawa,
    required this.totalAccounts,
    required this.totalMembers,
    required this.isWide,
    required this.isCreating,
    required this.onAdd,
  });

  final int totalOrmawa;
  final int totalAccounts;
  final int totalMembers;
  final bool isWide;
  final bool isCreating;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _SummaryPill(
        label: 'Total Ormawa',
        value: '$totalOrmawa',
        icon: Icons.apartment_rounded,
      ),
      _SummaryPill(
        label: 'Akun Ormawa',
        value: '$totalAccounts',
        icon: Icons.admin_panel_settings_outlined,
      ),
      _SummaryPill(
        label: 'Anggota Terhubung',
        value: '$totalMembers',
        icon: Icons.groups_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: isWide ? 520 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengelolaan Data Ormawa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tambah, ubah, dan hapus data organisasi yang digunakan pada register akun.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: isCreating ? null : onAdd,
              icon: isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Tambah Ormawa'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: stats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: stat,
                    ),
                  ),
                )
                .toList(),
          )
        else
          Column(
            children: stats
                .map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: stat,
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

class _OrmawaCard extends StatelessWidget {
  const _OrmawaCard({
    required this.ormawa,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedOrmawa ormawa;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                ormawa.initials,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ormawa.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (ormawa.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ormawa.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.stars_outlined,
                        label: '${ormawa.totalPoints} poin',
                      ),
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        label: '${ormawa.memberCount} anggota',
                      ),
                      _InfoChip(
                        icon: ormawa.hasOrmawaAccount
                            ? Icons.verified_user_outlined
                            : Icons.person_off_outlined,
                        label: ormawa.hasOrmawaAccount
                            ? ormawa.accountEmail
                            : 'Akun Ormawa belum ada',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isBusy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Aksi Ormawa',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Hapus'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

enum _OrmawaFormMode { create, edit }

class _OrmawaFormDialog extends StatefulWidget {
  const _OrmawaFormDialog({required this.mode, this.initial});

  final _OrmawaFormMode mode;
  final ManagedOrmawa? initial;

  @override
  State<_OrmawaFormDialog> createState() => _OrmawaFormDialogState();
}

class _OrmawaFormDialogState extends State<_OrmawaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountEmailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  bool get _isCreate => widget.mode == _OrmawaFormMode.create;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _accountNameController = TextEditingController(
      text: initial?.accountName.isNotEmpty == true
          ? initial!.accountName
          : initial?.name ?? '',
    );
    _accountEmailController = TextEditingController(
      text: initial?.accountEmail ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _accountNameController.dispose();
    _accountEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreate ? 'Tambah Ormawa' : 'Edit Ormawa'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Ormawa'),
                  validator: _required('Nama Ormawa wajib diisi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Akun Ormawa',
                  ),
                  validator: _required('Nama akun wajib diisi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountEmailController,
                  enabled: _isCreate,
                  decoration: const InputDecoration(
                    labelText: 'Email Akun Ormawa',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _isCreate ? _validateEmail : null,
                ),
                if (_isCreate) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password Akun Ormawa',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: 'Tampilkan password',
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _hideConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _hideConfirmPassword = !_hideConfirmPassword,
                        ),
                        icon: Icon(
                          _hideConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: 'Tampilkan konfirmasi password',
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Konfirmasi password harus sama';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_isCreate ? Icons.add_rounded : Icons.save_outlined),
          label: Text(_isCreate ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email akun wajib diisi';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)');
    if (!regex.hasMatch(value)) {
      return 'Harus ada huruf besar, kecil, dan angka';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _OrmawaFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        accountName: _accountNameController.text.trim(),
        accountEmail: _accountEmailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }
}

class _OrmawaFormResult {
  const _OrmawaFormResult({
    required this.name,
    required this.description,
    required this.accountName,
    required this.accountEmail,
    required this.password,
    required this.confirmPassword,
  });

  final String name;
  final String description;
  final String accountName;
  final String accountEmail;
  final String password;
  final String confirmPassword;
}

class ManagedOrmawa {
  const ManagedOrmawa({
    required this.id,
    required this.name,
    required this.description,
    required this.totalPoints,
    required this.users,
  });

  final String id;
  final String name;
  final String description;
  final int totalPoints;
  final List<ManagedOrmawaUser> users;

  bool get hasOrmawaAccount => users.any((user) => user.role == 'ormawa');

  String get accountName {
    for (final user in users) {
      if (user.role == 'ormawa') return user.name;
    }
    return '';
  }

  String get accountEmail {
    for (final user in users) {
      if (user.role == 'ormawa') return user.email;
    }
    return '';
  }

  int get memberCount => users.where((user) => user.role == 'anggota').length;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final value = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return value.isEmpty ? 'O' : value;
  }

  factory ManagedOrmawa.fromJson(Map<String, dynamic> json) {
    final usersData = json['users'];
    return ManagedOrmawa(
      id: json['id_ormawa']?.toString() ?? '',
      name: json['nama_ormawa']?.toString() ?? '-',
      description: json['deskripsi']?.toString() ?? '',
      totalPoints: int.tryParse(json['total_poin']?.toString() ?? '0') ?? 0,
      users: usersData is List
          ? usersData
                .whereType<Map<String, dynamic>>()
                .map(ManagedOrmawaUser.fromJson)
                .toList()
          : const <ManagedOrmawaUser>[],
    );
  }
}

class ManagedOrmawaUser {
  const ManagedOrmawaUser({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  factory ManagedOrmawaUser.fromJson(Map<String, dynamic> json) {
    return ManagedOrmawaUser(
      name: json['nama']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      role: json['role']?.toString() ?? '-',
    );
  }
}
