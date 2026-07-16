import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../logic/gamification_provider.dart';
import '../widgets/gamification_podium_widget.dart';
import '../widgets/gamification_tab_switch.dart';
import '../widgets/gamification_rank_list_item.dart';
import '../widgets/gamification_user_highlight_card.dart';
import '../../../leaderboard/presentation/constants/leaderboard_constants.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(gamificationLeaderboardProvider);
    final isLoading = ref.watch(gamificationIsLoadingProvider);
    final selectedType = ref.watch(leaderboardTypeProvider);
    final remaining = ref.watch(gamificationRemainingProvider);

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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: LeaderboardColors.surfaceColor,
                  title: const Text(
                    'Leaderboard Info',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Switch between Individu and Ormawa leaderboard to compare points and ranking.',
                    style: TextStyle(color: Colors.white70),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GamificationTabSwitch(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: isLoading
                  ? _buildShimmerContent()
                  : _buildLeaderboardContent(context, entries, remaining, selectedType),
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
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(
    BuildContext context,
    List entries,
    List remaining,
    LeaderboardType selectedType,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LeaderboardDimensions.spacingM),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LeaderboardDimensions.spacingL),
            child: Row(
              children: [
                Text(
                  selectedType == LeaderboardType.individu ? 'Top Individu' : 'Top Ormawa',
                  style: LeaderboardTypography.headerSmall,
                ),
                const SizedBox(width: LeaderboardDimensions.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LeaderboardDimensions.spacingM,
                    vertical: LeaderboardDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: LeaderboardColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusM),
                  ),
                  child: Text(
                    selectedType == LeaderboardType.individu ? 'Personal Ranking' : 'Organisasi Ranking',
                    style: LeaderboardTypography.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LeaderboardDimensions.spacingM),
          const GamificationPodiumWidget(),
          const SizedBox(height: LeaderboardDimensions.spacingM),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: LeaderboardDimensions.spacingM),
              itemCount: remaining.length,
              itemBuilder: (context, index) {
                final entry = remaining[index];
                return GamificationRankListItem(entry: entry);
              },
            ),
          ),
          const GamificationUserHighlightCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: LeaderboardDimensions.spacingM),
      child: Column(
        children: [
          Container(
            height: 230,
            margin: const EdgeInsets.symmetric(
              horizontal: LeaderboardDimensions.spacingL,
              vertical: LeaderboardDimensions.spacingL,
            ),
            child: Shimmer.fromColors(
              baseColor: LeaderboardColors.surfaceColor,
              highlightColor: LeaderboardColors.primary.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 80,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusM),
                    ),
                  ),
                  const SizedBox(width: LeaderboardDimensions.spacingL),
                  Container(
                    width: 90,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusM),
                    ),
                  ),
                  const SizedBox(width: LeaderboardDimensions.spacingL),
                  Container(
                    width: 80,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusM),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(
            6,
            (index) => Container(
              margin: const EdgeInsets.symmetric(
                horizontal: LeaderboardDimensions.spacingL,
                vertical: LeaderboardDimensions.spacingM,
              ),
              height: 72,
              decoration: BoxDecoration(
                color: LeaderboardColors.surfaceColor,
                borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusXL),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
