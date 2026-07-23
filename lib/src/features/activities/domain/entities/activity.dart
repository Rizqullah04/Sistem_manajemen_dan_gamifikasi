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
    this.likeCount = 0,
    this.isLiked = false,
    this.dislikeCount = 0,
    this.isDisliked = false,
    this.organizerName = '',
    this.commentCount = 0,
    this.documentationPhotos = const [],
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
  final int likeCount;
  final bool isLiked;
  final int dislikeCount;
  final bool isDisliked;
  final String organizerName;
  final int commentCount;
  final List<String> documentationPhotos;

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
    int? likeCount,
    bool? isLiked,
    int? dislikeCount,
    bool? isDisliked,
    String? organizerName,
    int? commentCount,
    List<String>? documentationPhotos,
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
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isDisliked: isDisliked ?? this.isDisliked,
      organizerName: organizerName ?? this.organizerName,
      commentCount: commentCount ?? this.commentCount,
      documentationPhotos: documentationPhotos ?? this.documentationPhotos,
    );
  }
}

class ActivityPage {
  const ActivityPage({required this.items, required this.hasMore});

  final List<Activity> items;
  final bool hasMore;
}
