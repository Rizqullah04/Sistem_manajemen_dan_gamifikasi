import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/period_status.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) {
    throw Exception('User belum login');
  }
  return ref.watch(dashboardRepositoryProvider).getSummary(user);
});

final realtimeDashboardSummaryProvider =
    StreamProvider.autoDispose<DashboardSummary>((ref) async* {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) {
    throw Exception('User belum login');
  }

  final repository = ref.watch(dashboardRepositoryProvider);
  while (true) {
    yield await repository.getSummary(user);
    await Future<void>.delayed(const Duration(seconds: 8));
  }
});

final ormawaLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getOrmawaLeaderboard();
});

final memberLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getMemberLeaderboard();
});

final periodStatusProvider = FutureProvider<PeriodStatus>((ref) {
  return ref.watch(dashboardRepositoryProvider).getPeriodStatus();
});

final periodResetControllerProvider =
    AsyncNotifierProvider<PeriodResetController, PeriodResetResult?>(
  PeriodResetController.new,
);

class PeriodResetController extends AsyncNotifier<PeriodResetResult?> {
  @override
  Future<PeriodResetResult?> build() async => null;

  Future<void> endCurrentPeriod() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(dashboardRepositoryProvider).endCurrentPeriod();
      ref.invalidate(periodStatusProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(realtimeDashboardSummaryProvider);
      ref.invalidate(ormawaLeaderboardProvider);
      ref.invalidate(memberLeaderboardProvider);
      return result;
    });
  }
}
