import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class VotingModel {
  const VotingModel({
    required this.tipeVoting,
    required this.title,
    required this.endTime,
    required this.totalParticipants,
    this.status = 'AKTIF',
    this.candidates = const [],
    this.activities = const [],
  });

  final String tipeVoting;
  final String title;
  final DateTime endTime;
  final int totalParticipants;
  final String status;
  final List<CandidateVotingOption> candidates;
  final List<ActivityVotingOption> activities;

  bool get isKetua => tipeVoting.toUpperCase() == 'KETUA';

}

class CandidateVotingOption {
  const CandidateVotingOption({
    required this.name,
    required this.slogan,
    required this.voteCount,
    this.photoUrl,
  });

  final String name;
  final String slogan;
  final int voteCount;
  final String? photoUrl;
}

class ActivityVotingOption {
  const ActivityVotingOption({
    required this.name,
    required this.description,
    required this.estimatedDate,
    required this.voteCount,
    this.icon = Icons.event_available_rounded,
  });

  final String name;
  final String description;
  final DateTime estimatedDate;
  final int voteCount;
  final IconData icon;
}

class LiveVotingPreviewPage extends StatefulWidget {
  const LiveVotingPreviewPage({
    required this.data,
    this.onCandidateVote,
    this.onActivityVote,
    super.key,
  });

  final VotingModel data;
  final ValueChanged<CandidateVotingOption>? onCandidateVote;
  final ValueChanged<ActivityVotingOption>? onActivityVote;

  @override
  State<LiveVotingPreviewPage> createState() => _LiveVotingPreviewPageState();
}

class _LiveVotingPreviewPageState extends State<LiveVotingPreviewPage> {
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingTime = _calculateRemainingTime());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Live Voting Preview'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _VotingHeaderCard(data: data, remainingTime: _remainingTime),
            const SizedBox(height: 16),
            Text(
              data.isKetua ? 'Daftar Kandidat' : 'Daftar Pilihan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            if (data.isKetua)
              ...data.candidates.map(
                (candidate) => _CandidateCard(
                  candidate: candidate,
                  maxVotes: _maxCandidateVotes(data.candidates),
                  onVote: widget.onCandidateVote,
                ),
              )
            else
              ...data.activities.map(
                (activity) => _ActivityCard(
                  activity: activity,
                  maxVotes: _maxActivityVotes(data.activities),
                  onVote: widget.onActivityVote,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Duration _calculateRemainingTime() {
    final remaining = widget.data.endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int _maxCandidateVotes(List<CandidateVotingOption> items) {
    if (items.isEmpty) return 1;
    return math.max(items.map((item) => item.voteCount).reduce(math.max), 1);
  }

  int _maxActivityVotes(List<ActivityVotingOption> items) {
    if (items.isEmpty) return 1;
    return math.max(items.map((item) => item.voteCount).reduce(math.max), 1);
  }
}

class _VotingHeaderCard extends StatelessWidget {
  const _VotingHeaderCard({required this.data, required this.remainingTime});

  final VotingModel data;
  final Duration remainingTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF111827), Color(0xFF2E1065)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.tipeVoting.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.sensors_rounded, color: Color(0xFF22D3EE)),
              const SizedBox(width: 6),
              const Text(
                'Live',
                style: TextStyle(
                  color: Color(0xFF22D3EE),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _ParticipationRing(
                participantCount: data.totalParticipants,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _StatPill(
                      icon: Icons.timer_rounded,
                      label: 'Countdown',
                      value: _formatDuration(remainingTime),
                    ),
                    const SizedBox(height: 10),
                    _StatPill(
                      icon: Icons.groups_2_rounded,
                      label: 'Partisipasi',
                      value: '${data.totalParticipants} partisipan',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (days > 0) return '${days}h $hours:$minutes:$seconds';
    return '$hours:$minutes:$seconds';
  }
}

class _ParticipationRing extends StatelessWidget {
  const _ParticipationRing({required this.participantCount});

  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_2_rounded,
                color: Color(0xFF22D3EE),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                '$participantCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'partisipan',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC4B5FD), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.maxVotes,
    required this.onVote,
  });

  final CandidateVotingOption candidate;
  final int maxVotes;
  final ValueChanged<CandidateVotingOption>? onVote;

  @override
  Widget build(BuildContext context) {
    final ratio = (candidate.voteCount / maxVotes).clamp(0.0, 1.0).toDouble();

    return _OptionShell(
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF312E81),
            backgroundImage: candidate.photoUrl == null
                ? null
                : NetworkImage(candidate.photoUrl!),
            child: candidate.photoUrl == null
                ? Text(
                    _initials(candidate.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  candidate.slogan,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _MiniProgress(value: ratio),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => onVote?.call(candidate),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Cast Vote'),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.maxVotes,
    required this.onVote,
  });

  final ActivityVotingOption activity;
  final int maxVotes;
  final ValueChanged<ActivityVotingOption>? onVote;

  @override
  Widget build(BuildContext context) {
    final ratio = (activity.voteCount / maxVotes).clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;

        return _OptionShell(
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ActivityIcon(icon: activity.icon),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActivityInfo(
                            activity: activity,
                            ratio: ratio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => onVote?.call(activity),
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Pilih Opsi'),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActivityIcon(icon: activity.icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActivityInfo(activity: activity, ratio: ratio),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => onVote?.call(activity),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Pilih Opsi'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
        ),
      ),
      child: Icon(icon, color: const Color(0xFF38BDF8), size: 30),
    );
  }
}

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({required this.activity, required this.ratio});

  final ActivityVotingOption activity;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          activity.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFC4B5FD),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _formatDate(activity.estimatedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MiniProgress(value: ratio),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _OptionShell extends StatelessWidget {
  const _OptionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10162F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: animatedValue,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: const Color(0xFF8B5CF6),
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  return words
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
}
