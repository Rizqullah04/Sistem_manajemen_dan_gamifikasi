import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

enum RankMovement { up, down, stable }

class LeaderboardTabView extends StatelessWidget {
  const LeaderboardTabView({super.key, 
    required this.entriesAsync,
    required this.currentUserId,
    required this.isOrmawaTab,
  });

  final AsyncValue<List<LeaderboardEntry>> entriesAsync;
  final String currentUserId;
  final bool isOrmawaTab;

  @override
  Widget build(BuildContext context) {
    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (entries) {
        final currentUser = entries.firstWhere(
          (entry) => entry.id == currentUserId,
          orElse: () => LeaderboardEntry(id: currentUserId, name: 'You', points: 0, ranking: 0, level: 0),
        );
        final top3 = entries.take(3).toList();
        final remaining = entries.skip(3).toList();

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PodiumWidget(entries: top3),
                      const SizedBox(height: 18),
                      ...remaining.asMap().entries.map((entryPair) {
                        final index = entryPair.key;
                        final entry = entryPair.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RankItemCard(
                            entry: entry,
                            isCurrent: entry.id == currentUserId,
                            subtitle: isOrmawaTab ? 'Ormawa' : 'Level ${entry.level}',
                            movement: _rankMovement(entry, index + 3),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: UserHighlightCard(entry: currentUser),
              ),
            ],
          ),
        );
      },
    );
  }

  RankMovement _rankMovement(LeaderboardEntry entry, int index) {
    if (entry.ranking < index + 1) {
      return RankMovement.up;
    }
    if (entry.ranking > index + 1) {
      return RankMovement.down;
    }
    return RankMovement.stable;
  }
}

class PodiumWidget extends StatelessWidget {
  const PodiumWidget({super.key, required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null)
          Expanded(
            child: _PodiumPosition(
              entry: second,
              rank: 2,
              color: const Color(0xFFC0C0C0),
              height: 150,
            ),
          ),
        if (first != null)
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: _PodiumPosition(
                entry: first,
                rank: 1,
                color: const Color(0xFFF7A400),
                height: 190,
                isMain: true,
              ),
            ),
          ),
        if (third != null)
          Expanded(
            child: _PodiumPosition(
              entry: third,
              rank: 3,
              color: const Color(0xFFCD7F32),
              height: 140,
            ),
          ),
      ],
    );
  }
}

class _PodiumPosition extends StatelessWidget {
  const _PodiumPosition({
    required this.entry,
    required this.rank,
    required this.color,
    required this.height,
    this.isMain = false,
  });

  final LeaderboardEntry entry;
  final int rank;
  final Color color;
  final double height;
  final bool isMain;

  String get rankLabel {
    if (rank == 1) return '1ST';
    if (rank == 2) return '2ND';
    return '3RD';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1733),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 38, bottom: 16, left: 12, right: 12),
                child: Column(
                  children: [
                    Text(entry.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${entry.points} PTS', style: TextStyle(color: rank == 1 ? const Color(0xFFF7A400) : Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                radius: isMain ? 34 : 26,
                backgroundColor: color.withOpacity(0.2),
                child: CircleAvatar(
                  radius: isMain ? 28 : 20,
                  backgroundColor: const Color(0xFF0D0B1F),
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.white, fontSize: isMain ? 24 : 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(rankLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: isMain ? 12 : 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          width: isMain ? 92 : 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class RankItemCard extends StatelessWidget {
  const RankItemCard({super.key, 
    required this.entry,
    required this.isCurrent,
    required this.subtitle,
    required this.movement,
  });

  final LeaderboardEntry entry;
  final bool isCurrent;
  final String subtitle;
  final RankMovement movement;

  @override
  Widget build(BuildContext context) {
    final accentColor = isCurrent ? const Color(0xFF8B64FF) : const Color(0xFF6C4AB6);
    final backgroundColor = isCurrent ? const Color(0xFF261A45) : const Color(0xFF1A1733);

    return TweenAnimationBuilder<Offset>(
      duration: const Duration(milliseconds: 420),
      tween: Tween(begin: const Offset(0, 0.08), end: Offset.zero),
      builder: (context, offset, child) {
        return Transform.translate(offset: offset * 20, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isCurrent ? accentColor.withOpacity(0.35) : Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withOpacity(0.18),
              child: Text('${entry.ranking}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white12,
              child: Text(entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.points} PTS', style: const TextStyle(color: Color(0xFFF7A400), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (movement != RankMovement.stable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: movement == RankMovement.up ? Colors.green.withOpacity(0.18) : Colors.red.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          movement == RankMovement.up ? Icons.arrow_upward : Icons.arrow_downward,
                          color: movement == RankMovement.up ? Colors.greenAccent : Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movement == RankMovement.up ? 'Up' : 'Down',
                          style: TextStyle(
                            color: movement == RankMovement.up ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserHighlightCard extends StatelessWidget {
  const UserHighlightCard({super.key, required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C4AB6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4AB6).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0B1F),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.ranking}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'You - ${entry.points} PTS',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Text('Current', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
