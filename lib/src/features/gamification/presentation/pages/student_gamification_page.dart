import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/domain/entities/student_gamification_model.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/gamification/presentation/providers/student_gamification_controller.dart';

class StudentGamificationPage extends ConsumerWidget {
  const StudentGamificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentGamificationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Badge & Pencapaian',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const DashboardHomeAction(),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref
                .read(studentGamificationControllerProvider.notifier)
                .reload(),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _GamificationColors.gold),
        ),
        error: (error, _) => _GamificationErrorView(
          message: error.toString(),
          onRetry: () => ref
              .read(studentGamificationControllerProvider.notifier)
              .reload(),
        ),
        data: (data) => RefreshIndicator(
          color: _GamificationColors.gold,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () => ref
              .read(studentGamificationControllerProvider.notifier)
              .reload(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfilePointCard(data: data),
                const SizedBox(height: 16),
                _StatsGrid(data: data),
                const SizedBox(height: 18),
                if (data.collectionBadges.isEmpty) ...[
                  const SizedBox(height: 18),
                  const _EmptyBadgeCatalog(),
                ] else ...[
                  const _SectionHeader(title: 'FEATURED BADGE'),
                  const SizedBox(height: 8),
                  _FeaturedBadgeCard(data: data),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'KOLEKSI BADGE',
                    action: 'Lihat Semua',
                  ),
                  const SizedBox(height: 10),
                  _BadgeCollectionGrid(data: data),
                  const SizedBox(height: 18),
                ],
                const _MotivationBanner(),
                const SizedBox(height: 22),
                const _SectionHeader(title: 'AKTIVITAS TERBARU'),
                const SizedBox(height: 12),
                _ActivityTimeline(logs: data.pointLogs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePointCard extends StatelessWidget {
  const _ProfilePointCard({required this.data});

  final StudentGamificationModel data;

  @override
  Widget build(BuildContext context) {
    final progress = _levelProgress(data.totalPoints);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GamificationColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _GamificationColors.violet.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(name: data.studentName, level: data.level),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.isOrmawa
                          ? 'Ormawa Achievement'
                          : 'Student Achievement',
                      style: const TextStyle(
                        color: _GamificationColors.muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 18,
                          color: _GamificationColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            data.tierLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _GamificationColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatNumber(data.totalPoints),
                    style: const TextStyle(
                      color: Color(0xFFD9C4FF),
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'POINTS',
                    style: TextStyle(
                      color: _GamificationColors.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'NEXT LEVEL: ${data.nextLevelLabel}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD9C4FF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.level});

  final String name;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _GamificationColors.gold, width: 2),
            gradient: const LinearGradient(
              colors: [Color(0xFF291D4D), Color(0xFF08050F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _GamificationColors.gold,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _GamificationColors.gold.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'LVL $level',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final StudentGamificationModel data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(Icons.emoji_events_outlined, '${data.badges.length}', 'BADGES'),
      _StatData(Icons.leaderboard_outlined, '#${data.rankEstimate}', 'RANK'),
      _StatData(
        Icons.star_border_rounded,
        _formatNumber(data.totalPoints),
        'PTS',
      ),
      _StatData(Icons.chat_bubble_outline_rounded, '${data.talkCount}', 'TALK'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 98,
      ),
      itemBuilder: (context, index) => _StatCard(
        data: stats[index],
        highlighted: index == 1,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data, required this.highlighted});

  final _StatData data;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: _GamificationColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? _GamificationColors.gold
              : Colors.white.withValues(alpha: 0.08),
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _GamificationColors.gold.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data.icon,
            color: highlighted
                ? _GamificationColors.gold
                : const Color(0xFFD9C4FF),
            size: 20,
          ),
          const SizedBox(height: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _GamificationColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBadgeCard extends StatelessWidget {
  const _FeaturedBadgeCard({required this.data});

  final StudentGamificationModel data;

  @override
  Widget build(BuildContext context) {
    final badge = data.featuredBadge;
    if (badge == null) return const SizedBox.shrink();

    final isUnlocked = badge.isUnlocked;
    final title = badge.name;
    final description = badge.description.isEmpty
        ? 'Aktif berkontribusi dalam aktivitas Ormawa Awards.'
        : badge.description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _GamificationColors.gold.withValues(alpha: 0.75),
        ),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            _GamificationColors.gold.withValues(alpha: 0.16),
            _GamificationColors.card,
            _GamificationColors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _GamificationColors.gold.withValues(alpha: 0.18),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        children: [
          _StudentBadgeIcon(
            imageUrl: badge.icon,
            size: 74,
            color: _GamificationColors.gold,
            fallbackIcon: isUnlocked
                ? Icons.shield_rounded
                : Icons.shield_outlined,
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _GamificationColors.gold,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _GamificationColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _GamificationColors.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              isUnlocked
                  ? 'UNLOCKED ${_formatBadgeDate(badge.awardedAt)}'
                  : 'LOCKED - BUT READY TO UNLOCK',
              style: const TextStyle(
                color: _GamificationColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCollectionGrid extends StatelessWidget {
  const _BadgeCollectionGrid({required this.data});

  final StudentGamificationModel data;

  @override
  Widget build(BuildContext context) {
    final badges = data.collectionBadges;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 140,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _CollectionBadgeTile(
          badge: badge,
          isUnlocked: badge.isUnlocked,
          progress: data.badgeProgress(badge),
        );
      },
    );
  }
}

class _CollectionBadgeTile extends StatelessWidget {
  const _CollectionBadgeTile({
    required this.badge,
    required this.isUnlocked,
    required this.progress,
  });

  final StudentBadgeModel badge;
  final bool isUnlocked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final accent = isUnlocked
        ? _GamificationColors.gold
        : const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? _GamificationColors.card
            : const Color(0xFF111018).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: ClipOval(
                    child: _StudentBadgeIcon(
                      imageUrl: badge.icon,
                      size: 48,
                      color: accent,
                      fallbackIcon: isUnlocked
                          ? Icons.emoji_events_outlined
                          : Icons.military_tech_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  badge.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUnlocked
                      ? _tierFromPoints(badge.minimumPoints).toUpperCase()
                      : progress <= 0
                          ? 'LOCKED'
                          : '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    color: isUnlocked
                        ? _GamificationColors.gold
                        : _GamificationColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (!isUnlocked)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.42),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white70,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentBadgeIcon extends StatelessWidget {
  const _StudentBadgeIcon({
    required this.imageUrl,
    required this.size,
    required this.color,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final double size;
  final Color color;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(fallbackIcon, color: color, size: size * 0.65);
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return fallback;

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF221049),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 22,
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: _GamificationColors.gold,
            child: Icon(Icons.emoji_events_rounded, color: Colors.black),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Terus tingkatkan partisipasi untuk membuka badge dan pencapaian baru.',
              style: TextStyle(
                color: Color(0xFFD9C4FF),
                height: 1.45,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBadgeCatalog extends StatelessWidget {
  const _EmptyBadgeCatalog();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 32),
      decoration: BoxDecoration(
        color: _GamificationColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            _GamificationColors.gold.withValues(alpha: 0.08),
            _GamificationColors.card,
            _GamificationColors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: _GamificationColors.gold.withValues(alpha: 0.42),
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum ada lencana yang tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selesaikan aktivitas atau tunggu Admin merilis lencana baru!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _GamificationColors.muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.logs});

  final List<StudentPointLogModel> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Belum ada riwayat poin.',
          style: TextStyle(color: _GamificationColors.muted),
        ),
      );
    }
    final timeline = logs.take(5).toList();
    return Column(
      children: [
        for (var index = 0; index < timeline.length; index++)
          _TimelineItem(
            log: timeline[index],
            isFirst: index == 0,
            isLast: index == timeline.length - 1,
          ),
      ],
    );
  }

}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.log,
    required this.isFirst,
    required this.isLast,
  });

  final StudentPointLogModel log;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dateText = isFirst
        ? 'TODAY'
        : log.date == null
            ? log.source.toUpperCase()
            : DateFormat('dd MMM yyyy').format(log.date!).toUpperCase();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst
                        ? _GamificationColors.gold
                        : const Color(0xFFD9C4FF),
                    boxShadow: [
                      if (isFirst)
                        BoxShadow(
                          color: _GamificationColors.gold.withValues(
                            alpha: 0.6,
                          ),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      color: isFirst
                          ? _GamificationColors.gold
                          : _GamificationColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    log.points > 0 ? '+${log.points} Point' : log.source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.description.isEmpty
                        ? 'Aktivitas gamifikasi berhasil dicatat.'
                        : log.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _GamificationColors.muted,
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
      ],
    );
  }
}

class _GamificationErrorView extends StatelessWidget {
  const _GamificationErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: _GamificationColors.gold,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationColors {
  const _GamificationColors._();

  static const background = Color(0xFF080213);
  static const surface = Color(0xFF11091F);
  static const card = Color(0xFF151020);
  static const violet = Color(0xFF7C3AED);
  static const gold = Color(0xFFFFD400);
  static const muted = Color(0xFF8D86A4);
}

class _StatData {
  const _StatData(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

extension _StudentGamificationUi on StudentGamificationModel {
  int get level => (totalPoints ~/ 100) + 1;

  int get rankEstimate {
    if (totalPoints <= 0) return 99;
    return (1000 / totalPoints).ceil().clamp(1, 99).toInt();
  }

  int get talkCount {
    return pointLogs
        .where((log) => log.source.toLowerCase().contains('diskusi'))
        .length;
  }

  String get tierLabel {
    if (totalPoints >= 700) return 'Tier 4 - Master';
    if (totalPoints >= 300) return 'Tier 3 - Elite';
    if (totalPoints >= 100) return 'Tier 2 - Gold';
    return 'Tier 1 - Rookie';
  }

  String get nextLevelLabel {
    if (totalPoints >= 700) return 'LEGEND';
    if (totalPoints >= 300) return 'MASTER';
    if (totalPoints >= 100) return 'ELITE';
    return 'GOLD';
  }

  StudentBadgeModel? get featuredBadge {
    final unlockedBadges = collectionBadges.where((badge) => badge.isUnlocked);
    if (unlockedBadges.isNotEmpty) return unlockedBadges.first;
    if (collectionBadges.isNotEmpty) return collectionBadges.first;
    return null;
  }

  List<StudentBadgeModel> get collectionBadges {
    return availableBadges;
  }

  double badgeProgress(StudentBadgeModel badge) {
    if (badge.minimumPoints <= 0) return 1;
    return (totalPoints / badge.minimumPoints).clamp(0.0, 1.0).toDouble();
  }
}

double _levelProgress(int points) {
  if (points <= 0) return 0;
  final currentLevelStart = (points ~/ 100) * 100;
  return ((points - currentLevelStart) / 100).clamp(0.0, 1.0).toDouble();
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

String _formatBadgeDate(DateTime? date) {
  if (date == null) return 'SOON';
  return DateFormat('dd MMM yyyy').format(date).toUpperCase();
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return 'S';
  return words
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
}

String _tierFromPoints(int points) {
  if (points >= 700) return 'Platinum';
  if (points >= 300) return 'Gold';
  if (points >= 100) return 'Silver';
  return 'Bronze';
}
