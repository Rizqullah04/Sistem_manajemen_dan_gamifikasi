import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';

class DashboardHomeAction extends ConsumerWidget {
  const DashboardHomeAction({
    this.hideWhenCurrent = true,
    super.key,
  });

  final bool hideWhenCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final route = dashboardHomeRoute(user?.role);
    if (route == null) return const SizedBox.shrink();

    final currentPath = GoRouterState.of(context).uri.path;
    if (hideWhenCurrent && currentPath == route) return const SizedBox.shrink();

    return IconButton(
      onPressed: () => context.go(route),
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Kembali ke Dashboard',
    );
  }
}

String? dashboardHomeRoute(UserRole? role) {
  switch (role) {
    case UserRole.adminFaculty:
      return '/admin';
    case UserRole.ormawaAccount:
      return '/ormawa';
    case UserRole.memberAccount:
      return '/member';
    case null:
      return null;
  }
}
