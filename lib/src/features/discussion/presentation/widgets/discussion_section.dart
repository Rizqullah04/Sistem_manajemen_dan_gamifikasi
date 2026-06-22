import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/presentation/providers/comment_providers.dart';

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
                      children: [
                        Text(item.content),
                      ],
                    ),
                    trailing: Text(
                      DateFormat('HH:mm').format(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
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
      await ref.read(commentRepositoryProvider).addComment(
            activityId: widget.activityId,
            userId: user.id,
            content: content,
          );
      _controller.clear();
      ref.invalidate(commentsStreamProvider(widget.activityId));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komentar gagal dikirim: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
