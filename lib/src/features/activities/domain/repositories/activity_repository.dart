import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';

abstract class ActivityRepository {
  Future<ActivityPage> fetchActivities({
    required int page,
    required int pageSize,
    required User user,
  });

  Future<Activity> createActivity(Activity activity);
  Future<Activity> updateActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<Activity> verifyActivity({
    required String activityId,
    required ActivityStatus status,
    required String note,
  });
}
