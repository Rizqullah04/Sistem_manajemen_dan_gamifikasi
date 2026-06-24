import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/config/api_config.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/data/repositories/activity_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/repositories/activity_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/data/repositories/comment_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/repositories/comment_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/data/repositories/student_gamification_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/repositories/student_gamification_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/data/repositories/voting_repository_impl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/repositories/voting_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(ref.watch(dioProvider));
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepositoryImpl(ref.watch(dioProvider));
});

final votingRepositoryProvider = Provider<VotingRepository>((ref) {
  return VotingRepositoryImpl(ref.watch(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dioProvider));
});

final studentGamificationRepositoryProvider =
    Provider<StudentGamificationRepository>((ref) {
  return StudentGamificationRepositoryImpl(ref.watch(dioProvider));
});
