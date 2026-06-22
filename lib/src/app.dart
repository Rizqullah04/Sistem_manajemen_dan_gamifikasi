import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/router/app_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/theme/app_theme.dart';

class OrmawaAwardsApp extends ConsumerWidget {
  const OrmawaAwardsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ormawa Awards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
