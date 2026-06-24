import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/student_gamification_model.dart';

abstract class StudentGamificationRepository {
  Future<StudentGamificationModel> getCurrentStudentGamification();
}
