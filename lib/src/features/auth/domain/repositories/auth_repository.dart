import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<(String token, User user)> login({
    required String email,
    required String password,
  });

  User? get currentUser;
  String? get token;
  Future<User> profile();
  Future<User> updateProfile({
    required String name,
    required String nim,
    required String email,
  });
  Future<void> logout();
}
