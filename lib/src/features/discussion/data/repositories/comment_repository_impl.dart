import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/entities/comment.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> addComment({
    required String activityId,
    required String userId,
    required String content,
  }) async {
    await _safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/diskusis',
        data: {
          'id_kegiatan': activityId,
          'id_user': userId,
          'komentar': content,
        },
      ),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _safeRequest(
      () => _dio.delete<Map<String, dynamic>>('/diskusis/$commentId'),
    );
  }

  @override
  Stream<List<CommentItem>> watchByActivity(String activityId) async* {
    while (true) {
      yield await _fetchByActivity(activityId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<List<CommentItem>> _fetchByActivity(String activityId) async {
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/diskusis',
        queryParameters: {'id_kegiatan': activityId},
      ),
    );
    final data = response.data?['data'];
    if (data is! List)
      throw const AppException('Response diskusi tidak valid.');
    return data.whereType<Map<String, dynamic>>().map(_mapComment).toList();
  }

  CommentItem _mapComment(Map<String, dynamic> json) {
    final user = json['user'];
    return CommentItem(
      id: json['id_diskusi']?.toString() ?? '',
      userId: json['id_user']?.toString() ?? '',
      kegiatanId: json['id_kegiatan']?.toString() ?? '',
      content: json['komentar']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['tanggal']?.toString() ?? '') ??
          DateTime.now(),
      userName: user is Map<String, dynamic> ? user['nama']?.toString() : null,
    );
  }

  Future<Response<Map<String, dynamic>>> _safeRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw AppException(data['message'] as String);
      }
      throw const AppException('Tidak dapat terhubung ke API diskusi.');
    }
  }
}
