import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/repositories/activity_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/presentation/providers/point_sync_provider.dart';

class ActivityState {
  const ActivityState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<Activity> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  ActivityState copyWith({
    List<Activity>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ActivityState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class ActivityController extends StateNotifier<ActivityState> {
  ActivityController(this._ref) : super(const ActivityState());

  final Ref _ref;
  static const int _pageSize = 6;

  Future<void> loadInitial() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return;
    state = state.copyWith(
      isLoading: true,
      page: 1,
      hasMore: true,
      errorMessage: null,
    );
    try {
      final page = await _ref
          .read(activityRepositoryProvider)
          .fetchActivities(page: 1, pageSize: _pageSize, user: user);
      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    final nextPage = state.page + 1;
    final page = await _ref
        .read(activityRepositoryProvider)
        .fetchActivities(page: nextPage, pageSize: _pageSize, user: user);
    state = state.copyWith(
      items: [...state.items, ...page.items],
      page: nextPage,
      hasMore: page.hasMore,
      isLoadingMore: false,
    );
  }

  Future<void> create({
    required String title,
    required String description,
    required DateTime date,
    required String documentation,
    required String category,
    List<ActivityPhotoUpload> photos = const [],
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null ||
        (user.role != UserRole.adminFaculty &&
            user.role != UserRole.ormawaAccount)) {
      return;
    }
    final activity = Activity(
      id: '',
      title: title,
      description: description,
      date: date,
      documentation: documentation,
      category: category,
      status: ActivityStatus.pending,
      ormawaId: user.ormawaId ?? '',
      pointsGenerated: 0,
      memberIds: const ['u3', 'u4'],
    );
    await _ref
        .read(activityRepositoryProvider)
        .createActivity(activity, photos: photos);
    await loadInitial();
  }

  Future<void> update({
    required Activity activity,
    required String title,
    required String description,
    required DateTime date,
    required String documentation,
    required String category,
    List<ActivityPhotoUpload> photos = const [],
  }) async {
    final updatedActivity = activity.copyWith(
      title: title,
      description: description,
      date: date,
      documentation: documentation,
      category: category,
    );
    await _ref
        .read(activityRepositoryProvider)
        .updateActivity(updatedActivity, photos: photos);
    await loadInitial();
  }

  Future<void> delete(String activityId) async {
    await _ref.read(activityRepositoryProvider).deleteActivity(activityId);
    await loadInitial();
  }

  Future<void> toggleLike(Activity activity) async {
    await _ref
        .read(activityRepositoryProvider)
        .setActivityLiked(activity.id, !activity.isLiked);
    await loadInitial();
    // Like hanya mengubah reaksi kegiatan. Meng-invalidasi seluruh provider
    // dashboard dari controller ini dapat membongkar widget yang masih aktif.
    await _ref.read(authControllerProvider.notifier).refreshProfile();
  }

  Future<void> verify({
    required String activityId,
    required ActivityStatus status,
    required String note,
  }) async {
    await _ref
        .read(activityRepositoryProvider)
        .verifyActivity(activityId: activityId, status: status, note: note);
    await refreshPointDependentState(_ref);
    await loadInitial();
  }
}

final activityControllerProvider =
    StateNotifierProvider<ActivityController, ActivityState>((ref) {
      return ActivityController(ref);
    });
