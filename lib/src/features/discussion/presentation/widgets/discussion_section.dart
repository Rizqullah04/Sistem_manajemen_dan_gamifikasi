import 'dart:async';

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
  const DiscussionSection({
    required this.activityId,
    this.canComment = true,
    super.key,
  });

  final String activityId;
  final bool canComment;

  @override
  ConsumerState<DiscussionSection> createState() => _DiscussionSectionState();
}

class _DiscussionSectionState extends ConsumerState<DiscussionSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  Timer? _guardTimer;

  @override
  void initState() {
    super.initState();
    _guardTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _guardTimer?.cancel();
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
            if (widget.canComment &&
                currentUser != null &&
                currentUser.role != UserRole.adminFaculty)
              _buildSpamGuardNotice(comments, currentUser.id),
            if (widget.canComment)
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
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Mode baca: komentar hanya dapat dikirim mahasiswa aktif pada kegiatan yang telah disetujui.',
                ),
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

    final comments = ref
            .read(commentsStreamProvider(widget.activityId))
            .valueOrNull ??
        const <CommentItem>[];
    final guardMessage = _commentGuardMessage(
      comments: comments,
      userId: user.id,
      content: content,
      isAdmin: user.role == UserRole.adminFaculty,
    );
    if (guardMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(guardMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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

  Widget _buildSpamGuardNotice(List<CommentItem> comments, String userId) {
    final now = DateTime.now();
    final ownComments = comments
        .where((item) => item.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentCount = ownComments
        .where((item) => now.difference(item.createdAt).inMinutes < 10)
        .length;
    final rewardedLimitReached = ownComments.length >= 3;
    final remainingSeconds = ownComments.isEmpty
        ? 0
        : 30 - now.difference(ownComments.first.createdAt).inSeconds;

    final String message;
    final IconData icon;
    final Color color;
    if (remainingSeconds > 0) {
      message =
          'Tunggu $remainingSeconds detik sebelum mengirim komentar berikutnya.';
      icon = Icons.timer_outlined;
      color = Colors.orange;
    } else if (recentCount >= 5) {
      message =
          'Batas 5 komentar dalam 10 menit tercapai. Coba lagi beberapa menit lagi.';
      icon = Icons.block_outlined;
      color = Theme.of(context).colorScheme.error;
    } else if (recentCount >= 4) {
      message =
          'Peringatan anti-spam: Anda sudah mengirim $recentCount dari maksimal 5 komentar dalam 10 menit.';
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    } else {
      message = rewardedLimitReached
          ? 'Batas 3 komentar berpoin pada kegiatan ini sudah tercapai. Anda tetap dapat berdiskusi tanpa memperoleh poin tambahan.'
          : 'Anti-spam: jeda 30 detik, maksimal 5 komentar per 10 menit. Hanya 3 komentar pertama per kegiatan yang memperoleh poin.';
      icon = Icons.shield_outlined;
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String? _commentGuardMessage({
    required List<CommentItem> comments,
    required String userId,
    required String content,
    required bool isAdmin,
  }) {
    if (isAdmin) return null;
    final now = DateTime.now();
    final ownComments = comments
        .where((item) => item.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (ownComments.isNotEmpty) {
      final remaining = 30 - now.difference(ownComments.first.createdAt).inSeconds;
      if (remaining > 0) {
        return 'Tunggu $remaining detik sebelum mengirim komentar lagi.';
      }
    }

    final recentCount = ownComments
        .where((item) => now.difference(item.createdAt).inMinutes < 10)
        .length;
    if (recentCount >= 5) {
      return 'Batas 5 komentar dalam 10 menit sudah tercapai.';
    }

    final normalized = _normalizeComment(content);
    final exactDuplicate = ownComments.any(
      (item) => _normalizeComment(item.content) == normalized,
    );
    if (exactDuplicate) {
      return 'Komentar yang sama sudah pernah Anda kirim pada kegiatan ini.';
    }

    final nearDuplicate = ownComments.any((item) {
      final age = now.difference(item.createdAt);
      if (age > const Duration(days: 7)) return false;
      return _commentSimilarity(normalized, _normalizeComment(item.content)) >=
          0.85;
    });
    if (nearDuplicate) {
      return 'Komentar terlalu mirip dengan komentar Anda dalam 7 hari terakhir.';
    }

    return null;
  }

  String _normalizeComment(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _commentSimilarity(String first, String second) {
    if (first.isEmpty || second.isEmpty) return 0;
    final longest = first.length > second.length ? first.length : second.length;
    return 1 - (_levenshteinDistance(first, second) / longest);
  }

  int _levenshteinDistance(String first, String second) {
    var previous = List<int>.generate(second.length + 1, (index) => index);
    for (var firstIndex = 1; firstIndex <= first.length; firstIndex++) {
      final current = List<int>.filled(second.length + 1, 0);
      current[0] = firstIndex;
      for (var secondIndex = 1;
          secondIndex <= second.length;
          secondIndex++) {
        final cost = first[firstIndex - 1] == second[secondIndex - 1] ? 0 : 1;
        final deletion = previous[secondIndex] + 1;
        final insertion = current[secondIndex - 1] + 1;
        final substitution = previous[secondIndex - 1] + cost;
        current[secondIndex] = [deletion, insertion, substitution]
            .reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }
    return previous.last;
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
