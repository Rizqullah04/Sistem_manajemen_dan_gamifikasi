import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/router/app_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/theme/app_theme.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/settings_providers.dart';

class OrmawaAwardsApp extends ConsumerWidget {
  const OrmawaAwardsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(dashboardSettingsProvider).valueOrNull;
    return MaterialApp.router(
      title: 'Ormawa Awards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: (settings?.darkModeEnabled ?? true)
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: router,
    );
  }
}
