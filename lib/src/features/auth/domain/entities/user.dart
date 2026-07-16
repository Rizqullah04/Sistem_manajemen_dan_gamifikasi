import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.studentStaffId,
    this.email = '',
    required this.role,
    required this.points,
    required this.level,
    this.ormawaId,
    this.ormawaPoints,
    this.badges = const [],
  });

  final String id;
  final String name;
  final String studentStaffId;
  final String email;
  final UserRole role;
  final int points;
  final int level;
  final String? ormawaId;
  final int? ormawaPoints;
  final List<String> badges;

  int get effectivePoints {
    if (role == UserRole.ormawaAccount) return ormawaPoints ?? points;
    return points;
  }

  User copyWith({
    String? id,
    String? name,
    String? studentStaffId,
    String? email,
    UserRole? role,
    int? points,
    int? level,
    String? ormawaId,
    int? ormawaPoints,
    List<String>? badges,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      studentStaffId: studentStaffId ?? this.studentStaffId,
      email: email ?? this.email,
      role: role ?? this.role,
      points: points ?? this.points,
      level: level ?? this.level,
      ormawaId: ormawaId ?? this.ormawaId,
      ormawaPoints: ormawaPoints ?? this.ormawaPoints,
      badges: badges ?? this.badges,
    );
  }
}
