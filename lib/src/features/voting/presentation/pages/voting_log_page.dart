import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';

class VotingLogPage extends StatefulWidget {
  const VotingLogPage({required this.completedVotes, super.key});

  final List<Voting> completedVotes;

  @override
  State<VotingLogPage> createState() => _VotingLogPageState();
}

class _VotingLogPageState extends State<VotingLogPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080B1F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080B1F),
          foregroundColor: Colors.white,
          title: const Text('Log Riwayat Voting'),
        ),
        body: widget.completedVotes.isEmpty
            ? const _EmptyVotingLog()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.completedVotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _VotingLogCard(voting: widget.completedVotes[index]);
                },
              ),
      ),
    );
  }
}

class _EmptyVotingLog extends StatelessWidget {
  const _EmptyVotingLog();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        EmptyState(
          title: 'Belum ada riwayat voting',
          subtitle: 'Voting yang sudah selesai akan muncul di halaman ini.',
          icon: Icons.history_rounded,
        ),
      ],
    );
  }
}

class _VotingLogCard extends StatelessWidget {
  const _VotingLogCard({required this.voting});

  final Voting voting;

  @override
  Widget build(BuildContext context) {
    final totalVotes = voting.options.fold<int>(
      0,
      (sum, option) => sum + option.votes,
    );
    final winner = _winnerOption(voting.options);
    final winnerPercent = totalVotes == 0
        ? 0
        : ((winner.votes / totalVotes) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10162F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voting.type == VotingType.kegiatan
                          ? 'Voting Program Kegiatan'
                          : 'Voting Ketua Ormawa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voting.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _periodText(voting),
                      style: const TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _FinishedBadge(),
            ],
          ),
          const SizedBox(height: 16),
          ...voting.options.map(
            (option) => _VotingLogOptionRow(
              option: option,
              totalVotes: totalVotes,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1065).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFC4B5FD).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFDE68A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hasil Akhir: ${winner.title} Menang ($winnerPercent% Suara)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoteOption _winnerOption(List<VoteOption> options) {
    if (options.isEmpty) {
      return const VoteOption(id: '-', title: '-', votes: 0);
    }
    return options.reduce(
      (current, next) => next.votes > current.votes ? next : current,
    );
  }

  String _periodText(Voting voting) {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(voting.startDate)} - ${formatter.format(voting.endDate)}';
  }
}

class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'SELESAI',
        style: TextStyle(
          color: Color(0xFF86EFAC),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VotingLogOptionRow extends StatelessWidget {
  const _VotingLogOptionRow({
    required this.option,
    required this.totalVotes,
  });

  final VoteOption option;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final ratio = totalVotes == 0 ? 0.0 : option.votes / totalVotes;
    final percentage = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${option.votes} suara - $percentage%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: ratio.clamp(0.0, 1.0).toDouble(),
            ),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: const Color(0xFF8B5CF6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
