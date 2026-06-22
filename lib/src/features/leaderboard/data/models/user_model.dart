enum RankMovement { up, down, stable }

class UserModel {
  final String id;
  final String name;
  final String avatar;
  final int points;
  final int rank;
  final String ormawa;
  final bool isVerified;
  final bool isActive;
  final bool isTopContributor;
  final RankMovement movement;

  UserModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.points,
    required this.rank,
    required this.ormawa,
    this.isVerified = false,
    this.isActive = false,
    this.isTopContributor = false,
    this.movement = RankMovement.stable,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      points: json['points'],
      rank: json['rank'],
      ormawa: json['ormawa'],
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? false,
      isTopContributor: json['isTopContributor'] ?? false,
      movement: RankMovement.values.firstWhere(
        (movement) => movement.name == (json['movement'] as String? ?? 'stable'),
        orElse: () => RankMovement.stable,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'points': points,
      'rank': rank,
      'ormawa': ormawa,
      'isVerified': isVerified,
      'isActive': isActive,
      'isTopContributor': isTopContributor,
      'movement': movement.name,
    };
  }
}