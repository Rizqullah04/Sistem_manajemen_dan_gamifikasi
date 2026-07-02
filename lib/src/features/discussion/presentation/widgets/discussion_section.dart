import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/entities/comment.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/presentation/providers/comment_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/presentation/providers/point_sync_provider.dart';

class DiscussionSection extends ConsumerStatefulWidget {
  const DiscussionSection({required this.activityId, super.key});

  final String activityId;

  @override
  ConsumerState<DiscussionSection> createState() => _DiscussionSectionState();
}

class _DiscussionSectionState extends ConsumerState<DiscussionSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(widget.activityId));
    final currentUser = ref.watch(authControllerProvider).user;
    return commentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Diskusi tidak tersedia',
        subtitle: error.toString(),
      ),
      data: (comments) {
        final badge = comments.length >= 5 ? 'Diskusi Aktif' : 'Diskusi Baru';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Komentar (${comments.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Chip(label: Text(badge)),
              ],
            ),
            if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: Icons.forum_rounded,
                  title: 'Belum ada komentar',
                  subtitle: 'Mulai diskusi untuk menambah poin partisipasi.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = comments[index];
                  final canDelete =
                      currentUser != null &&
                      (currentUser.id == item.userId ||
                          currentUser.role == UserRole.adminFaculty);
                  final trimmedName = item.userName?.trim();
                  final authorName =
                      trimmedName != null && trimmedName.isNotEmpty
                      ? trimmedName
                      : 'User ${item.userId}';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: Text(
                        authorName.isNotEmpty
                            ? authorName[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                    title: Text(authorName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(item.content)],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(item.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (canDelete) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Hapus komentar',
                            onPressed: _isSubmitting
                                ? null
                                : () => _confirmDeleteComment(item),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Tulis komentar...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitComment() async {
    final user = ref.read(authControllerProvider).user;
    final content = _controller.text.trim();
    if (user == null || content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(commentRepositoryProvider)
          .addComment(
            activityId: widget.activityId,
            userId: user.id,
            content: content,
          );
      _controller.clear();
      ref.invalidate(commentsStreamProvider(widget.activityId));
      await refreshPointDependentWidgetState(ref);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Komentar gagal dikirim: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmDeleteComment(CommentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text(
          'Komentar akan dihapus dan poin terkait akan disesuaikan.',
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

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(commentRepositoryProvider).deleteComment(item.id);
      ref.invalidate(commentsStreamProvider(widget.activityId));
      await refreshPointDependentWidgetState(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar berhasil dihapus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Komentar gagal dihapus: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
