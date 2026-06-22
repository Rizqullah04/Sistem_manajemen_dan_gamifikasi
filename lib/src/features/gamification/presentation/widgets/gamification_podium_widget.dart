import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../logic/gamification_provider.dart';
import '../../../leaderboard/presentation/constants/leaderboard_constants.dart';

class GamificationPodiumWidget extends ConsumerWidget {
  const GamificationPodiumWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3 = ref.watch(gamificationTop3Provider);
    final selectedType = ref.watch(leaderboardTypeProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: LeaderboardDimensions.spacingL, vertical: LeaderboardDimensions.spacingM),
        padding: const EdgeInsets.symmetric(vertical: LeaderboardDimensions.spacingL),
        decoration: BoxDecoration(
          color: LeaderboardColors.surfaceColor,
          borderRadius: BorderRadius.circular(LeaderboardDimensions.radiusXXL),
          boxShadow: LeaderboardShadows.elevatedShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: LeaderboardColors.rankGold, size: 18),
                const SizedBox(width: LeaderboardDimensions.spacingM),
                Text(
                  selectedType == LeaderboardType.individu ? 'Podium Individu' : 'Podium Ormawa',
                  style: LeaderboardTypography.headerSmall,
                ),
              ],
            ),
            const SizedBox(height: LeaderboardDimensions.spacingL),
            SizedBox(
              height: 240,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (top3.length > 1) _GamificationPodiumItem(entry: top3[1], rank: 2, height: 150),
                  if (top3.isNotEmpty) _GamificationPodiumItem(entry: top3[0], rank: 1, height: 210, isCenter: true),
                  if (top3.length > 2) _GamificationPodiumItem(entry: top3[2], rank: 3, height: 130),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationPodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final bool isCenter;

  const _GamificationPodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRankColor(rank);
    final avatarSize = isCenter ? 50.0 : 34.0;
    final spacing = isCenter ? 16.0 : 12.0;

    return Expanded(
      flex: isCenter ? 12 : 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Top spacing untuk rank 2 & 3
          if (!isCenter) SizedBox(height: 24 + (10 - rank % 10) * 2),
          
          // Avatar dengan glow untuk rank 1
          Transform.translate(
            offset: Offset(0, isCenter ? -20 : 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect hanya untuk rank 1
                if (isCenter)
                  Container(
                    width: avatarSize + 30,
                    height: avatarSize + 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF7A400).withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 12,
                        ),
                        BoxShadow(
                          color: const Color(0xFF6C4AB6).withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                // Gradient ring untuk rank 1
                if (isCenter)
                  Container(
                    width: avatarSize + 16,
                    height: avatarSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C4AB6), Color(0xFFF7A400)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                // Avatar placeholder dengan initial
                CircleAvatar(
                  radius: avatarSize,
                  backgroundColor: _getAvatarBgColor(rank),
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCenter ? 24 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rank == 1 ? '1ST' : rank == 2 ? '2ND' : '3RD',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: isCenter ? 14 : 12,
              ),
            ),
          ),
          SizedBox(height: spacing),
          
          // Name
          Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isCenter ? FontWeight.w800 : FontWeight.w700,
              fontSize: isCenter ? 15 : 13,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          
          // Points
          Text(
            '${_formatPoints(entry.points)} PTS',
            style: TextStyle(
              color: rank == 1 ? const Color(0xFFF7A400) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: isCenter ? 14 : 12,
            ),
          ),
          SizedBox(height: spacing),
          
          // Podium bar
          Container(
            height: height,
            width: isCenter ? 96 : 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF7A400);
      case 2:
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Color _getAvatarBgColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFF6C4AB6);
      case 2:
        return const Color(0xFF6C4AB6).withValues(alpha: 0.8);
      default:
        return const Color(0xFF6C4AB6).withValues(alpha: 0.6);
    }
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
