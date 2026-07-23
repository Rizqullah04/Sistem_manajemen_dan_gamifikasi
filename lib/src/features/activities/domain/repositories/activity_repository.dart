import 'dart:typed_data';

import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';

abstract class ActivityRepository {
  Future<ActivityPage> fetchActivities({
    required int page,
    required int pageSize,
    required User user,
  });

  Future<Activity> createActivity(
    Activity activity, {
    List<ActivityPhotoUpload> photos = const [],
  });
  Future<Activity> updateActivity(
    Activity activity, {
    List<ActivityPhotoUpload> photos = const [],
  });
  Future<void> deleteActivity(String activityId);
  Future<void> setActivityLiked(String activityId, bool liked);
  Future<void> setActivityDisliked({
    required String activityId,
    required bool disliked,
    String? reason,
    String? solution,
  });
  Future<List<ActivityFeedback>> fetchActivityFeedback(String activityId);
  Future<Activity> verifyActivity({
    required String activityId,
    required ActivityStatus status,
    required String note,
  });
}

class ActivityPhotoUpload {
  const ActivityPhotoUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class ActivityFeedback {
  const ActivityFeedback({
    required this.userName,
    required this.reason,
    required this.solution,
    this.createdAt,
  });

  final String userName;
  final String reason;
  final String solution;
  final DateTime? createdAt;
}
