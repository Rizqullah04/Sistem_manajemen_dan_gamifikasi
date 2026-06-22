class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.points,
    required this.ranking,
    required this.level,
  });

  final String id;
  final String name;
  final int points;
  final int ranking;
  final int level;
}
