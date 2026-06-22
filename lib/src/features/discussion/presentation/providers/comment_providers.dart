import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/entities/comment.dart';

final commentsStreamProvider =
    StreamProvider.family<List<CommentItem>, String>((ref, activityId) {
  return ref.watch(commentRepositoryProvider).watchByActivity(activityId);
});
