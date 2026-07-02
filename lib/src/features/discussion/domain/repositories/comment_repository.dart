import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/entities/comment.dart';

abstract class CommentRepository {
  Stream<List<CommentItem>> watchByActivity(String activityId);
  Future<void> addComment({
    required String activityId,
    required String userId,
    required String content,
  });
  Future<void> deleteComment(String commentId);
}
