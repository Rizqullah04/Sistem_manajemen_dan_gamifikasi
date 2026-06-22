import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/utils/level_calculator.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<(String, User)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data ?? <String, dynamic>{};
      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppException('Response login tidak valid.');
      }

      final token = data['token']?.toString();
      final userData = data['user'];
      if (token == null || token.isEmpty || userData is! Map<String, dynamic>) {
        throw const AppException('Response login tidak valid.');
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      return (token, _mapUser(userData));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw AppException(message);
        }
      }

      final statusCode = e.response?.statusCode;
      if (statusCode != null) {
        throw AppException(
          'API merespons HTTP $statusCode di ${_dio.options.baseUrl}. Periksa kembali base URL dan route API.',
        );
      }

      throw AppException(
        'Tidak dapat terhubung ke server API (${_dio.options.baseUrl}). Pastikan alamat API sudah benar.',
      );
    }
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  User _mapUser(Map<String, dynamic> data) {
    final role = switch (data['role']?.toString()) {
      'admin' => UserRole.adminFaculty,
      'ormawa' => UserRole.ormawaAccount,
      _ => UserRole.memberAccount,
    };

    final points = int.tryParse(data['poin']?.toString() ?? '0') ?? 0;

    return User(
      id: data['id_user']?.toString() ?? data['id']?.toString() ?? '',
      name: data['nama']?.toString() ?? data['name']?.toString() ?? '',
      studentStaffId: data['email']?.toString() ?? '',
      role: role,
      points: points,
      level: levelFromPoints(points),
      ormawaId: data['id_ormawa']?.toString(),
    );
  }
}
