import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/pages/activity_list_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/login_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/register_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_ormawa_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_ormawa_awards_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/dashboard_leaderboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/member_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/ormawa_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/ormawa_members_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/achievement_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/chat_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/profile_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/settings_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/presentation/pages/student_gamification_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/presentation/pages/voting_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/ormawas',
        builder: (context, state) => const AdminOrmawaPage(),
      ),
      GoRoute(
        path: '/admin/ormawa-awards',
        builder: (context, state) => const AdminOrmawaAwardsPage(),
      ),
      GoRoute(
        path: '/admin/gamification/badges',
        builder: (context, state) => const AchievementPage(),
      ),
      GoRoute(
        path: '/ormawa',
        builder: (context, state) => const OrmawaDashboardPage(),
      ),
      GoRoute(
        path: '/ormawa/members',
        builder: (context, state) => const OrmawaMembersPage(),
      ),
      GoRoute(
        path: '/member',
        builder: (context, state) => const MemberDashboardPage(),
      ),
      GoRoute(
        path: '/activities',
        builder: (context, state) => const ActivityListPage(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const DashboardLeaderboardPage(),
      ),
      GoRoute(
        path: '/gamification/points-badges',
        builder: (context, state) => const StudentGamificationPage(),
      ),
      GoRoute(
        path: '/achievement',
        builder: (context, state) => const AchievementPage(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(path: '/voting', builder: (context, state) => const VotingPage()),
    ],
  );
});
