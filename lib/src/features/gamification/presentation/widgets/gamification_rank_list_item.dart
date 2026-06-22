import 'package:flutter/material.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../../leaderboard/presentation/constants/leaderboard_constants.dart';

class GamificationRankListItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrent;

  const GamificationRankListItem({
    super.key,
    required this.entry,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -20, end: 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: LeaderboardDimensions.spacingL,
          vertical: LeaderboardDimensions.spacingM,
        ),
        padding: const EdgeInsets.all(LeaderboardDimensions.spacingM),
        decoration: BoxDecoration(
          color: isCurrent ? LeaderboardColors.primary.withValues(alpha: 0.18) : LeaderboardColors.surfaceColor,
          borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusL),
          border: isCurrent ? Border.all(color: LeaderboardColors.primary, width: 1.2) : null,
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: LeaderboardColors.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              alignment: Alignment.center,
              child: Text(
                '#${entry.ranking}',
                style: TextStyle(
                  color: isCurrent ? LeaderboardColors.textWhite : LeaderboardColors.textWhite70,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: LeaderboardDimensions.spacingM),
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(entry.ranking),
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: LeaderboardDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: LeaderboardColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: LeaderboardDimensions.spacingXS),
                  Row(
                    children: [
                      const Icon(
                        Icons.layers,
                        color: LeaderboardColors.textWhite70,
                        size: 12,
                      ),
                      const SizedBox(width: LeaderboardDimensions.spacingXS),
                      Text(
                        'Level ${entry.level}',
                        style: const TextStyle(
                          color: LeaderboardColors.textWhite70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${_formatPoints(entry.points)} PTS',
              style: const TextStyle(
                color: LeaderboardColors.rankGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int ranking) {
    switch (ranking) {
      case 1:
        return LeaderboardColors.rankGold;
      case 2:
        return LeaderboardColors.rankSilver;
      case 3:
        return LeaderboardColors.rankBronze;
      default:
        return LeaderboardColors.primary;
    }
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
