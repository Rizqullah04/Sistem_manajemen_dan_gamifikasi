import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';

abstract class VotingRepository {
  Future<List<Voting>> getVotings();
  Future<Voting> createVoting({
    required String title,
    required VotingType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> pollOptions,
  });
  Future<Voting> castVote({
    required String votingId,
    required String optionId,
    required String userId,
  });
  Future<Voting> updatePeriod({
    required String votingId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Voting> updateStatus({
    required String votingId,
    required String status,
  });
  Future<void> deleteVoting(String votingId);
}
