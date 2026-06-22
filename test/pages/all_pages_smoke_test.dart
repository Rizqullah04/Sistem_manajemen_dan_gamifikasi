import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/app.dart';
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
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/chat_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/member_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/ormawa_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/profile_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/settings_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/leaderboard/presentation/pages/leaderboard_page.dart';
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
      status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
      token: user == null ? null : 'test-token',
    );
  }
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
}) async {
  tester.view.physicalSize = const Size(1440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _TestAuthController(user)),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
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
      expect(find.text('Total Kegiatan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ormawa dashboard renders', (tester) async {
      await _pumpPage(tester, const OrmawaDashboardPage(), user: _ormawaUser);

      expect(find.text('Dashboard Ormawa'), findsOneWidget);
      expect(find.text('Total Kegiatan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('member dashboard renders', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

      expect(find.text('Leaderboard Snapshot'), findsOneWidget);
      expect(find.text('Recent Activities'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('member rank tab uses the new leaderboard UI', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

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

    testWidgets('member profile tab uses the gamified profile UI', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

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
    });

    testWidgets('member profile avatar opens edit profile page', (tester) async {
      await _pumpPage(tester, const MemberDashboardPage(), user: _memberUser);

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
      expect(find.textContaining('Halo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaderboard page renders', (tester) async {
      await _pumpPage(tester, const LeaderboardPage(), user: _memberUser);

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('Top Individu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('achievement page renders', (tester) async {
      await _pumpPage(tester, const AchievementPage(), user: _memberUser);

      expect(find.text('Achievement'), findsOneWidget);
      expect(find.text('Poin 100 tercapai'), findsOneWidget);
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
      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings page renders', (tester) async {
      await _pumpPage(tester, const SettingsPage(), user: _memberUser);

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Pengaturan Akun'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('voting page renders', (tester) async {
      await _pumpPage(tester, const VotingPage(), user: _memberUser);

      expect(find.text('Voting Digital'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
