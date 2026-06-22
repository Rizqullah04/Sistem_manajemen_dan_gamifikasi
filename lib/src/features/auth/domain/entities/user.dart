import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.studentStaffId,
    required this.role,
    required this.points,
    required this.level,
    this.ormawaId,
  });

  final String id;
  final String name;
  final String studentStaffId;
  final UserRole role;
  final int points;
  final int level;
  final String? ormawaId;

  User copyWith({
    String? id,
    String? name,
    String? studentStaffId,
    UserRole? role,
    int? points,
    int? level,
    String? ormawaId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      studentStaffId: studentStaffId ?? this.studentStaffId,
      role: role ?? this.role,
      points: points ?? this.points,
      level: level ?? this.level,
      ormawaId: ormawaId ?? this.ormawaId,
    );
  }
}
