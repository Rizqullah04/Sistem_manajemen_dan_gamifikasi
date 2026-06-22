import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/leaderboard/presentation/pages/leaderboard_page.dart';

class DashboardLeaderboardPage extends ConsumerWidget {
  const DashboardLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final shouldUseDashboardShell = user?.role == UserRole.adminFaculty ||
        user?.role == UserRole.ormawaAccount;

    if (!shouldUseDashboardShell) {
      return const LeaderboardPage(showBottomNavigation: false);
    }

    return DashboardScaffold(
      title: 'Leaderboard',
      onLogout: () {
        ref.read(authControllerProvider.notifier).logout();
        context.go('/login');
      },
      body: const LeaderboardPage(
        showAppBar: false,
        showBottomNavigation: false,
      ),
    );
  }
}
