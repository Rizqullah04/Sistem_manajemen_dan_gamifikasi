import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';
import '../data/models/user_model.dart';

enum LeaderboardFilter { monthly, semester, allTime }

enum LeaderboardType { individu, ormawa }

final leaderboardFilterProvider = StateProvider<LeaderboardFilter>(
  (ref) => LeaderboardFilter.monthly,
);
final leaderboardTypeProvider = StateProvider<LeaderboardType>(
  (ref) => LeaderboardType.individu,
);

final _leaderboardEntriesProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) {
  final type = ref.watch(leaderboardTypeProvider);
  ref.watch(leaderboardFilterProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return type == LeaderboardType.ormawa
      ? repository.getOrmawaLeaderboard()
      : repository.getMemberLeaderboard();
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(_leaderboardEntriesProvider).isLoading;
});

final usersProvider = Provider<List<UserModel>>((ref) {
  final entries =
      ref.watch(_leaderboardEntriesProvider).valueOrNull ??
      const <LeaderboardEntry>[];
  return entries.map(_toUserModel).toList()
    ..sort((a, b) => a.rank.compareTo(b.rank));
});

final top3Provider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(usersProvider);
  return users.take(3).toList();
});

final remainingUsersProvider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(usersProvider);
  return users.skip(3).toList();
});

final currentUserProvider = Provider<UserModel>((ref) {
  final authUser = ref.watch(authControllerProvider).user;
  return UserModel(
    id: authUser?.id ?? 'current',
    name: authUser?.name ?? 'User',
    avatar: '',
    points: authUser?.effectivePoints ?? 0,
    rank: 0,
    ormawa: authUser?.ormawaId ?? '',
  );
});

final currentLeaderboardEntryProvider = Provider<UserModel>((ref) {
  final type = ref.watch(leaderboardTypeProvider);
  final users = ref.watch(usersProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (users.isEmpty) return currentUser;

  if (type == LeaderboardType.ormawa) {
    return users.firstWhere(
      (entry) => entry.id == currentUser.ormawa,
      orElse: () => users.first,
    );
  }

  return users.firstWhere(
    (entry) => entry.id == currentUser.id,
    orElse: () => users.first,
  );
});

UserModel _toUserModel(LeaderboardEntry entry) {
  return UserModel(
    id: entry.id,
    name: entry.name,
    avatar: '',
    points: entry.points,
    rank: entry.ranking,
    ormawa: '',
    isVerified: true,
    isActive: true,
    isTopContributor: entry.ranking == 1,
  );
}
