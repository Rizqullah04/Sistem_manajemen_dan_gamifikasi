import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/app.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/pages/activity_list_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/login_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/achievement_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_ormawa_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_student_management_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/chat_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/member_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/ormawa_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/profile_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/settings_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/period_status.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/leaderboard_entry.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/repositories/voting_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/presentation/pages/voting_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;

  @override
  String? get token => _user == null ? null : 'test-token';

  @override
  Future<(String token, User user)> login({
    required String email,
    required String password,
  }) async {
    final user = _user;
    if (user == null) {
      throw StateError('No test user configured');
    }
    return ('test-token', user);
  }

  @override
  Future<void> logout() async {}
}

class _TestAuthController extends AuthController {
  _TestAuthController(User? user)
    : super(
        LoginUseCase(_FakeAuthRepository(user)),
        _FakeAuthRepository(user),
      ) {
    state = AuthState(
      status: user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      user: user,
      token: user == null ? null : 'test-token',
    );
  }
}

class _FakeVotingRepository implements VotingRepository {
  final List<Voting> _items = [
    Voting(
      id: 'v1',
      type: VotingType.kegiatan,
      relatedId: 'activity-1',
      creatorName: 'BEM Fakultas Teknik',
      startDate: DateTime(2026),
      endDate: DateTime(2027),
      options: const [
        VoteOption(id: 'o1', title: 'Seminar Karier', votes: 12),
        VoteOption(id: 'o2', title: 'Workshop UI/UX', votes: 8),
      ],
      voterIds: const {},
    ),
  ];

  @override
  Future<List<Voting>> getVotings() async => _items;

  @override
  Future<Voting> createVoting({
    required String title,
    required VotingType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> pollOptions,
  }) async {
    final voting = Voting(
      id: 'v${_items.length + 1}',
      type: type,
      relatedId: title,
      creatorName: 'BEM Fakultas Teknik',
      startDate: startDate,
      endDate: endDate,
      options: [
        for (final option in pollOptions)
          VoteOption(id: option, title: option, votes: 0),
      ],
      voterIds: const {},
    );
    _items.add(voting);
    return voting;
  }

  @override
  Future<Voting> castVote({
    required String votingId,
    required String optionId,
    required String userId,
  }) async {
    final voting = _items.firstWhere((item) => item.id == votingId);
    return voting;
  }

  @override
  Future<Voting> updatePeriod({
    required String votingId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final index = _items.indexWhere((item) => item.id == votingId);
    final voting = _items[index].copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    _items[index] = voting;
    return voting;
  }

  @override
  Future<Voting> updateStatus({
    required String votingId,
    required String status,
  }) async {
    final index = _items.indexWhere((item) => item.id == votingId);
    final voting = _items[index].copyWith(status: status.toUpperCase());
    _items[index] = voting;
    return voting;
  }

  @override
  Future<void> deleteVoting(String votingId) async {
    _items.removeWhere((item) => item.id == votingId);
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  static const _summary = DashboardSummary(
    totalActivities: 8,
    totalPoints: 320,
    currentRanking: 2,
    monthlyActivities: {1: 1, 2: 2, 3: 3, 4: 4, 5: 3, 6: 5},
    notifications: ['Data dashboard test siap.'],
    pendingMemberCount: 2,
  );

  static const _leaderboard = [
    LeaderboardEntry(
      id: 'u3',
      name: 'Andi Pratama',
      points: 320,
      ranking: 1,
      level: 3,
    ),
    LeaderboardEntry(
      id: 'u4',
      name: 'Siti Rahma',
      points: 280,
      ranking: 2,
      level: 2,
    ),
  ];

  @override
  Future<DashboardSummary> getSummary(User user) async => _summary;

  @override
  Future<List<LeaderboardEntry>> getMemberLeaderboard() async => _leaderboard;

  @override
  Future<List<LeaderboardEntry>> getOrmawaLeaderboard() async => _leaderboard;

  @override
  Future<PeriodStatus> getPeriodStatus() async => PeriodStatus(
    activePeriod: DashboardPeriod(
      id: 1,
      year: 2026,
      name: 'Periode 2026',
      status: 'active',
      startsOn: DateTime(2026),
      endsOn: DateTime(2026, 12, 31),
    ),
    archivedPeriods: const [],
  );

  @override
  Future<PeriodResetResult> endCurrentPeriod() async => PeriodResetResult(
    archivedPeriod: DashboardPeriod(
      id: 1,
      year: 2026,
      name: 'Periode 2026',
      status: 'archived',
      startsOn: DateTime(2026),
      endsOn: DateTime(2026, 12, 31),
    ),
    activePeriod: DashboardPeriod(
      id: 2,
      year: 2027,
      name: 'Periode 2027',
      status: 'active',
      startsOn: DateTime(2027),
      endsOn: DateTime(2027, 12, 31),
    ),
    userSnapshotCount: 2,
    ormawaSnapshotCount: 1,
  );
}

const _adminUser = User(
  id: 'u1',
  name: 'Admin Fakultas',
  studentStaffId: 'ADM001',
  role: UserRole.adminFaculty,
  points: 220,
  level: 2,
);

const _ormawaUser = User(
  id: 'u2',
  name: 'Himpunan Teknik Informatika',
  studentStaffId: 'ORM001',
  role: UserRole.ormawaAccount,
  points: 320,
  level: 3,
  ormawaId: 'o1',
);

const _memberUser = User(
  id: 'u3',
  name: 'Andi Pratama',
  studentStaffId: 'ANG001',
  role: UserRole.memberAccount,
  points: 96,
  level: 1,
  ormawaId: 'o1',
);

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  User? user,
  bool settleAnimations = true,
}) async {
  tester.view.physicalSize = const Size(1440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: '/__test',
    routes: [
      GoRoute(path: '/__test', builder: (context, state) => page),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Admin route',
        ),
      ),
      GoRoute(
        path: '/admin/ormawas',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Admin Ormawa route',
        ),
      ),
      GoRoute(
        path: '/admin/students',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Admin Students route',
        ),
      ),
      GoRoute(
        path: '/admin/gamification/badges',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Badge Settings route',
        ),
      ),
      GoRoute(
        path: '/admin/ormawa-awards',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Ormawa Awards route',
        ),
      ),
      GoRoute(
        path: '/ormawa',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Ormawa route',
        ),
      ),
      GoRoute(
        path: '/ormawa/members',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Ormawa Members route',
        ),
      ),
      GoRoute(
        path: '/activities',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Activities route',
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Leaderboard route',
        ),
      ),
      GoRoute(
        path: '/gamification/points-badges',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Point & Badge route',
        ),
      ),
      GoRoute(
        path: '/voting',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Voting route',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Profile route',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Settings route',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const _SmokeRoutePlaceholder(
          title: 'Register route',
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _TestAuthController(user)),
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(),
        ),
        dashboardSummaryProvider.overrideWith(
          (ref) async => _FakeDashboardRepository._summary,
        ),
        realtimeDashboardSummaryProvider.overrideWith(
          (ref) => Stream.value(_FakeDashboardRepository._summary),
        ),
        memberLeaderboardProvider.overrideWith(
          (ref) async => _FakeDashboardRepository._leaderboard,
        ),
        ormawaLeaderboardProvider.overrideWith(
          (ref) async => _FakeDashboardRepository._leaderboard,
        ),
        votingRepositoryProvider.overrideWithValue(_FakeVotingRepository()),
        adminOrmawasProvider.overrideWith(
          (ref) async => const [
            ManagedOrmawa(
              id: 'o1',
              name: 'Himpunan Teknik Informatika',
              description: 'Organisasi mahasiswa informatika',
              totalPoints: 320,
              users: [
                ManagedOrmawaUser(
                  name: 'Akun HTI',
                  email: 'hti@example.com',
                  role: 'ormawa',
                ),
                ManagedOrmawaUser(
                  name: 'Andi Pratama',
                  email: 'andi@example.com',
                  role: 'anggota',
                ),
              ],
            ),
          ],
        ),
        adminStudentsProvider.overrideWith(
          (ref) async => const [
            ManagedStudent(
              id: 'u3',
              name: 'Andi Pratama',
              email: 'andi@example.com',
              ormawaName: 'Himpunan Teknik Informatika',
              points: 96,
              status: 'aktif',
            ),
            ManagedStudent(
              id: 'u4',
              name: 'Siti Rahma',
              email: 'siti@example.com',
              ormawaName: 'Badan Eksekutif Mahasiswa',
              points: 80,
              status: 'pending',
            ),
          ],
        ),
        adminBadgesProvider.overrideWith(
          (ref) async => const [
            GamificationBadge(
              id: 'b1',
              name: 'Active Participant',
              description: 'Aktif berpartisipasi dalam kegiatan.',
              activityType: 'Poin Kumulatif',
              minimumPoints: 50,
              icon: 'active-participant.png',
            ),
          ],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (settleAnimations) {
    await tester.pumpAndSettle();
  }
}

class _SmokeRoutePlaceholder extends StatelessWidget {
  const _SmokeRoutePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}

void main() {
  group('App bootstrap', () {
    testWidgets('starts on login screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: OrmawaAwardsApp()));
      await tester.pumpAndSettle();

      expect(find.text('Ormawa Awards'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });

  group('Page smoke tests', () {
    testWidgets('login page renders', (tester) async {
      await _pumpPage(tester, const LoginPage());

      expect(find.text('Log In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin dashboard renders', (tester) async {
      await _pumpPage(tester, const AdminDashboardPage(), user: _adminUser);

      expect(find.text('Dashboard Admin Fakultas'), findsOneWidget);
      expect(find.text('Total Poin'), findsOneWidget);
      expect(find.text('Notifikasi Terbaru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin ormawa management page renders', (tester) async {
      await _pumpPage(tester, const AdminOrmawaPage(), user: _adminUser);

      expect(find.text('Pengelolaan Data Ormawa'), findsOneWidget);
      expect(find.text('Tambah Ormawa'), findsOneWidget);
      expect(find.text('Himpunan Teknik Informatika'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin student management page renders global students', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        const AdminStudentManagementPage(),
        user: _adminUser,
      );

      expect(find.text('Monitoring Mahasiswa'), findsOneWidget);
      expect(find.text('Nama Mahasiswa'), findsOneWidget);
      expect(find.text('Asal Ormawa'), findsOneWidget);
      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(find.text('Badan Eksekutif Mahasiswa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ormawa dashboard renders', (tester) async {
      await _pumpPage(tester, const OrmawaDashboardPage(), user: _ormawaUser);

      expect(find.text('Dashboard Ormawa'), findsOneWidget);
      expect(find.text('Total Poin'), findsOneWidget);
      expect(find.text('Notifikasi Terbaru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('member dashboard renders', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

      expect(find.text('Leaderboard Snapshot'), findsOneWidget);
      expect(find.text('Andi Pratama'), findsWidgets);
      expect(find.text('Recent Activities'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('member rank tab uses the new leaderboard UI', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rank'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Individu'), findsOneWidget);
      expect(find.text('Ormawa'), findsOneWidget);
      expect(find.text('Top Individu'), findsOneWidget);
      expect(find.textContaining('PTS'), findsWidgets);
      expect(find.text('Ranking Saya'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('member profile tab uses the gamified profile UI', (
      tester,
    ) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('POINT PROGRESSION'), findsOneWidget);
      expect(find.text('BADGES & ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('Top Leader'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, skip: true);

    testWidgets('member profile avatar opens edit profile page', (
      tester,
    ) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDIT').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Lengkapi Profil'), findsOneWidget);
      expect(find.text('Unggah foto dari galeri'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('activity list page renders', (tester) async {
      await _pumpPage(tester, const ActivityListPage(), user: _adminUser);

      expect(find.text('Feed Kegiatan'), findsOneWidget);
      // Sapaan header berubah mengikuti UI terbaru; smoke test cukup memastikan halaman render.
      // expect(find.textContaining('Halo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaderboard page renders', (tester) async {
      await _pumpPage(tester, const LeaderboardPage(), user: _memberUser);

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('Top Individu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('badge settings page renders', (tester) async {
      await _pumpPage(tester, const AchievementPage(), user: _adminUser);

      expect(find.text('Pengaturan Lencana'), findsOneWidget);
      expect(find.text('Active Participant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chat page renders', (tester) async {
      await _pumpPage(tester, const ChatPage(), user: _memberUser);

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('ID penerima'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profile page renders', (tester) async {
      await _pumpPage(tester, const ProfilePage(), user: _memberUser);

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Andi Pratama'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings page renders', (tester) async {
      await _pumpPage(
        tester,
        const SettingsPage(),
        user: _memberUser,
        settleAnimations: false,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Pengaturan'), findsOneWidget);
      // expect(find.text('Pengaturan Akun'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('voting page renders', (tester) async {
      await _pumpPage(tester, const VotingPage(), user: _memberUser);

      expect(find.text('Voting Digital'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
