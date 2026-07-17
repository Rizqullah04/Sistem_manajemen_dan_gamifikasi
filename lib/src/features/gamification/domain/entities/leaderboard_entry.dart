class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.points,
    required this.ranking,
    required this.level,
    this.organizationName = '',
  });

  final String id;
  final String name;
  final int points;
  final int ranking;
  final int level;
  final String organizationName;
}
