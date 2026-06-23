import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';

class VotingState {
  const VotingState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Voting> items;
  final bool isLoading;
  final String? errorMessage;

  VotingState copyWith({
    List<Voting>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VotingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class VotingController extends StateNotifier<VotingState> {
  VotingController(this._ref) : super(const VotingState());

  final Ref _ref;

  Future<void> createVoting({
    required String title,
    required VotingType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> pollOptions,
  }) async {
    await _ref
        .read(votingRepositoryProvider)
        .createVoting(
          title: title,
          type: type,
          startDate: startDate,
          endDate: endDate,
          pollOptions: pollOptions,
        );
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _ref.read(votingRepositoryProvider).getVotings();
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat voting.',
      );
    }
  }

  Future<void> castVote({
    required String votingId,
    required String optionId,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) {
      throw const AppException('Silakan login untuk menggunakan hak suara.');
    }
    if (user.role != UserRole.memberAccount) {
      throw const AppException('Voting hanya tersedia untuk akun anggota.');
    }
    await _ref
        .read(votingRepositoryProvider)
        .castVote(votingId: votingId, optionId: optionId, userId: user.id);
    await load();
  }

  Future<void> updatePeriod({
    required String votingId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _ref
        .read(votingRepositoryProvider)
        .updatePeriod(
          votingId: votingId,
          startDate: startDate,
          endDate: endDate,
        );
    await load();
  }
}

final votingControllerProvider =
    StateNotifierProvider<VotingController, VotingState>((ref) {
      return VotingController(ref);
    });
