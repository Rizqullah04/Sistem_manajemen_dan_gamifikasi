import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/repositories/activity_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Activity> createActivity(
    Activity activity, {
    List<ActivityPhotoUpload> photos = const [],
  }) async {
    final categoryId = await _resolveCategoryId(activity.category);
    final response = await _safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/kegiatans',
        data: {
          if (activity.ormawaId.isNotEmpty) 'id_ormawa': activity.ormawaId,
          'nama_kegiatan': activity.title,
          'deskripsi': activity.description,
          'tanggal': _formatDate(activity.date),
          'poin_kegiatan': activity.pointsGenerated,
          if (categoryId != null) 'kategori_id': categoryId,
        },
      ),
    );
    final created = _mapActivity(_dataMap(response));
    if (activity.documentation.trim().isNotEmpty) {
      await _storeDocumentation(created.id, activity.documentation);
    }
    await _storeDocumentationPhotos(created.id, photos);
    return created;
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await _safeRequest(
      () => _dio.delete<Map<String, dynamic>>('/kegiatans/$activityId'),
    );
  }

  @override
  Future<void> setActivityLiked(String activityId, bool liked) async {
    await _safeRequest(
      () => liked
          ? _dio.post<Map<String, dynamic>>(
              '/like-kegiatans',
              data: {'id_kegiatan': activityId},
            )
          : _dio.delete<Map<String, dynamic>>('/kegiatans/$activityId/like'),
    );
  }

  @override
  Future<void> setActivityDisliked({
    required String activityId,
    required bool disliked,
    String? reason,
    String? solution,
  }) async {
    await _safeRequest(
      () => disliked
          ? _dio.post<Map<String, dynamic>>(
              '/dislike-kegiatans',
              data: {
                'id_kegiatan': activityId,
                'alasan': reason,
                'solusi': solution,
              },
            )
          : _dio.delete<Map<String, dynamic>>('/kegiatans/$activityId/dislike'),
    );
  }

  @override
  Future<List<ActivityFeedback>> fetchActivityFeedback(
    String activityId,
  ) async {
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>('/kegiatans/$activityId/feedback'),
    );
    return _dataList(response)
        .map(
          (item) => ActivityFeedback(
            userName:
                (item['user'] as Map?)?['nama']?.toString() ?? 'Mahasiswa',
            reason: item['alasan']?.toString() ?? '-',
            solution: item['solusi']?.toString() ?? '-',
            createdAt: DateTime.tryParse(item['created_at']?.toString() ?? ''),
          ),
        )
        .toList();
  }

  @override
  Future<ActivityPage> fetchActivities({
    required int page,
    required int pageSize,
    required User user,
  }) async {
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>('/kegiatans'),
    );
    final all = _dataList(response).map(_mapActivity).toList();
    final start = (page - 1) * pageSize;
    if (start >= all.length) {
      return const ActivityPage(items: [], hasMore: false);
    }
    final end = (start + pageSize).clamp(0, all.length);
    return ActivityPage(
      items: all.sublist(start, end),
      hasMore: end < all.length,
    );
  }

  @override
  Future<Activity> updateActivity(
    Activity activity, {
    List<ActivityPhotoUpload> photos = const [],
  }) async {
    final categoryId = await _resolveCategoryId(activity.category);
    final response = await _safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        '/kegiatans/${activity.id}',
        data: {
          'id_ormawa': activity.ormawaId,
          'nama_kegiatan': activity.title,
          'deskripsi': activity.description,
          'tanggal': _formatDate(activity.date),
          'poin_kegiatan': activity.pointsGenerated,
          if (categoryId != null) 'kategori_id': categoryId,
        },
      ),
    );
    final updated = _mapActivity(_dataMap(response));
    if (activity.documentation.trim().isNotEmpty &&
        activity.documentation.trim() != updated.documentation.trim()) {
      await _storeDocumentation(activity.id, activity.documentation);
    }
    await _storeDocumentationPhotos(activity.id, photos);
    return updated;
  }

  @override
  Future<Activity> verifyActivity({
    required String activityId,
    required ActivityStatus status,
    required String note,
  }) async {
    final response = await _safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        '/kegiatans/$activityId/verifikasi',
        data: {
          'status': switch (status) {
            ActivityStatus.approved => 'valid',
            ActivityStatus.rejected => 'ditolak',
            ActivityStatus.pending => 'valid',
          },
          'catatan': note,
        },
      ),
    );
    return _mapActivity(_dataMap(response));
  }

  Activity _mapActivity(Map<String, dynamic> json) {
    final status = switch (json['status']?.toString()) {
      'valid' => ActivityStatus.approved,
      'ditolak' => ActivityStatus.rejected,
      _ => ActivityStatus.pending,
    };
    final docs = json['dokumentasi_kegiatans'];
    String documentation = '';
    final documentationPhotos = <String>[];
    if (docs is List) {
      final docMaps = docs.whereType<Map>().toList();
      for (final doc in docMaps) {
        final url = doc['file_url']?.toString() ?? '';
        if (url.isEmpty) continue;
        if (doc['caption']?.toString() == 'Foto kegiatan') {
          documentationPhotos.add(url);
        } else {
          documentation = url;
        }
      }
    }
    final verifications = json['verifikasis'];
    String? note;
    if (verifications is List &&
        verifications.isNotEmpty &&
        verifications.last is Map) {
      note = (verifications.last as Map)['catatan']?.toString();
    }

    return Activity(
      id: json['id_kegiatan']?.toString() ?? '',
      title: json['nama_kegiatan']?.toString() ?? '',
      description: json['deskripsi']?.toString() ?? '',
      date:
          DateTime.tryParse(json['tanggal']?.toString() ?? '') ??
          DateTime.now(),
      documentation: documentation,
      category: json['kategori'] is Map
          ? ((json['kategori'] as Map)['nama_kategori']?.toString() ??
                'Tanpa Kategori')
          : 'Tanpa Kategori',
      status: status,
      ormawaId: json['id_ormawa']?.toString() ?? '',
      pointsGenerated:
          int.tryParse(json['poin_kegiatan']?.toString() ?? '0') ?? 0,
      memberIds: const [],
      verificationNote: note,
      likeCount: int.tryParse(json['jumlah_like']?.toString() ?? '0') ?? 0,
      isLiked: json['disukai_user'] == true || json['disukai_user'] == 1,
      dislikeCount:
          int.tryParse(json['jumlah_dislike']?.toString() ?? '0') ?? 0,
      isDisliked:
          json['tidak_disukai_user'] == true || json['tidak_disukai_user'] == 1,
      organizerName: json['ormawa'] is Map
          ? ((json['ormawa'] as Map)['nama_ormawa']?.toString() ?? '')
          : '',
      commentCount:
          int.tryParse(json['jumlah_komentar']?.toString() ?? '0') ?? 0,
      documentationPhotos: documentationPhotos,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _storeDocumentation(
    String activityId,
    String documentation,
  ) async {
    await _safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/dokumentasi-kegiatans',
        data: {
          'id_kegiatan': activityId,
          'caption': 'Dokumentasi lengkap',
          'file_url': documentation.trim(),
        },
      ),
    );
  }

  Future<void> _storeDocumentationPhotos(
    String activityId,
    List<ActivityPhotoUpload> photos,
  ) async {
    for (final photo in photos) {
      await _safeRequest(
        () => _dio.post<Map<String, dynamic>>(
          '/dokumentasi-kegiatans',
          data: FormData.fromMap({
            'id_kegiatan': activityId,
            'caption': 'Foto kegiatan',
            'file': MultipartFile.fromBytes(
              photo.bytes,
              filename: photo.fileName,
            ),
          }),
        ),
      );
    }
  }

  Future<String?> _resolveCategoryId(String name) async {
    if (name.trim().isEmpty || name == 'Tanpa Kategori') return null;
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>('/kategori-kegiatans'),
    );
    for (final item in _dataList(response)) {
      if (item['nama_kategori']?.toString().toLowerCase() ==
          name.trim().toLowerCase()) {
        return item['id']?.toString();
      }
    }
    return null;
  }

  Map<String, dynamic> _dataMap(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppException('Response kegiatan tidak valid.');
  }

  List<Map<String, dynamic>> _dataList(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data?['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    throw const AppException('Response kegiatan tidak valid.');
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
      throw const AppException('Tidak dapat terhubung ke API kegiatan.');
    }
  }
}
