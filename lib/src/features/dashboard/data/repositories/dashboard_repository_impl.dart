import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/utils/level_calculator.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/period_status.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LeaderboardEntry>> getMemberLeaderboard() async {
    return _fetchLeaderboard('individu');
  }

  @override
  Future<List<LeaderboardEntry>> getOrmawaLeaderboard() async {
    return _fetchLeaderboard('ormawa');
  }

  @override
  Future<PeriodStatus> getPeriodStatus() async {
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>('/periods/current'),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppException('Response periode tidak valid.');
    }

    return PeriodStatus.fromJson(data);
  }

  @override
  Future<PeriodResetResult> endCurrentPeriod() async {
    final response = await _safeRequest(
      () => _dio.post<Map<String, dynamic>>('/periods/end-current'),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppException('Response reset periode tidak valid.');
    }

    return PeriodResetResult.fromJson(data);
  }

  @override
  Future<DashboardSummary> getSummary(User user) async {
    final activitiesResponse = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/kegiatans',
        queryParameters: {
          if (user.role == UserRole.ormawaAccount && user.ormawaId != null)
            'id_ormawa': user.ormawaId,
        },
      ),
    );
    final activities = activitiesResponse.data?['data'];
    final activityList = activities is List
        ? activities.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final leaderboard = user.role == UserRole.ormawaAccount
        ? await getOrmawaLeaderboard()
        : await getMemberLeaderboard();
    final ormawaMembers = user.role == UserRole.ormawaAccount
        ? await _fetchOrmawaMembers()
        : const <Map<String, dynamic>>[];
    final pendingMembers = ormawaMembers
        .where((member) => member['status_akun']?.toString() == 'pending')
        .toList();
    final ranking = leaderboard.indexWhere((entry) {
      if (user.role == UserRole.ormawaAccount) return entry.id == user.ormawaId;
      return entry.id == user.id;
    }) + 1;

    return DashboardSummary(
      totalActivities: activityList.length,
      totalPoints: user.points,
      currentRanking: ranking == 0 ? 1 : ranking,
      monthlyActivities: _monthlyActivityChart(activityList),
      pendingMemberCount: pendingMembers.length,
      notifications: [
        if (pendingMembers.isNotEmpty)
          '${pendingMembers.length} anggota baru menunggu verifikasi Ormawa.',
        ...pendingMembers.take(3).map(
              (member) =>
                  '${member['nama'] ?? 'Anggota baru'} memilih Ormawa Anda saat registrasi.',
            ),
        ..._activityNotifications(activityList, user),
      ],
    );
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboard(String type) async {
    final response = await _safeRequest(() => _dio.get<Map<String, dynamic>>(
          '/leaderboard',
          queryParameters: {'tipe': type},
        ));
    final data = response.data?['data'];
    if (data is! List) {
      throw const AppException('Response leaderboard tidak valid.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(_mapLeaderboardEntry)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchOrmawaMembers() async {
    final response = await _safeRequest(() => _dio.get<Map<String, dynamic>>(
          '/ormawa/members',
        ));
    final data = response.data?['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  LeaderboardEntry _mapLeaderboardEntry(Map<String, dynamic> json) {
    final points = int.tryParse(json['poin']?.toString() ?? '0') ?? 0;
    return LeaderboardEntry(
      id: json['id_user']?.toString() ?? json['id_ormawa']?.toString() ?? '',
      name: json['nama']?.toString() ?? '-',
      points: points,
      ranking: int.tryParse(json['ranking']?.toString() ?? '0') ?? 0,
      level: levelFromPoints(points),
    );
  }

  Map<int, int> _monthlyActivityChart(List<Map<String, dynamic>> activities) {
    final data = <int, int>{for (var month = 1; month <= 12; month++) month: 0};
    final year = DateTime.now().year;
    for (final activity in activities) {
      final date = DateTime.tryParse(activity['tanggal']?.toString() ?? '');
      if (date != null && date.year == year) {
        data[date.month] = (data[date.month] ?? 0) + 1;
      }
    }
    return data;
  }

  List<String> _activityNotifications(
    List<Map<String, dynamic>> activities,
    User user,
  ) {
    final sortedActivities = [...activities]
      ..sort((a, b) {
        final aDate = DateTime.tryParse(
              a['created_at']?.toString() ?? a['tanggal']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(
              b['created_at']?.toString() ?? b['tanggal']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return sortedActivities.take(3).map((activity) {
      final title = activity['nama_kegiatan']?.toString().trim();
      final displayTitle = title == null || title.isEmpty
          ? 'Kegiatan baru'
          : title;
      final status = activity['status']?.toString();

      if (user.role == UserRole.ormawaAccount) {
        if (status == 'pending') {
          return '$displayTitle menunggu verifikasi fakultas.';
        }
        if (status == 'ditolak') {
          return '$displayTitle ditolak dan perlu diperbaiki.';
        }
        return '$displayTitle sudah terverifikasi.';
      }

      return 'Kegiatan baru tersedia: $displayTitle.';
    }).toList();
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
      throw const AppException('Tidak dapat terhubung ke API dashboard.');
    }
  }
}
