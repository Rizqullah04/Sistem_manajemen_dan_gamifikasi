import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/pages/activity_list_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/login_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/pages/register_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_data_management_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_ormawa_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_ormawa_awards_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/admin_student_management_page.dart';
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
    redirect: (context, state) {
      final path = state.uri.path;
      final user = ref.read(authControllerProvider).user;
      final isPublicRoute =
          path == '/login' ||
          path == '/register' ||
          path.startsWith('/forgot-password');

      if (user == null) return isPublicRoute ? null : '/login';
      if (isPublicRoute) return _homePathForRole(user.role);

      if (path.startsWith('/admin') && user.role != UserRole.adminFaculty) {
        return _homePathForRole(user.role);
      }
      if (path.startsWith('/ormawa') && user.role != UserRole.ormawaAccount) {
        return _homePathForRole(user.role);
      }
      if (path == '/member' && user.role != UserRole.memberAccount) {
        return _homePathForRole(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map) return const ForgotPasswordPage();

          final email = extra['email']?.toString() ?? '';
          if (email.isEmpty) return const ForgotPasswordPage();

          return VerifyOtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password/reset',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map) return const ForgotPasswordPage();

          final email = extra['email']?.toString() ?? '';
          final otp = extra['otp']?.toString() ?? '';
          if (email.isEmpty || otp.isEmpty) return const ForgotPasswordPage();

          return ResetPasswordPage(email: email, otp: otp);
        },
      ),
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
        path: '/admin/students',
        builder: (context, state) => const AdminStudentManagementPage(),
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
        path: '/admin/data-management',
        builder: (context, state) => const AdminDataManagementPage(),
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

String _homePathForRole(UserRole role) {
  return switch (role) {
    UserRole.adminFaculty => '/admin',
    UserRole.ormawaAccount => '/ormawa',
    UserRole.memberAccount => '/member',
  };
}
