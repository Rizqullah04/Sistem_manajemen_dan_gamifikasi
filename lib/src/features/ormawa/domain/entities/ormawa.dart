class Ormawa {
  const Ormawa({
    required this.id,
    required this.name,
    required this.totalPoints,
    required this.ranking,
  });

  final String id;
  final String name;
  final int totalPoints;
  final int ranking;

  Ormawa copyWith({
    String? id,
    String? name,
    int? totalPoints,
    int? ranking,
  }) {
    return Ormawa(
      id: id ?? this.id,
      name: name ?? this.name,
      totalPoints: totalPoints ?? this.totalPoints,
      ranking: ranking ?? this.ranking,
    );
  }
}
