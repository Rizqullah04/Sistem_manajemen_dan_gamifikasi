class StudentGamificationModel {
  const StudentGamificationModel({
    required this.studentId,
    required this.studentName,
    required this.totalPoints,
    required this.badges,
    required this.availableBadges,
    required this.activityStatus,
    required this.pointLogs,
  });

  final String studentId;
  final String studentName;
  final int totalPoints;
  final List<StudentBadgeModel> badges;
  final List<StudentBadgeModel> availableBadges;
  final StudentActivityStatus activityStatus;
  final List<StudentPointLogModel> pointLogs;

  factory StudentGamificationModel.fromJson(Map<String, dynamic> json) {
    final logsData = json['poin_logs'];
    final pointLogs = logsData is List
        ? logsData
              .whereType<Map<String, dynamic>>()
              .map(StudentPointLogModel.fromJson)
              .toList()
        : const <StudentPointLogModel>[];
    final totalPointsFromLogs = pointLogs.fold<int>(
      0,
      (sum, log) => sum + log.points,
    );
    final parsedTotal =
        int.tryParse(json['total_poin']?.toString() ?? '') ??
        int.tryParse(json['poin']?.toString() ?? '') ??
        totalPointsFromLogs;
    final badgesData = json['badges'];
    final availableBadgesData = json['available_badges'];
    final badges = badgesData is List
        ? badgesData
              .whereType<Map<String, dynamic>>()
              .map(StudentBadgeModel.fromJson)
              .toList()
        : const <StudentBadgeModel>[];
    final availableBadges = availableBadgesData is List
        ? availableBadgesData
              .whereType<Map<String, dynamic>>()
              .map(StudentBadgeModel.fromJson)
              .toList()
        : badges;

    return StudentGamificationModel(
      studentId: json['id_user']?.toString() ?? '',
      studentName: json['nama']?.toString() ?? '-',
      totalPoints: parsedTotal,
      activityStatus: StudentActivityStatus.fromPoints(parsedTotal),
      pointLogs: pointLogs,
      badges: badges,
      availableBadges: availableBadges,
    );
  }
}

class StudentBadgeModel {
  const StudentBadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumPoints,
    required this.activityType,
    required this.status,
    this.icon,
    this.awardedAt,
  });

  final String id;
  final String name;
  final String description;
  final int minimumPoints;
  final String activityType;
  final String status;
  final String? icon;
  final DateTime? awardedAt;

  factory StudentBadgeModel.fromJson(Map<String, dynamic> json) {
    final awardedAt = DateTime.tryParse(
      json['awarded_at']?.toString() ??
          json['tanggal_diperoleh']?.toString() ??
          '',
    );
    final rawStatus = json['status']?.toString().toLowerCase().trim();

    return StudentBadgeModel(
      id: json['id']?.toString() ?? '',
      name: json['nama_badge']?.toString() ?? '-',
      description: json['deskripsi']?.toString() ?? '',
      minimumPoints:
          int.tryParse(json['minimal_poin']?.toString() ?? '0') ?? 0,
      activityType: json['activity_type']?.toString() ?? 'Poin Kumulatif',
      status: rawStatus == null || rawStatus.isEmpty
          ? (awardedAt == null ? 'locked' : 'unlocked')
          : rawStatus,
      icon: json['icon']?.toString(),
      awardedAt: awardedAt,
    );
  }

  bool get isUnlocked => status == 'unlocked' || status == 'earned';
}

class StudentPointLogModel {
  const StudentPointLogModel({
    required this.id,
    required this.source,
    required this.points,
    required this.description,
    this.date,
  });

  final String id;
  final String source;
  final int points;
  final String description;
  final DateTime? date;

  factory StudentPointLogModel.fromJson(Map<String, dynamic> json) {
    return StudentPointLogModel(
      id: json['id_poin_log']?.toString() ?? '',
      source: json['sumber']?.toString() ?? 'Aktivitas',
      points: int.tryParse(json['poin']?.toString() ?? '0') ?? 0,
      description: json['keterangan']?.toString() ?? '',
      date: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
    );
  }
}

enum StudentActivityStatus {
  inactive('Kurang Aktif', 'Mulai ikut kegiatan untuk menaikkan status.'),
  active('Aktif', 'Konsisten mengikuti aktivitas kampus.'),
  veryActive('Sangat Aktif', 'Kontribusi kamu sangat kuat periode ini.');

  const StudentActivityStatus(this.label, this.description);

  final String label;
  final String description;

  static StudentActivityStatus fromPoints(int points) {
    if (points >= 300) return StudentActivityStatus.veryActive;
    if (points >= 100) return StudentActivityStatus.active;
    return StudentActivityStatus.inactive;
  }
}
