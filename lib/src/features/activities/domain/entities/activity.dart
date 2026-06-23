enum ActivityStatus { pending, approved, rejected }

extension ActivityStatusX on ActivityStatus {
  String get label {
    switch (this) {
      case ActivityStatus.pending:
        return 'Menunggu Verifikasi';
      case ActivityStatus.approved:
        return 'Disetujui';
      case ActivityStatus.rejected:
        return 'Ditolak';
    }
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.documentation,
    required this.category,
    required this.status,
    required this.ormawaId,
    required this.pointsGenerated,
    required this.memberIds,
    this.verificationNote,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String documentation;
  final String category;
  final ActivityStatus status;
  final String ormawaId;
  final int pointsGenerated;
  final List<String> memberIds;
  final String? verificationNote;

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? documentation,
    String? category,
    ActivityStatus? status,
    String? ormawaId,
    int? pointsGenerated,
    List<String>? memberIds,
    String? verificationNote,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      documentation: documentation ?? this.documentation,
      category: category ?? this.category,
      status: status ?? this.status,
      ormawaId: ormawaId ?? this.ormawaId,
      pointsGenerated: pointsGenerated ?? this.pointsGenerated,
      memberIds: memberIds ?? this.memberIds,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }
}

class ActivityPage {
  const ActivityPage({required this.items, required this.hasMore});

  final List<Activity> items;
  final bool hasMore;
}
