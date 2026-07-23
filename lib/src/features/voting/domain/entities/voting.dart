enum VotingType { kegiatan, ketua }

enum VotingCalculationMethod { raw, studyProgramWeighted }

class VoteOption {
  const VoteOption({
    required this.id,
    required this.title,
    required this.votes,
    this.weightedScore,
  });

  final String id;
  final String title;
  final int votes;
  final double? weightedScore;

  VoteOption copyWith({
    String? id,
    String? title,
    int? votes,
    double? weightedScore,
  }) {
    return VoteOption(
      id: id ?? this.id,
      title: title ?? this.title,
      votes: votes ?? this.votes,
      weightedScore: weightedScore ?? this.weightedScore,
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
    this.title = '',
    this.calculationMethod = VotingCalculationMethod.raw,
    this.status = 'AKTIF',
    this.scope = 'faculty',
    this.canVote = true,
    this.eligibilityMessage = '',
  });

  final String id;
  final VotingType type;
  final String relatedId;
  final String creatorName;
  final String title;
  final VotingCalculationMethod calculationMethod;
  final DateTime startDate;
  final DateTime endDate;
  final List<VoteOption> options;
  final Set<String> voterIds;
  final String status;
  final String scope;
  final bool canVote;
  final String eligibilityMessage;

  bool get isActive {
    final now = DateTime.now();
    return status == 'AKTIF' && now.isAfter(startDate) && now.isBefore(endDate);
  }

  Voting copyWith({
    String? id,
    VotingType? type,
    String? relatedId,
    String? creatorName,
    String? title,
    VotingCalculationMethod? calculationMethod,
    DateTime? startDate,
    DateTime? endDate,
    List<VoteOption>? options,
    Set<String>? voterIds,
    String? status,
    String? scope,
    bool? canVote,
    String? eligibilityMessage,
  }) {
    return Voting(
      id: id ?? this.id,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      options: options ?? this.options,
      voterIds: voterIds ?? this.voterIds,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      canVote: canVote ?? this.canVote,
      eligibilityMessage: eligibilityMessage ?? this.eligibilityMessage,
    );
  }
}
