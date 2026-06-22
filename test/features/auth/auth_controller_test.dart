import 'package:flutter_test/flutter_test.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.shouldFail = false});

  final bool shouldFail;
  User? _user;
  String? _token;

  @override
  User? get currentUser => _user;

  @override
  String? get token => _token;

  @override
  Future<(String token, User user)> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw const AppException('invalid');
    }
    const user = User(
      id: 'u1',
      name: 'Tester',
      studentStaffId: 'ANG001',
      role: UserRole.memberAccount,
      points: 0,
      level: 1,
      ormawaId: 'o1',
    );
    _user = user;
    _token = 'mock.jwt.token';
    return (_token!, user);
  }

  @override
  Future<void> logout() async {
    _token = null;
    _user = null;
  }
}

void main() {
  group('Login validation', () {
    test('student ID validation', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('A1'), isNotNull);
      expect(validateEmail('admin@example.com'), isNull);
    });

    test('password validation', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('secret12'), isNull);
    });
  });

  group('AuthController', () {
    test('login success updates authenticated state', () async {
      final repository = FakeAuthRepository();
      final controller = AuthController(
        LoginUseCase(repository),
        repository,
      );
      await controller.login(email: 'anggota@example.com', password: 'member123');
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user?.name, 'Tester');
      expect(controller.state.token, isNotNull);
    });

    test('login failure updates error state', () async {
      final repository = FakeAuthRepository(shouldFail: true);
      final controller = AuthController(
        LoginUseCase(repository),
        repository,
      );
      await controller.login(email: 'anggota@example.com', password: 'wrong');
      expect(controller.state.status, AuthStatus.error);
      expect(controller.state.errorMessage, isNotNull);
    });
  });
}
