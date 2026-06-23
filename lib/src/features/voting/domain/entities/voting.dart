enum VotingType { kegiatan, ketua }

class VoteOption {
  const VoteOption({
    required this.id,
    required this.title,
    required this.votes,
  });

  final String id;
  final String title;
  final int votes;

  VoteOption copyWith({String? id, String? title, int? votes}) {
    return VoteOption(
      id: id ?? this.id,
      title: title ?? this.title,
      votes: votes ?? this.votes,
    );
  }
}

class Voting {
  const Voting({
    required this.id,
    required this.type,
    required this.relatedId,
    required this.creatorName,
    required this.startDate,
    required this.endDate,
    required this.options,
    required this.voterIds,
  });

  final String id;
  final VotingType type;
  final String relatedId;
  final String creatorName;
  final DateTime startDate;
  final DateTime endDate;
  final List<VoteOption> options;
  final Set<String> voterIds;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Voting copyWith({
    String? id,
    VotingType? type,
    String? relatedId,
    String? creatorName,
    DateTime? startDate,
    DateTime? endDate,
    List<VoteOption>? options,
    Set<String>? voterIds,
  }) {
    return Voting(
      id: id ?? this.id,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      creatorName: creatorName ?? this.creatorName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      options: options ?? this.options,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}
