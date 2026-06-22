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
      startDate:
          DateTime.tryParse(json['tanggal_mulai']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['tanggal_selesai']?.toString() ?? '') ??
          DateTime.now(),
      options: options,
      voterIds: voters,
    );
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
