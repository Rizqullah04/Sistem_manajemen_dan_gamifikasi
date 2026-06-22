import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/period_status.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary(User user);
  Future<List<LeaderboardEntry>> getOrmawaLeaderboard();
  Future<List<LeaderboardEntry>> getMemberLeaderboard();
  Future<PeriodStatus> getPeriodStatus();
  Future<PeriodResetResult> endCurrentPeriod();
}
