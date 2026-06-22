import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/leaderboard_constants.dart';

/// Unified Leaderboard Page yang dapat digunakan oleh semua role
/// 
/// Parameters:
/// - [title]: Judul halaman (default: 'LEADERBOARD')
/// - [tabWidget]: Widget untuk tab switch
/// - [podiumWidget]: Widget untuk menampilkan top 3
/// - [listItemBuilder]: Builder untuk list item
/// - [userHighlightCard]: Widget untuk highlight user saat ini
/// - [totalItems]: Total items untuk shimmer loading
/// - [isLoading]: State loading
abstract class BaseLeaderboardPage extends ConsumerWidget {
  const BaseLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LeaderboardColors.backgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildTabSwitch(ref),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: buildIsLoading(ref)
                  ? _buildShimmerContent()
                  : buildLeaderboardContent(context, ref),
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

  /// Override methods
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: LeaderboardColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'LEADERBOARD',
        style: LeaderboardTypography.headerMedium,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () => _showInfoDialog(context),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LeaderboardColors.surfaceColor,
        title: const Text(
          'Leaderboard Info',
          style: TextStyle(
            color: LeaderboardColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Switch between Individu and Ormawa leaderboard to compare points and ranking.',
          style: TextStyle(color: LeaderboardColors.textWhite70),
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
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
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
                  _buildShimmerBox(80, 150),
                  const SizedBox(width: LeaderboardDimensions.spacingL),
                  _buildShimmerBox(90, 190),
                  const SizedBox(width: LeaderboardDimensions.spacingL),
                  _buildShimmerBox(80, 130),
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

  Widget _buildShimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusM),
      ),
    );
  }

  /// Abstract methods that must be implemented by subclasses
  Widget buildTabSwitch(WidgetRef ref);
  bool buildIsLoading(WidgetRef ref);
  Widget buildLeaderboardContent(BuildContext context, WidgetRef ref);
}
