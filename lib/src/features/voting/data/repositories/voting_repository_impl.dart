import 'package:dio/dio.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/repositories/voting_repository.dart';

class VotingRepositoryImpl implements VotingRepository {
  VotingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Voting> createVoting({
    required String title,
    required VotingType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> pollOptions,
  }) async {
    final response = await _safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/votings',
        data: {
          'judul_voting': title,
          'tanggal_mulai': _formatDate(startDate),
          'tanggal_selesai': _formatDate(endDate),
          'jenis_voting': type == VotingType.ketua ? 'ketua' : 'kegiatan',
          'poll_options': pollOptions,
          'status': 'aktif',
        },
      ),
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) return _mapVoting(data);
    throw const AppException('Response voting tidak valid.');
  }

  @override
  Future<Voting> castVote({
    required String votingId,
    required String optionId,
    required String userId,
  }) async {
    await _safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/vote-details',
        data: {'id_voting': votingId, 'pilihan': optionId},
      ),
    );
    final items = await getVotings();
    return items.firstWhere((item) => item.id == votingId);
  }

  @override
  Future<List<Voting>> getVotings() async {
    final response = await _safeRequest(
      () => _dio.get<Map<String, dynamic>>('/votings'),
    );
    final data = response.data?['data'];
    if (data is! List) throw const AppException('Response voting tidak valid.');
    return data.whereType<Map<String, dynamic>>().map(_mapVoting).toList();
  }

  @override
  Future<Voting> updatePeriod({
    required String votingId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        '/votings/$votingId',
        data: {
          'tanggal_mulai': _formatDate(startDate),
          'tanggal_selesai': _formatDate(endDate),
        },
      ),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) return _mapVoting(data);
    throw const AppException('Response voting tidak valid.');
  }

  @override
  Future<Voting> updateStatus({
    required String votingId,
    required String status,
  }) async {
    final response = await _safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        '/votings/$votingId',
        data: {'status': status.toLowerCase()},
      ),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) return _mapVoting(data);
    throw const AppException('Response voting tidak valid.');
  }

  @override
  Future<void> deleteVoting(String votingId) async {
    await _safeRequest(
      () => _dio.delete<Map<String, dynamic>>('/votings/$votingId'),
    );
  }

  @override
  Future<int> clearCompletedVotingLogs() async {
    final response = await _safeRequest(
      () => _dio.delete<Map<String, dynamic>>('/votings/completed-logs'),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return int.tryParse(data['deleted_count']?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Voting _mapVoting(Map<String, dynamic> json) {
    final voteDetails = json['vote_details'];
    final pollOptionsJson = json['poll_options'];
    final counts = <String, int>{};
    final voters = <String>{};
    if (voteDetails is List) {
      for (final item in voteDetails.whereType<Map>()) {
        final pilihan = item['pilihan']?.toString();
        if (pilihan == null || pilihan.isEmpty) continue;
        counts[pilihan] = (counts[pilihan] ?? 0) + 1;
        final userId = item['id_user']?.toString();
        if (userId != null) voters.add(userId);
      }
    }
    final pollOptions = <String>[];
    if (pollOptionsJson is List) {
      pollOptions.addAll(
        pollOptionsJson.whereType<Object>().map((item) => item.toString()),
      );
    }

    final sourceOptions = pollOptions.isNotEmpty
        ? pollOptions
        : counts.keys.toList(growable: false);

    final options = sourceOptions
        .map(
          (entry) =>
              VoteOption(id: entry, title: entry, votes: counts[entry] ?? 0),
        )
        .toList();
    if (options.isEmpty) {
      options.addAll(const [
        VoteOption(id: 'setuju', title: 'Setuju', votes: 0),
        VoteOption(id: 'tidak_setuju', title: 'Tidak Setuju', votes: 0),
      ]);
    }

    return Voting(
      id: json['id_voting']?.toString() ?? '',
      type: json['jenis_voting']?.toString() == 'ketua'
          ? VotingType.ketua
          : VotingType.kegiatan,
      relatedId: json['id_kegiatan']?.toString() ?? '',
      creatorName: _creatorNameFrom(json),
      title: json['judul_voting']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['tanggal_mulai']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['tanggal_selesai']?.toString() ?? '') ??
          DateTime.now(),
      options: options,
      voterIds: voters,
      status: _statusFrom(json['status']),
      scope: json['voting_scope']?.toString() ?? 'faculty',
      canVote: json['can_vote'] == true || json['can_vote'] == 1,
      eligibilityMessage: json['eligibility_message']?.toString() ?? '',
    );
  }

  String _statusFrom(Object? value) {
    final status = value?.toString().toUpperCase();
    return status == 'SELESAI' ? 'SELESAI' : 'AKTIF';
  }

  String _creatorNameFrom(Map<String, dynamic> json) {
    final candidates = [
      json['creator_name'],
      json['nama_ormawa'],
      json['ormawa_name'],
      if (json['ormawa'] is Map) (json['ormawa'] as Map)['nama_ormawa'],
      if (json['ormawa'] is Map) (json['ormawa'] as Map)['name'],
      json['created_by_name'],
      json['sender_name'],
      json['email'],
      json['created_by_email'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value == null || value.isEmpty) continue;
      return _displayNameFromAccount(value);
    }

    final ormawaId = json['id_ormawa']?.toString().trim();
    if (ormawaId != null && ormawaId.isNotEmpty) {
      return 'Ormawa #$ormawaId';
    }
    return 'Ormawa Pembuat';
  }

  String _displayNameFromAccount(String value) {
    if (!value.contains('@')) return value;
    final localPart = value.split('@').first;
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map(_capitalizeWord)
        .toList();
    if (words.isEmpty) return 'Ormawa Pembuat';
    return words.join(' ');
  }

  String _capitalizeWord(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
      throw const AppException('Tidak dapat terhubung ke API voting.');
    }
  }
}
