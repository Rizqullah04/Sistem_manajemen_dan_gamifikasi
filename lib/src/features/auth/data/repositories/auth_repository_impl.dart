import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  String? _token;
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  String? get token => _token;

  @override
  Future<(String token, User user)> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    _token = result.$1;
    _user = result.$2;
    return (result.$1, result.$2);
  }

  @override
  Future<void> logout() async {
    _remoteDataSource.clearToken();
    _token = null;
    _user = null;
  }
}
