import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/providers/activity_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/presentation/widgets/discussion_section.dart';

class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key});

  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(activityControllerProvider.notifier).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Feed Kegiatan')),
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
    final isEditing = activity != null;
    final titleController = TextEditingController(text: activity?.title);
    final descController = TextEditingController(text: activity?.description);
    final categoryController = TextEditingController(
      text: activity?.category ?? 'Kegiatan',
    );
    final docsController = TextEditingController(text: activity?.documentation);
    DateTime selectedDate = activity?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Kegiatan' : 'Input Kegiatan'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Judul'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      TextFormField(
                        controller: docsController,
                        decoration: const InputDecoration(
                          labelText: 'Dokumentasi URL',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tanggal: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                            ),
                          ),
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2035),
                                      initialDate: selectedDate,
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                        () => selectedDate = picked,
                                      );
                                    }
                                  },
                            child: const Text('Pilih'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
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
                                category: categoryController.text.trim(),
                              );
                            } else {
                              await notifier.create(
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                date: selectedDate,
                                documentation: docsController.text.trim(),
                                category: categoryController.text.trim(),
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
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(e.message)));
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
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
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
                Chip(
                  avatar: const Icon(Icons.star_rate_rounded, size: 18),
                  label: Text('${activity.pointsGenerated} Poin'),
                  backgroundColor: Colors.amber.withValues(alpha: 0.16),
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
                TextButton.icon(
                  onPressed: () {},
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
                          await ref
                              .read(activityControllerProvider.notifier)
                              .verify(
                                activityId: activity.id,
                                status: ActivityStatus.rejected,
                                note: 'Perlu perbaikan data administrasi.',
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
}
