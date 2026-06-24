import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/student_gamification_model.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/repositories/student_gamification_repository.dart';

class StudentGamificationRepositoryImpl
    implements StudentGamificationRepository {
  StudentGamificationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<StudentGamificationModel> getCurrentStudentGamification() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/profile/gamification',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppException('Response gamifikasi mahasiswa tidak valid.');
      }

      return StudentGamificationModel.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw AppException(data['message'] as String);
      }
      throw const AppException('Tidak dapat mengambil data gamifikasi.');
    }
  }
}
