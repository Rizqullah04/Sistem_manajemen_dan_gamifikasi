import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../logic/leaderboard_provider.dart';
import '../constants/leaderboard_constants.dart';

class PodiumWidget extends ConsumerWidget {
  const PodiumWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3 = ref.watch(top3Provider);
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
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (top3.length > 1) _PodiumItem(entry: top3[1], rank: 2, height: 54),
                  if (top3.isNotEmpty) _PodiumItem(entry: top3[0], rank: 1, height: 82, isCenter: true),
                  if (top3.length > 2) _PodiumItem(entry: top3[2], rank: 3, height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final UserModel entry;
  final int rank;
  final double height;
  final bool isCenter;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRankColor(rank);
    final avatarSize = isCenter ? 42.0 : 30.0;
    final spacing = isCenter ? 10.0 : 8.0;

    return Expanded(
      flex: isCenter ? 12 : 10,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: isCenter ? 120 : 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCenter) SizedBox(height: rank == 2 ? 18 : 10),
                Transform.translate(
                  offset: Offset(0, isCenter ? -12 : 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isCenter)
                        Container(
                          width: avatarSize + 22,
                          height: avatarSize + 22,
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
                      if (isCenter)
                        Container(
                          width: avatarSize + 12,
                          height: avatarSize + 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C4AB6), Color(0xFFF7A400)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      CircleAvatar(
                        radius: avatarSize,
                        backgroundColor: Colors.grey[900],
                        child: Text(
                          _initials(entry.name),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isCenter ? 16 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
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
                Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isCenter ? FontWeight.w800 : FontWeight.w700,
                    fontSize: isCenter ? 14 : 12,
                  ),
                ),
                if (entry.ormawa.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.ormawa,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                  ),
                ],
                SizedBox(height: spacing * 0.5),
                Text(
                  '${_formatPoints(entry.points)} PTS',
                  style: TextStyle(
                    color: rank == 1 ? const Color(0xFFF7A400) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: isCenter ? 12 : 11,
                  ),
                ),
                SizedBox(height: spacing),
                Container(
                  height: height,
                  width: isCenter ? 78 : 60,
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
          ),
        ),
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

  String _initials(String name) {
    if (name.isEmpty) {
      return '?';
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
