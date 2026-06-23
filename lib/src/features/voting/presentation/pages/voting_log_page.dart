import 'package:flutter/material.dart';

class VotingLogPage extends StatefulWidget {
  const VotingLogPage({super.key});

  @override
  State<VotingLogPage> createState() => _VotingLogPageState();
}

class _VotingLogPageState extends State<VotingLogPage> {
  final List<_VotingLogItem> _items = const [
    _VotingLogItem(
      title: 'Voting Program Kegiatan',
      creatorName: 'BEM Fakultas Teknik',
      period: '02 Jun 2026 - 16 Jun 2026',
      winner: 'FTJ',
      winnerPercentage: 65,
      options: [
        _VotingLogOption(name: 'FTJ', percentage: 65, votes: 156),
        _VotingLogOption(name: 'WEBINAR', percentage: 35, votes: 84),
      ],
    ),
    _VotingLogItem(
      title: 'Voting Ketua Ormawa',
      creatorName: 'Himpunan Mahasiswa Teknologi Informasi',
      period: '11 Mei 2026 - 25 Mei 2026',
      winner: 'Arjun Wijaya',
      winnerPercentage: 58,
      options: [
        _VotingLogOption(name: 'Arjun Wijaya', percentage: 58, votes: 132),
        _VotingLogOption(name: 'Nadia Putri', percentage: 42, votes: 96),
      ],
    ),
  ];

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
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _VotingLogCard(item: _items[index]);
          },
        ),
      ),
    );
  }
}

class _VotingLogCard extends StatelessWidget {
  const _VotingLogCard({required this.item});

  final _VotingLogItem item;

  @override
  Widget build(BuildContext context) {
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
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.period,
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
          ...item.options.map((option) => _VotingLogOptionRow(option: option)),
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
            child: Text(
              '🏆 Hasil Akhir: ${item.winner} Menang (${item.winnerPercentage}% Suara)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
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
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
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
  const _VotingLogOptionRow({required this.option});

  final _VotingLogOption option;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
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
                '${option.votes} suara',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: option.percentage / 100),
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

class _VotingLogItem {
  const _VotingLogItem({
    required this.title,
    required this.creatorName,
    required this.period,
    required this.winner,
    required this.winnerPercentage,
    required this.options,
  });

  final String title;
  final String creatorName;
  final String period;
  final String winner;
  final int winnerPercentage;
  final List<_VotingLogOption> options;
}

class _VotingLogOption {
  const _VotingLogOption({
    required this.name,
    required this.percentage,
    required this.votes,
  });

  final String name;
  final int percentage;
  final int votes;
}
