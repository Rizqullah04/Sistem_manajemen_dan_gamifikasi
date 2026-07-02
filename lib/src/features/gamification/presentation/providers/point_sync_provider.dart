import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/logic/gamification_provider.dart'
    as gamification;
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/presentation/providers/student_gamification_controller.dart';

Future<void> refreshPointDependentState(Ref ref) async {
  await _refresh(ref);
}

Future<void> refreshPointDependentWidgetState(WidgetRef ref) async {
  await _refresh(ref);
}

Future<void> _refresh(dynamic ref) async {
  await ref.read(authControllerProvider.notifier).refreshProfile();
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(realtimeDashboardSummaryProvider);
  ref.invalidate(memberLeaderboardProvider);
  ref.invalidate(ormawaLeaderboardProvider);
  ref.invalidate(studentGamificationControllerProvider);
  ref.invalidate(gamification.gamificationEntriesProvider);
}
