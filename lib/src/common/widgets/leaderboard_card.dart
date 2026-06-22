import 'package:flutter/material.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

String _entryInitials(String name) {
  if (name.isEmpty) {
    return '?';
  }
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    required this.entries,
    required this.currentUserId,
    super.key,
  });

  final List<LeaderboardEntry> entries;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final topEntries = entries.take(3).toList();
    final remaining = entries.skip(3).take(4).toList();
    final userEntry = entries.firstWhere(
      (entry) => entry.id == currentUserId,
      orElse: () => LeaderboardEntry(id: currentUserId, name: 'You', points: 0, ranking: 0, level: 0),
    );
    final topPercent = entries.isEmpty ? 0 : ((1 - (userEntry.ranking / entries.length)) * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141227),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Leaderboard Preview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C4AB6)),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (topEntries.length > 1) _PodiumMember(entry: topEntries[1], rank: 2),
              if (topEntries.isNotEmpty) _PodiumMember(entry: topEntries[0], rank: 1, isCenter: true),
              if (topEntries.length > 2) _PodiumMember(entry: topEntries[2], rank: 3),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C4AB6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your leaderboard progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${userEntry.ranking} · Top $topPercent%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A400).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFF2B0A00), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${userEntry.points} PTS',
                        style: const TextStyle(color: Color(0xFF2B0A00), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...remaining.map((entry) => _LeaderboardRow(entry: entry, isCurrent: entry.id == currentUserId)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'See full leaderboard to track every milestone',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumMember extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCenter;

  const _PodiumMember({
    required this.entry,
    required this.rank,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? const Color(0xFFF7A400)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);
    final height = isCenter ? 190.0 : 150.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCenter)
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C4AB6), Color(0xFFF7A400)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              CircleAvatar(
                radius: isCenter ? 44 : 32,
                backgroundColor: Colors.grey[850],
                child: Text(
                  _entryInitials(entry.name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isCenter ? 18 : 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              rank == 1 ? '1ST' : rank == 2 ? '2ND' : '3RD',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isCenter ? FontWeight.w800 : FontWeight.w700,
              fontSize: isCenter ? 14 : 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.points} PTS',
            style: TextStyle(
              color: rank == 1 ? const Color(0xFFF7A400) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: isCenter ? 13 : 11,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: height,
            width: isCenter ? 96 : 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrent;

  const _LeaderboardRow({required this.entry, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF6C4AB6).withValues(alpha: 0.18) : const Color(0xFF1A1733),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6C4AB6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.ranking}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[900],
            child: Text(
              _entryInitials(entry.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.level > 0 ? 'Level ${entry.level}' : 'Ormawa',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${entry.points} PTS',
            style: const TextStyle(color: Color(0xFF6C4AB6), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

}
