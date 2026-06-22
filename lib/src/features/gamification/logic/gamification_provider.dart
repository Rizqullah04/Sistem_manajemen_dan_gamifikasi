import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import '../domain/entities/leaderboard_entry.dart';

enum LeaderboardType { individu, ormawa }

final leaderboardTypeProvider = StateProvider<LeaderboardType>((ref) => LeaderboardType.ormawa);

final _gamificationEntriesProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final type = ref.watch(leaderboardTypeProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return type == LeaderboardType.ormawa
      ? repository.getOrmawaLeaderboard()
      : repository.getMemberLeaderboard();
});

final gamificationIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(_gamificationEntriesProvider).isLoading;
});

final gamificationLeaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  return ref.watch(_gamificationEntriesProvider).valueOrNull ?? const <LeaderboardEntry>[];
});

final gamificationTop3Provider = Provider<List<LeaderboardEntry>>((ref) {
  final entries = ref.watch(gamificationLeaderboardProvider);
  return entries.take(3).toList();
});

final gamificationRemainingProvider = Provider<List<LeaderboardEntry>>((ref) {
  final entries = ref.watch(gamificationLeaderboardProvider);
  return entries.skip(3).toList();
});

final gamificationCurrentEntryProvider = Provider<LeaderboardEntry>((ref) {
  final type = ref.watch(leaderboardTypeProvider);
  final entries = ref.watch(gamificationLeaderboardProvider);
  final user = ref.watch(authControllerProvider).user;

  if (entries.isEmpty) {
    return LeaderboardEntry(
      id: user?.id ?? 'current',
      name: user?.name ?? 'You',
      points: user?.points ?? 0,
      ranking: 0,
      level: user?.level ?? 1,
    );
  }

  if (type == LeaderboardType.ormawa && user?.ormawaId != null) {
    return entries.firstWhere(
      (entry) => entry.id == user!.ormawaId,
      orElse: () => entries.first,
    );
  }

  return entries.firstWhere(
    (entry) => entry.id == user?.id,
    orElse: () => entries.first,
  );
});
