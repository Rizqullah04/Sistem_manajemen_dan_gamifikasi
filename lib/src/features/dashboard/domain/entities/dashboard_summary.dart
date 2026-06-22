class DashboardSummary {
  const DashboardSummary({
    required this.totalActivities,
    required this.totalPoints,
    required this.currentRanking,
    required this.monthlyActivities,
    required this.notifications,
    this.pendingMemberCount = 0,
  });

  final int totalActivities;
  final int totalPoints;
  final int currentRanking;
  final Map<int, int> monthlyActivities;
  final List<String> notifications;
  final int pendingMemberCount;
}
