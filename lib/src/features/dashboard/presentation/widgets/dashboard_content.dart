import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/settings_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/admin_monitoring_card.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/monthly_activity_chart.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/period_reset_card.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/stat_card.dart';

class DashboardContent extends ConsumerWidget {
  const DashboardContent({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(realtimeDashboardSummaryProvider);
    final settings = ref.watch(dashboardSettingsProvider).valueOrNull;
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Gagal memuat dashboard',
        subtitle: error.toString(),
        icon: Icons.error_outline_rounded,
      ),
      data: (summary) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = DashboardResponsive.getContentPadding(width);
            final spacing = DashboardResponsive.getSpacing(width);

            return ListView(
              padding: padding,
              children: [
                // Stat Cards Section
                _buildStatCardsSection(context, width, spacing, summary),
                SizedBox(height: spacing),

                // Monthly Activity Chart
                MonthlyActivityChart(data: summary.monthlyActivities),
                SizedBox(height: spacing),

                // Recent Notifications
                _buildNotificationsCard(
                  context,
                  spacing,
                  summary,
                  notificationsEnabled:
                      settings?.notificationsEnabled ?? true,
                ),
                SizedBox(height: spacing),

                // Admin Monitoring (only for Admin Fakultas)
                if (role == UserRole.adminFaculty) ...[
                  const PeriodResetCard(),
                  SizedBox(height: spacing),
                  const AdminMonitoringCard(),
                  SizedBox(height: spacing),
                ],

                // Bottom spacing
                SizedBox(height: spacing),
              ],
            );
          },
        );
      },
    );
  }

  /// Build responsive stat cards section
  Widget _buildStatCardsSection(
    BuildContext context,
    double width,
    double spacing,
    dynamic summary,
  ) {
    final isMobile = width < DashboardResponsive.tabletMinWidth;
    final isTablet = width >= DashboardResponsive.tabletMinWidth &&
        width < DashboardResponsive.desktopMinWidth;

    if (isMobile) {
      // Single column for mobile
      return Column(
        children: [
          StatCard(
            title: 'Total Kegiatan',
            value: '${summary.totalActivities}',
            icon: Icons.event_note_outlined,
          ),
          SizedBox(height: spacing),
          StatCard(
            title: 'Total Poin',
            value: '${summary.totalPoints}',
            icon: Icons.stars_rounded,
          ),
          SizedBox(height: spacing),
          StatCard(
            title: 'Ranking Saat Ini',
            value: summary.currentRanking > 0 ? '#${summary.currentRanking}' : '-',
            icon: Icons.emoji_events_outlined,
          ),
        ],
      );
    } else if (isTablet) {
      // Two columns for tablet
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Kegiatan',
                  value: '${summary.totalActivities}',
                  icon: Icons.event_note_outlined,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: StatCard(
                  title: 'Total Poin',
                  value: '${summary.totalPoints}',
                  icon: Icons.stars_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          StatCard(
            title: 'Ranking Saat Ini',
            value: summary.currentRanking > 0 ? '#${summary.currentRanking}' : '-',
            icon: Icons.emoji_events_outlined,
          ),
        ],
      );
    } else {
      // Three columns for desktop
      return Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total Kegiatan',
              value: '${summary.totalActivities}',
              icon: Icons.event_note_outlined,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: 'Total Poin',
              value: '${summary.totalPoints}',
              icon: Icons.stars_rounded,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: 'Ranking Saat Ini',
              value: summary.currentRanking > 0 ? '#${summary.currentRanking}' : '-',
              icon: Icons.emoji_events_outlined,
            ),
          ),
        ],
      );
    }
  }

  /// Build notifications card with proper scrolling
  Widget _buildNotificationsCard(BuildContext context, double spacing,
      dynamic summary, {required bool notificationsEnabled}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi Terbaru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (role == UserRole.ormawaAccount &&
                summary.pendingMemberCount > 0) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => context.push('/ormawa/members'),
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: Text(
                  'Review ${summary.pendingMemberCount} pendaftar anggota',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!notificationsEnabled)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Notifikasi sedang dinonaktifkan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              )
            else if (summary.notifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada notifikasi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              )
            else
              // Use ConstrainedBox to limit notification list height
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: summary.notifications.map<Widget>(
                      (n) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            leading: Icon(
                              Icons.notifications_active_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              n,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
