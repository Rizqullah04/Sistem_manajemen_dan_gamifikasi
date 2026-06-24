import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/student_gamification_model.dart';

final studentGamificationControllerProvider = AutoDisposeAsyncNotifierProvider<
    StudentGamificationController, StudentGamificationModel>(
  StudentGamificationController.new,
);

class StudentGamificationController
    extends AutoDisposeAsyncNotifier<StudentGamificationModel> {
  @override
  Future<StudentGamificationModel> build() {
    return _fetch();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<StudentGamificationModel> _fetch() {
    return ref
        .watch(studentGamificationRepositoryProvider)
        .getCurrentStudentGamification();
  }
}
