import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';

import '../../logic/leaderboard_provider.dart';
import '../../data/models/user_model.dart';
import '../widgets/tab_filter_widget.dart';
import '../widgets/podium_widget.dart';
import '../widgets/rank_list_item.dart';
import '../widgets/user_highlight_card.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../constants/leaderboard_constants.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({
    super.key,
    this.showAppBar = true,
    this.showBottomNavigation = true,
  });

  final bool showAppBar;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingUsers = ref.watch(remainingUsersProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final selectedType = ref.watch(leaderboardTypeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final content = ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LeaderboardTabSwitch(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: isLoading
                  ? _buildShimmerContent()
                  : _buildLeaderboardContent(context, remainingUsers, selectedType, currentUser),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
            ),
          ),
          if (showBottomNavigation) const BottomNavigationWidget(),
        ],
      ),
    );

    if (!showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'LEADERBOARD',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: true,
        actions: [
          const DashboardHomeAction(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Leaderboard Info',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  content: Text(
                    'Switch between Individu and Ormawa leaderboard to compare points and ranking.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'OK',
                        style: TextStyle(color: LeaderboardColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildLeaderboardContent(BuildContext context, List users, LeaderboardType selectedType, UserModel currentUser) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  selectedType == LeaderboardType.individu ? 'Top Individu' : 'Top Ormawa',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C4AB6).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedType == LeaderboardType.individu ? 'Personal Ranking' : 'Ormawa Ranking',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        const SliverToBoxAdapter(child: PodiumWidget()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return RankListItem(
                user: user,
                isCurrent: selectedType == LeaderboardType.individu
                    ? user.id == currentUser.id
                    : user.name == currentUser.ormawa,
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: UserHighlightCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            height: 230,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A1733),
              highlightColor: const Color(0xFF2A2743),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 80, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 16),
                  Container(width: 90, height: 190, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 16),
                  Container(width: 80, height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ),
          ...List.generate(
            6,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1733),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
