import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/activity_card.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/badge_widget.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/dashboard_header.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/leaderboard_card.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/leaderboard_preview.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/point_card.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/providers/activity_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/settings_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/pages/edit_profile_page.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/discussion/presentation/widgets/discussion_section.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/leaderboard/presentation/pages/leaderboard_page.dart';

class MemberDashboardPage extends ConsumerStatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  ConsumerState<MemberDashboardPage> createState() =>
      _MemberDashboardPageState();
}

class _MemberDashboardPageState extends ConsumerState<MemberDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _badges = [
    'Early Bird',
    'On Fire',
    'Team Player',
    'Night Owl',
  ];
  final Set<String> _readNotificationKeys = <String>{};
  MemberProfileData? _profileData;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(activityControllerProvider.notifier).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0819),
      endDrawer: user == null ? null : _buildSidebar(context, user),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Silakan login untuk melihat dashboard'))
            : _buildPage(context, user),
      ),
      floatingActionButton: user == null
          ? null
          : Builder(
              builder: (buttonContext) {
                return FloatingActionButton(
                  onPressed: () => Scaffold.of(buttonContext).openEndDrawer(),
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.menu_rounded),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPage(BuildContext context, User user) {
    _profileData ??= _createInitialProfileData(user);
    switch (_selectedIndex) {
      case 1:
        return _buildDashboardSubPage(
          context,
          title: 'Rank',
          child: const LeaderboardPage(
            showAppBar: false,
            showBottomNavigation: false,
          ),
        );
      case 2:
        return _buildDashboardSubPage(
          context,
          title: 'Activity',
          child: _buildActivity(context),
        );
      case 3:
        return _buildDashboardSubPage(
          context,
          title: 'Profile',
          child: _buildProfile(context, user),
        );
      case 0:
      default:
        return _buildHome(context, user);
    }
  }

  Widget _buildDashboardSubPage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return ColoredBox(
      color: const Color(0xFF0B0819),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 20, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Kembali ke Home',
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context, User user) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final realtimeSummaryAsync = ref.watch(realtimeDashboardSummaryProvider);
    final settings = ref.watch(dashboardSettingsProvider).valueOrNull;
    final leaderboardAsync = ref.watch(memberLeaderboardProvider);
    final activities = ref.watch(activityControllerProvider);
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (summary) {
        final notifications =
            realtimeSummaryAsync.valueOrNull?.notifications ??
            summary.notifications;
        final unreadNotificationCount = _unreadNotificationCount(
          notifications,
        );
        final isCompactDashboard =
            settings?.compactDashboardEnabled ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                userName: user.name,
                notificationCount: settings?.notificationsEnabled == false
                    ? 0
                    : unreadNotificationCount,
                onNotificationTap: () {
                  if (settings?.notificationsEnabled == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi sedang dinonaktifkan.'),
                      ),
                    );
                    return;
                  }
                  _markNotificationsAsRead(notifications);
                  ref.invalidate(realtimeDashboardSummaryProvider);
                  _showNotifications(context, summary);
                },
              ),
              const SizedBox(height: 24),
              PointCard(
                points: summary.totalPoints,
                rankLabel: _rankLabel(summary.totalPoints),
                progress: _progress(summary.totalPoints),
                remainingText: _remainingText(summary.totalPoints),
              ),
              const SizedBox(height: 24),
              leaderboardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (entries) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard Snapshot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LeaderboardPreview(
                      entries: entries,
                      currentUserId: user.id,
                    ),
                    if (!isCompactDashboard) ...[
                      const SizedBox(height: 18),
                      LeaderboardCard(entries: entries, currentUserId: user.id),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: activities.items.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada kegiatan terbaru',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activities.items.length,
                        itemBuilder: (context, index) {
                          final item = activities.items[index];
                          return ActivityCard(
                            title: item.title,
                            organizer: item.ormawaId,
                            date: DateFormat('dd MMM').format(item.date),
                            status: item.status.label,
                            points: item.pointsGenerated,
                          );
                        },
                      ),
              ),
              if (!isCompactDashboard) ...[
                const SizedBox(height: 24),
                Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _displayBadges(user)
                      .map((badge) => BadgeWidget(label: badge))
                      .toList(),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  int _unreadNotificationCount(List<String> notifications) {
    return notifications
        .where((notification) => !_readNotificationKeys.contains(notification))
        .length;
  }

  void _markNotificationsAsRead(List<String> notifications) {
    if (notifications.isEmpty) return;
    setState(() => _readNotificationKeys.addAll(notifications));
  }

  Future<void> _showNotifications(
    BuildContext context,
    DashboardSummary fallbackSummary,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF120E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final realtimeSummaryAsync = ref.watch(
              realtimeDashboardSummaryProvider,
            );
            final summary = realtimeSummaryAsync.valueOrNull ?? fallbackSummary;
            final notifications = summary.notifications;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notifikasi Terbaru',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (realtimeSummaryAsync.isLoading)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Tidak ada notifikasi baru.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF6D28D9),
                                foregroundColor: Colors.white,
                                child: Icon(Icons.notifications_none_rounded),
                              ),
                              title: Text(
                                notifications[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivity(BuildContext context) {
    final activities = ref.watch(activityControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: activities.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.items.isEmpty
          ? const Center(child: Text('Tidak ada kegiatan yang tersedia.'))
          : ListView.separated(
              itemCount: activities.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = activities.items[index];
                return _buildActivityCard(context, item);
              },
            ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity item) {
    return Material(
      color: const Color(0xFF17122D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showActivityDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(item.date),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const Spacer(),
                  Text(
                    '+${item.pointsGenerated} pts',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 15, color: Colors.white38),
                  SizedBox(width: 6),
                  Text(
                    'Ketuk untuk detail dan diskusi',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ActivityStatus status) {
    final color = status == ActivityStatus.approved
        ? Colors.greenAccent
        : status == ActivityStatus.pending
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(status.label, style: TextStyle(color: color)),
    );
  }

  Future<void> _showActivityDetail(BuildContext context, Activity item) async {
    final documentation = item.documentation.trim();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF120E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBadge(item.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.calendar_month,
                        label: DateFormat('dd MMM yyyy').format(item.date),
                      ),
                      _buildInfoChip(
                        icon: Icons.category_outlined,
                        label: item.category,
                      ),
                      _buildInfoChip(
                        icon: Icons.star_rate_rounded,
                        label: '${item.pointsGenerated} poin',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Deskripsi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Dokumentasi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17122D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: documentation.isEmpty
                        ? const Text(
                            'Dokumentasi belum tersedia.',
                            style: TextStyle(color: Colors.white54),
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.link_rounded,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  documentation,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Salin dokumentasi',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: documentation),
                                  );
                                  if (!sheetContext.mounted) return;
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Link dokumentasi disalin.',
                                          ),
                                        ),
                                      );
                                },
                                icon: const Icon(Icons.copy_rounded),
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                  if (item.verificationNote != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Catatan Verifikasi: ${item.verificationNote!}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Diskusi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context)
                          .textTheme
                          .apply(
                            bodyColor: Colors.white,
                            displayColor: Colors.white,
                          ),
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: true,
                        fillColor: Color(0xFF17122D),
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                      ),
                    ),
                    child: DiscussionSection(activityId: item.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1738),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    final profile = _profileData ?? _createInitialProfileData(user);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final activities = ref.watch(activityControllerProvider);
    final totalPoints = summaryAsync.valueOrNull?.totalPoints ?? user.points;
    final globalRank = summaryAsync.valueOrNull?.currentRanking ?? 12;
    final activityCount =
        summaryAsync.valueOrNull?.totalActivities ?? activities.items.length;
    const profileBackground = Color(0xFF0B0819);

    return ColoredBox(
      color: profileBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;
          final horizontalPadding = isCompact ? 18.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedSection(
                  delay: 0,
                  child: _buildProfileHeaderCard(context, user, profile),
                ),
                const SizedBox(height: 22),
                _buildAnimatedSection(
                  delay: 1,
                  child: _buildStatsSection(
                    context,
                    totalPoints: totalPoints,
                    globalRank: globalRank,
                    activityCount: activityCount,
                    isCompact: isCompact,
                  ),
                ),
                const SizedBox(height: 26),
                _buildAnimatedSection(
                  delay: 2,
                  child: _buildPointProgressionSection(context),
                ),
                const SizedBox(height: 28),
                _buildAnimatedSection(
                  delay: 3,
                  child: _buildBadgesSection(
                    context,
                    user: user,
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, User user) {
    final items = const [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.emoji_events_outlined, label: 'Rank'),
      (icon: Icons.event_note_outlined, label: 'Activity'),
      (icon: Icons.person_rounded, label: 'Profile'),
      (icon: Icons.settings_outlined, label: 'Pengaturan'),
    ];

    return Drawer(
      backgroundColor: const Color(0xFF120E24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(
                      0xFF6D28D9,
                    ).withValues(alpha: 0.18),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role.label,
                          style: const TextStyle(
                            color: Color(0xFF9AA3B2),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Navigasi',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                items.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSidebarItem(
                    context,
                    icon: items[index].icon,
                    label: items[index].label,
                    isActive: _selectedIndex == index,
                    onTap: () {
                      Navigator.pop(context);
                      if (index == 4) {
                        context.push('/settings');
                        return;
                      }
                      setState(() => _selectedIndex = index);
                    },
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _logout(context);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive
          ? const Color(0xFF6D28D9).withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF9AA3B2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF9AA3B2),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8B5CF6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    BuildContext context,
    User user,
    MemberProfileData profile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16122D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16122D),
            const Color(0xFF1D1738).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  color: const Color(0xFF8B5CF6),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Student Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildProfileAvatar(context, profile),
          const SizedBox(height: 20),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.role.label,
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${profile.nim}',
            style: const TextStyle(
              color: Color(0xFF8A8F9F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>('/logout');
      ref.read(dioProvider).options.headers.remove('Authorization');
      await ref.read(authControllerProvider.notifier).logout();

      if (!context.mounted) return;
      context.go('/login');
    } on DioException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Logout gagal. Periksa koneksi API.')),
      );
    }
  }

  Widget _buildProfileAvatar(BuildContext context, MemberProfileData profile) {
    final initials = profile.fullName.trim().isEmpty
        ? 'U'
        : profile.fullName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return InkWell(
      borderRadius: BorderRadius.circular(64),
      onTap: () => _openEditProfile(context),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFF241B45),
              backgroundImage: _buildProfileImage(profile.profileImagePath),
              child: profile.profileImagePath == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              height: 30,
              width: 108,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(50),
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 6),
                  Text(
                    'EDIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF16122D), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required int totalPoints,
    required int globalRank,
    required int activityCount,
    required bool isCompact,
  }) {
    final stats = [
      ('Total Points', _formatNumber(totalPoints)),
      ('Global Rank', '#$globalRank'),
      ('Activities', '$activityCount'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        isCompact
            ? Column(
                children: stats
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildStatCard(item.$1, item.$2),
                      ),
                    )
                    .toList(),
              )
            : Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(child: _buildStatCard(stats[i].$1, stats[i].$2)),
                    if (i < stats.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF120E24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9AA3B2),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointProgressionSection(BuildContext context) {
    const values = [28, 54, 36, 82, 74, 92, 118];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'POINT PROGRESSION',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8187A2),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Text(
              '+15% this month',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF120E24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == values.length - 1 ? 0 : 10,
                    ),
                    child: _buildProgressBar(
                      value: values[index].toDouble(),
                      maxValue: 120,
                      durationMs: 450 + (index * 80),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required double value,
    required double maxValue,
    required int durationMs,
  }) {
    final heightFactor = (value / maxValue).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: heightFactor),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeOut,
            height: 24 + (128 * animatedValue),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _displayBadges(User user) {
    return user.badges.isEmpty ? _badges : user.badges;
  }

  Widget _buildBadgesSection(
    BuildContext context, {
    required User user,
    required bool isCompact,
  }) {
    final colors = const [
      Color(0xFFEAB308),
      Color(0xFF3B82F6),
      Color(0xFFA855F7),
      Color(0xFF14B8A6),
      Color(0xFFEF4444),
      Color(0xFF22C55E),
    ];
    final icons = const [
      Icons.emoji_events_rounded,
      Icons.groups_rounded,
      Icons.bolt_rounded,
      Icons.verified_rounded,
      Icons.workspace_premium_rounded,
      Icons.military_tech_rounded,
    ];
    final badges = _displayBadges(user).asMap().entries.map((entry) {
      final index = entry.key;
      return _ProfileBadgeData(
        label: entry.value,
        icon: icons[index % icons.length],
        color: colors[index % colors.length],
      );
    }).toList();

    final crossAxisCount = isCompact ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'BADGES & ACHIEVEMENTS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8187A2),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Text(
              'View All',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6D28D9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            mainAxisExtent: 150,
          ),
          itemBuilder: (context, index) => _buildBadgeItem(badges[index]),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(_ProfileBadgeData badge) {
    final opacity = badge.isLocked ? 0.3 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.color.withValues(alpha: 0.16),
              border: Border.all(color: badge.color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(
                    alpha: badge.isLocked ? 0.10 : 0.28,
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(badge.icon, color: badge.color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (delay * 120)),
      curve: Curves.easeOut,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _rankLabel(int points) {
    if (points <= 100) return 'BRONZE MEMBER';
    if (points <= 300) return 'SILVER MEMBER';
    if (points <= 700) return 'GOLD MEMBER';
    return 'PLATINUM MEMBER';
  }

  double _progress(int points) {
    if (points <= 100) return points / 100;
    if (points <= 300) return (points - 100) / 200;
    if (points <= 700) return (points - 300) / 400;
    return 1.0;
  }

  String _remainingText(int points) {
    if (points <= 100) return '${100 - points} pts remaining until Silver Rank';
    if (points <= 300) return '${300 - points} pts remaining until Gold Rank';
    if (points <= 700)
      return '${700 - points} pts remaining until Platinum Rank';
    return 'You have reached Platinum Rank';
  }

  MemberProfileData _createInitialProfileData(User user) {
    return MemberProfileData(
      fullName: user.name,
      nim: user.studentStaffId,
      email: '${user.studentStaffId.toLowerCase()}@student.univ.ac.id',
      phoneNumber: '0812-3456-7890',
      faculty: 'Fakultas Teknik',
      studyProgram: 'Teknik Informatika',
      batchYear: '2022',
      ormawa: 'BEM',
      birthDate: DateTime(2003, 4, 17),
    );
  }

  ImageProvider<Object>? _buildProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    return FileImage(File(path));
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final currentProfile = _profileData;
    if (currentProfile == null) return;

    final updatedProfile = await Navigator.of(context).push<MemberProfileData>(
      PageRouteBuilder<MemberProfileData>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return EditProfilePage(initialData: currentProfile);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );

    if (!mounted || updatedProfile == null) return;

    setState(() => _profileData = updatedProfile);
    ref
        .read(authControllerProvider.notifier)
        .updateProfile(name: updatedProfile.fullName);
  }
}

class _ProfileBadgeData {
  const _ProfileBadgeData({
    required this.label,
    required this.icon,
    required this.color,
    this.isLocked = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isLocked;
}
