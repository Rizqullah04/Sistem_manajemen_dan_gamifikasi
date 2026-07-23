import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/providers/activity_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/widgets/activity_dislike_feedback_dialog.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/presentation/widgets/discussion_section.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/pages/manage_category_page.dart';

class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key});

  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  final List<String> listKategori = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await Future.wait([
          ref.read(activityControllerProvider.notifier).loadInitial(),
          _loadCategories(),
        ]);
      },
    );
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/kategori-kegiatans');
      final data = response.data?['data'];
      if (!mounted || data is! List) return;
      setState(() {
        listKategori
          ..clear()
          ..addAll(
            data
                .whereType<Map<String, dynamic>>()
                .map((item) => item['nama_kategori']?.toString() ?? '')
                .where((name) => name.isNotEmpty),
          );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori kegiatan gagal dimuat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    final canManageCategories = user?.role == UserRole.adminFaculty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Kegiatan'),
        actions: [
          if (canManageCategories)
            IconButton(
              tooltip: 'Kelola kategori',
              onPressed: _openManageCategoryPage,
              icon: const Icon(Icons.category_outlined),
            ),
        ],
      ),
      floatingActionButton: user?.role == UserRole.ormawaAccount
          ? FloatingActionButton.extended(
              onPressed: () => _showActivityFormDialog(context),
              label: const Text('Input Kegiatan'),
              icon: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(activityControllerProvider.notifier).loadInitial(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 100 &&
                state.hasMore &&
                !state.isLoadingMore) {
              ref.read(activityControllerProvider.notifier).loadMore();
            }
            return false;
          },
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.items.isEmpty
              ? const EmptyState(
                  title: 'Belum ada kegiatan',
                  subtitle: 'Tambahkan kegiatan pertama Anda.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount:
                      1 + state.items.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ActivityFeedHeader(userName: user?.name);
                    }
                    if (index > state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final activity = state.items[index - 1];
                    return _ActivityCard(
                      activity: activity,
                      userRole: user?.role,
                      onEdit: () =>
                          _showActivityFormDialog(context, activity: activity),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showActivityFormDialog(
    BuildContext context, {
    Activity? activity,
  }) async {
    final user = ref.read(authControllerProvider).user;
    final isEditing = activity != null;
    final titleController = TextEditingController(text: activity?.title);
    final descController = TextEditingController(text: activity?.description);
    final availableCategories = listKategori.isEmpty
        ? const <String>['Tanpa Kategori']
        : List<String>.from(listKategori);
    var selectedCategory = availableCategories.contains(activity?.category)
        ? activity!.category
        : availableCategories.first;
    final docsController = TextEditingController(text: activity?.documentation);
    DateTime selectedDate = activity?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasDocumentation = docsController.text.trim().isNotEmpty;

            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Kegiatan' : 'Input Kegiatan',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul',
                          prefixIcon: Icon(Icons.event_note_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: availableCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                              if (value == null) return;
                              setDialogState(() => selectedCategory = value);
                            },
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      if (listKategori.isEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?.role == UserRole.adminFaculty
                                    ? 'Belum ada kategori. Buat kategori master untuk kebutuhan audit.'
                                    : 'Belum ada kategori master. Hubungi admin DPM; kegiatan tetap dapat disimpan sebagai Tanpa Kategori.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (user?.role == UserRole.adminFaculty)
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        _openManageCategoryPage();
                                      },
                                child: const Text('Buat Kategori'),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: docsController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Dokumentasi URL',
                          helperText: hasDocumentation
                              ? 'Dokumentasi berhasil ditautkan'
                              : 'Tempel URL atau lampirkan file dokumentasi',
                          helperStyle: TextStyle(
                            color: hasDocumentation
                                ? Colors.greenAccent
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            hasDocumentation
                                ? Icons.check_circle_rounded
                                : Icons.link_rounded,
                            color: hasDocumentation ? Colors.greenAccent : null,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Lampirkan dokumentasi',
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    docsController.text =
                                        'galeri/dokumentasi_kegiatan.pdf';
                                    setDialogState(() {});
                                  },
                            icon: const Icon(Icons.attach_file),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _DatePickerCard(
                        selectedDate: selectedDate,
                        isDisabled: isSubmitting,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                            initialDate: selectedDate,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSubmitting = true);
                            try {
                              final notifier = ref.read(
                                activityControllerProvider.notifier,
                              );
                              if (isEditing) {
                                await notifier.update(
                                  activity: activity,
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  date: selectedDate,
                                  documentation: docsController.text.trim(),
                                  category: selectedCategory,
                                );
                              } else {
                                await notifier.create(
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  date: selectedDate,
                                  documentation: docsController.text.trim(),
                                  category: selectedCategory,
                                );
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Kegiatan berhasil diperbarui.'
                                        : 'Kegiatan berhasil diajukan dan menunggu verifikasi.',
                                  ),
                                ),
                              );
                            } on AppException catch (e) {
                              if (!context.mounted) return;
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kegiatan gagal disimpan.'),
                                ),
                              );
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Simpan'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openManageCategoryPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageCategoryPage(
          initialCategories: listKategori,
          dio: ref.read(dioProvider),
          onCategoriesChanged: (categories) {
            setState(() {
              listKategori
                ..clear()
                ..addAll(categories);
            });
          },
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({
    required this.selectedDate,
    required this.isDisabled,
    required this.onTap,
  });

  final DateTime selectedDate;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Kegiatan',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityFeedHeader extends StatelessWidget {
  const _ActivityFeedHeader({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo${userName != null ? ', $userName' : ''}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Temukan kegiatan baru, lihat update ormawa, dan mulai diskusi seperti feed sosial media.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Trending')),
                Chip(label: Text('Terbaru')),
                Chip(label: Text('Seminar')),
                Chip(label: Text('Pelatihan')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.activity,
    required this.userRole,
    required this.onEdit,
  });

  final Activity activity;
  final UserRole? userRole;
  final VoidCallback onEdit;

  Color _statusColor(ActivityStatus status, BuildContext context) {
    switch (status) {
      case ActivityStatus.approved:
        return Colors.green.withValues(alpha: 0.16);
      case ActivityStatus.pending:
        return Colors.orange.withValues(alpha: 0.16);
      case ActivityStatus.rejected:
        return Colors.red.withValues(alpha: 0.16);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(activity.status.label),
                  backgroundColor: _statusColor(activity.status, context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(activity.category),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                ),
                Chip(
                  label: Text(DateFormat('dd MMM yyyy').format(activity.date)),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.12),
                ),
              ],
            ),
            if (activity.verificationNote != null) ...[
              const SizedBox(height: 12),
              Text(
                'Catatan Verifikasi: ${activity.verificationNote!}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(activityControllerProvider.notifier)
                      .toggleLike(activity),
                  icon: Icon(activity.isLiked ? Icons.favorite : Icons.favorite_border),
                  label: Text('${activity.likeCount} Suka'),
                ),
                if (userRole == UserRole.memberAccount)
                  OutlinedButton.icon(
                    onPressed: () => _toggleDislike(context, ref),
                    icon: Icon(
                      activity.isDisliked
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_outlined,
                    ),
                    label: Text('${activity.dislikeCount} Masukan'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _showFeedback(context, ref),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text('Lihat ${activity.dislikeCount} Masukan'),
                  ),
                TextButton.icon(
                  onPressed: activity.documentation.trim().isEmpty
                      ? null
                      : () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Dokumentasi Kegiatan'),
                              content: SelectableText(activity.documentation),
                              actions: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: activity.documentation),
                                    );
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Tautan dokumentasi disalin.'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy_outlined),
                                  label: const Text('Salin Tautan'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          ),
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Lihat Dokumentasi'),
                ),
                if (userRole == UserRole.ormawaAccount) ...[
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ],
              ],
            ),
            ExpansionTile(
              title: const Text('Lihat Diskusi'),
              childrenPadding: const EdgeInsets.only(top: 8),
              children: [
                DiscussionSection(activityId: activity.id),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (userRole == UserRole.adminFaculty) ...[
                      FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(activityControllerProvider.notifier)
                              .verify(
                                activityId: activity.id,
                                status: ActivityStatus.approved,
                                note: 'Kegiatan diverifikasi dan disetujui.',
                              );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final note = await _showVerificationNoteDialog(
                            context,
                            title: 'Tolak Kegiatan',
                            initialNote: 'Perlu perbaikan data administrasi.',
                          );
                          if (note == null) return;
                          await ref
                              .read(activityControllerProvider.notifier)
                              .verify(
                                activityId: activity.id,
                                status: ActivityStatus.rejected,
                                note: note,
                              );
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDislike(BuildContext context, WidgetRef ref) async {
    String? reason;
    String? solution;
    if (!activity.isDisliked) {
      final result = await showActivityDislikeFeedbackDialog(
        context,
        title: 'Masukan Perbaikan',
      );
      if (result == null) return;
      if (!context.mounted) return;
      reason = result.reason;
      solution = result.solution;
    }

    await ref.read(activityRepositoryProvider).setActivityDisliked(
          activityId: activity.id,
          disliked: !activity.isDisliked,
          reason: reason,
          solution: solution,
        );
    if (!context.mounted) return;
    await ref.read(activityControllerProvider.notifier).loadInitial();
  }

  Future<void> _showFeedback(BuildContext context, WidgetRef ref) async {
    try {
      final feedback = await ref
          .read(activityRepositoryProvider)
          .fetchActivityFeedback(activity.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Masukan Perbaikan'),
          content: SizedBox(
            width: 520,
            child: feedback.isEmpty
                ? const Text('Belum ada masukan untuk kegiatan ini.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: feedback.length,
                    separatorBuilder: (_, __) => const Divider(height: 28),
                    itemBuilder: (context, index) {
                      final item = feedback[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.userName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text('Alasan: ${item.reason}'),
                          const SizedBox(height: 6),
                          Text('Saran solusi: ${item.solution}'),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kegiatan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kegiatan "${activity.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    try {
      await ref.read(activityControllerProvider.notifier).delete(activity.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil dihapus.')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kegiatan gagal dihapus.')));
    }
  }

  Future<String?> _showVerificationNoteDialog(
    BuildContext context, {
    required String title,
    required String initialNote,
  }) async {
    final controller = TextEditingController(text: initialNote);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Catatan untuk Ormawa',
              hintText:
                  'Tuliskan alasan penolakan atau revisi yang diperlukan.',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Catatan penolakan wajib diisi.';
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
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Kirim Catatan'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }
}
