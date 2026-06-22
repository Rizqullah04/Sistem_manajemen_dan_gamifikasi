import 'package:flutter/material.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

class LeaderboardPreview extends StatelessWidget {
  const LeaderboardPreview({
    required this.entries,
    required this.currentUserId,
    super.key,
  });

  final List<LeaderboardEntry> entries;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final top3 = entries.take(3).toList();
    final current = entries.firstWhere(
      (entry) => entry.id == currentUserId,
      orElse: () => LeaderboardEntry(id: currentUserId, name: 'You', points: 0, ranking: 0, level: 0),
    );
    final rankLabel = current.ranking > 0 ? '#${current.ranking} in Leaderboard' : 'Join the competition';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1733),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Top Leaderboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C4AB6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  rankLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (top3.length > 1)
                Expanded(child: _PodiumPreviewCard(entry: top3[1], rank: 2, isCenter: false)),
              if (top3.isNotEmpty)
                Expanded(child: _PodiumPreviewCard(entry: top3[0], rank: 1, isCenter: true)),
              if (top3.length > 2)
                Expanded(child: _PodiumPreviewCard(entry: top3[2], rank: 3, isCenter: false)),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: entries.isEmpty ? 0 : (current.ranking > 0 ? (entries.length - current.ranking + 1) / entries.length : 0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(const Color(0xFFF7A400)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C4AB6).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6C4AB6),
                  child: Text(
                    _initials(current.name),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current position',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rankLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A400).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${current.points} PTS',
                    style: const TextStyle(color: Color(0xFF2B0A00), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _PodiumPreviewCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCenter;

  const _PodiumPreviewCard({
    required this.entry,
    required this.rank,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFF7A400)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);
    final height = isCenter ? 170.0 : 138.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCenter)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C4AB6), Color(0xFFF7A400)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              CircleAvatar(
                radius: isCenter ? 40 : 30,
                backgroundColor: Colors.grey[850],
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              rank == 1 ? '1ST' : rank == 2 ? '2ND' : '3RD',
              style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: isCenter ? 13 : 11),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCenter ? 13 : 11,
              fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.points} PTS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rank == 1 ? const Color(0xFFF7A400) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: height,
            width: isCenter ? 84 : 60,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
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
}
