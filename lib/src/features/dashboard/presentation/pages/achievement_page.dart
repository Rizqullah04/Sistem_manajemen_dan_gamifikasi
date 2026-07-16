import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/config/api_config.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final adminBadgesProvider = FutureProvider.autoDispose<List<GamificationBadge>>((
  ref,
) async {
  final response = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>('/badges');
  final responseData = response.data ?? <String, dynamic>{};
  final data = responseData['data'];
  if (data is! List) return const <GamificationBadge>[];

  return data
      .whereType<Map<String, dynamic>>()
      .map(GamificationBadge.fromJson)
      .toList();
});

class AchievementPage extends ConsumerWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Pengaturan Lencana',
      onLogout: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (!context.mounted) return;
        context.go('/login');
      },
      body: const _BadgeSettingsContent(),
    );
  }
}

class _BadgeSettingsContent extends ConsumerStatefulWidget {
  const _BadgeSettingsContent();

  @override
  ConsumerState<_BadgeSettingsContent> createState() =>
      _BadgeSettingsContentState();
}

class _BadgeSettingsContentState extends ConsumerState<_BadgeSettingsContent> {
  String? _busyId;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final badgesAsync = ref.watch(adminBadgesProvider);

    if (user?.role != UserRole.adminFaculty) {
      return const EmptyState(
        title: 'Akses khusus admin',
        subtitle: 'Pengaturan lencana gamifikasi hanya tersedia untuk admin.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Gagal memuat lencana',
        subtitle: _errorMessage(error),
        icon: Icons.error_outline_rounded,
      ),
      data: (badges) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = DashboardResponsive.getContentPadding(width);
            final spacing = DashboardResponsive.getSpacing(width);
            final isWide = width >= DashboardResponsive.desktopMinWidth;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminBadgesProvider);
                await ref.read(adminBadgesProvider.future);
              },
              child: ListView(
                padding: padding,
                children: [
                  _BadgeHeader(
                    totalBadges: badges.length,
                    highestMilestone: badges.isEmpty
                        ? 0
                        : badges
                              .map((badge) => badge.minimumPoints)
                              .reduce((a, b) => a > b ? a : b),
                    isWide: isWide,
                    isCreating: _isCreating,
                    onAdd: _showCreateDialog,
                  ),
                  SizedBox(height: spacing),
                  if (badges.isEmpty)
                    const EmptyState(
                      title: 'Belum ada lencana',
                      subtitle:
                          'Tambahkan lencana pertama untuk menentukan ambang batas poin mahasiswa dan Ormawa.',
                      icon: Icons.military_tech_outlined,
                    )
                  else
                    ...badges.map(
                      (badge) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _BadgeCard(
                          badge: badge,
                          isBusy: _busyId == badge.id,
                          onEdit: () => _showEditDialog(badge),
                          onDelete: () => _confirmDelete(badge),
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
    final result = await showDialog<_BadgeFormResult>(
      context: context,
      builder: (context) => const _BadgeFormDialog(mode: _BadgeFormMode.create),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCreating = true);
    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/badges',
        data: result.toFormData(),
      );
      ref.invalidate(adminBadgesProvider);
      await ref.read(adminBadgesProvider.future);
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

  Future<void> _showEditDialog(GamificationBadge badge) async {
    final result = await showDialog<_BadgeFormResult>(
      context: context,
      builder: (context) =>
          _BadgeFormDialog(mode: _BadgeFormMode.edit, initial: badge),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = badge.id);
    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/badges/${badge.id}',
        data: result.toFormData(methodOverride: 'PATCH'),
      );
      ref.invalidate(adminBadgesProvider);
      await ref.read(adminBadgesProvider.future);
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

  Future<void> _confirmDelete(GamificationBadge badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lencana'),
        content: Text('Hapus lencana ${badge.name}?'),
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
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = badge.id);
    try {
      await ref
          .read(dioProvider)
          .delete<Map<String, dynamic>>('/badges/${badge.id}');
      ref.invalidate(adminBadgesProvider);
      await ref.read(adminBadgesProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${badge.name} berhasil dihapus.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
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

class _BadgeHeader extends StatelessWidget {
  const _BadgeHeader({
    required this.totalBadges,
    required this.highestMilestone,
    required this.isWide,
    required this.isCreating,
    required this.onAdd,
  });

  final int totalBadges;
  final int highestMilestone;
  final bool isWide;
  final bool isCreating;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _SummaryPill(
        label: 'Total Lencana',
        value: '$totalBadges',
        icon: Icons.workspace_premium_outlined,
      ),
      _SummaryPill(
        label: 'Milestone Tertinggi',
        value: '$highestMilestone poin',
        icon: Icons.flag_outlined,
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
              width: isWide ? 560 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Lencana (Badges)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola kategori lencana dan ambang batas poin untuk mahasiswa dan Ormawa secara otomatis.',
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
              label: const Text('Tambah Lencana'),
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

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final GamificationBadge badge;
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
              child: ClipOval(
                child: _BadgeNetworkIcon(
                  imageUrl: badge.iconUrl,
                  size: 40,
                  fallbackColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (badge.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
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
                        icon: Icons.flag_outlined,
                        label: 'Minimal ${badge.minimumPoints} poin',
                      ),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: badge.activityType,
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
                tooltip: 'Aksi Lencana',
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

enum _BadgeFormMode { create, edit }

class _BadgeFormDialog extends StatefulWidget {
  const _BadgeFormDialog({required this.mode, this.initial});

  final _BadgeFormMode mode;
  final GamificationBadge? initial;

  @override
  State<_BadgeFormDialog> createState() => _BadgeFormDialogState();
}

class _BadgeFormDialogState extends State<_BadgeFormDialog> {
  static const _activityTypeOptions = [
    'Poin Kumulatif',
    'Keaktifan Diskusi',
    'Partisipasi Event',
    'Voting Berhasil',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minimumPointsController;
  late String _selectedActivityType;
  _PickedBadgeIcon? _selectedIcon;

  bool get _isCreate => widget.mode == _BadgeFormMode.create;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _minimumPointsController = TextEditingController(
      text: initial?.minimumPoints.toString() ?? '',
    );
    _selectedActivityType = _activityTypeOptions.contains(initial?.activityType)
        ? initial!.activityType
        : _activityTypeOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreate ? 'Tambah Lencana' : 'Edit Lencana'),
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
                  decoration: const InputDecoration(
                    labelText: 'Nama Lencana',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required('Nama lencana wajib diisi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Lencana',
                    hintText:
                        'Contoh: Diberikan kepada mahasiswa yang aktif berkontribusi dalam kegiatan.',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 3,
                  validator: _required('Deskripsi lencana wajib diisi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minimumPointsController,
                  decoration: const InputDecoration(
                    labelText: 'Ambang Batas Poin',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final points = int.tryParse(value ?? '');
                    if (points == null || points < 0) {
                      return 'Minimal poin harus angka 0 atau lebih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedActivityType,
                  items: _activityTypeOptions
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedActivityType = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Kriteria/Kategori Lencana',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kriteria lencana wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FormField<_PickedBadgeIcon>(
                  validator: (_) {
                    if (_isCreate && _selectedIcon == null) {
                      return 'Icon lencana wajib dipilih';
                    }
                    return null;
                  },
                  builder: (field) {
                    final fileName = _selectedIcon?.name;
                    final hasStoredIcon = widget.initial?.iconUrl.isNotEmpty ?? false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickIcon,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(
                            fileName == null && !hasStoredIcon
                                ? 'Pilih Icon PNG'
                                : 'Ganti Icon PNG',
                          ),
                        ),
                        if (fileName != null || hasStoredIcon) ...[
                          const SizedBox(height: 8),
                          Text(
                            fileName ?? 'Icon saat ini sudah tersimpan',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (field.hasError) ...[
                          const SizedBox(height: 6),
                          Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
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

  Future<void> _pickIcon() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();
    final iconBytes = file.bytes;

    if (extension != 'png' ||
        file.size > 2 * 1024 * 1024 ||
        iconBytes == null) {
      _showValidationSnackBar(
        'File wajib berformat .png dan ukuran maksimal 2MB!',
      );
      return;
    }

    final isSquare = await _isSquareImage(iconBytes);
    if (!isSquare) {
      _showValidationSnackBar('Dimensi icon wajib memiliki rasio 1:1!');
      return;
    }

    setState(() {
      _selectedIcon = _PickedBadgeIcon(
        name: file.name,
        bytes: iconBytes,
      );
    });
  }

  Future<bool> _isSquareImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final isSquare = image.width == image.height;
      image.dispose();
      codec.dispose();
      return isSquare;
    } catch (_) {
      return false;
    }
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BadgeFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        activityType: _selectedActivityType,
        minimumPoints: int.parse(_minimumPointsController.text.trim()),
        icon: _selectedIcon,
      ),
    );
  }
}

class _PickedBadgeIcon {
  const _PickedBadgeIcon({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class _BadgeFormResult {
  const _BadgeFormResult({
    required this.name,
    required this.description,
    required this.activityType,
    required this.minimumPoints,
    required this.icon,
  });

  final String name;
  final String description;
  final String activityType;
  final int minimumPoints;
  final _PickedBadgeIcon? icon;

  FormData toFormData({String? methodOverride}) {
    final data = <String, dynamic>{
      'nama_badge': name,
      'deskripsi': description.isEmpty ? '' : description,
      'activity_type': activityType,
      'minimal_poin': minimumPoints,
      if (methodOverride != null) '_method': methodOverride,
    };

    final selectedIcon = icon;
    if (selectedIcon != null) {
      data['icon'] = MultipartFile.fromBytes(
        selectedIcon.bytes,
        filename: selectedIcon.name,
      );
    }

    return FormData.fromMap(data);
  }
}

class GamificationBadge {
  const GamificationBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.activityType,
    required this.minimumPoints,
    required this.icon,
    this.iconUrl = '',
  });

  final String id;
  final String name;
  final String description;
  final String activityType;
  final int minimumPoints;
  final String icon;
  final String iconUrl;

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    final iconPath = json['icon']?.toString() ?? '';
    return GamificationBadge(
      id: json['id']?.toString() ?? '',
      name: json['nama_badge']?.toString() ?? '-',
      description: json['deskripsi']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? 'Poin Kumulatif',
      minimumPoints:
          int.tryParse(json['minimal_poin']?.toString() ?? '0') ?? 0,
      icon: iconPath,
      iconUrl: ApiConfig.publicStorageUrl(
        iconPath.isNotEmpty ? iconPath : json['icon_url']?.toString(),
      ),
    );
  }
}

class _BadgeNetworkIcon extends StatelessWidget {
  const _BadgeNetworkIcon({
    required this.imageUrl,
    required this.size,
    required this.fallbackColor,
  });

  final String imageUrl;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.military_tech_outlined,
      color: fallbackColor,
      size: size * 0.6,
    );
    if (imageUrl.isEmpty) return fallback;

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
