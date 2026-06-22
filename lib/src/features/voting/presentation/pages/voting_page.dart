import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/presentation/providers/voting_controller.dart';

class VotingPage extends ConsumerStatefulWidget {
  const VotingPage({super.key});

  @override
  ConsumerState<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends ConsumerState<VotingPage> {
  static const int _minKetuaPoints = 100;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(votingControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(votingControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final canCreateVoting =
        user?.role == UserRole.adminFaculty ||
        user?.role == UserRole.ormawaAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting Digital'),
        actions: [
          const DashboardHomeAction(),
          IconButton(
            onPressed: () => ref.read(votingControllerProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: canCreateVoting
          ? FloatingActionButton.extended(
              onPressed: user == null
                  ? null
                  : () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) {
                          return _CreateVotingSheet(
                            user: user,
                            minKetuaPoints: _minKetuaPoints,
                          );
                        },
                      );
                    },
              icon: const Icon(Icons.add),
              label: const Text('Buat Voting'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(votingControllerProvider.notifier).load(),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  const EmptyState(
                    title: 'Belum ada voting',
                    subtitle: 'Voting yang aktif akan muncul di sini.',
                    icon: Icons.how_to_vote_outlined,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final voting = state.items[index];
                return _VotingCard(
                  voting: voting,
                  canManagePeriod: user?.role == UserRole.adminFaculty,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CreateVotingSheet extends ConsumerStatefulWidget {
  const _CreateVotingSheet({required this.user, required this.minKetuaPoints});

  final User user;
  final int minKetuaPoints;

  @override
  ConsumerState<_CreateVotingSheet> createState() => _CreateVotingSheetState();
}

class _CreateVotingSheetState extends ConsumerState<_CreateVotingSheet> {
  late final TextEditingController _titleController;
  late VotingType _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;
  late final List<TextEditingController> _optionControllers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = VotingType.kegiatan;
    _titleController = TextEditingController(text: 'Polling Kegiatan Ormawa');
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate.add(const Duration(days: 14));
    _optionControllers = [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreateKetua =
        widget.user.role == UserRole.adminFaculty ||
        widget.user.points >= widget.minKetuaPoints;
    final pollOptions = _pollOptions;
    final canSubmit =
        !_isSubmitting &&
        pollOptions.length >= 2 &&
        (_selectedType == VotingType.kegiatan || canCreateKetua);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.7,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF120E24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF6D28D9),
                        child: Icon(
                          Icons.how_to_vote_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buat Polling Voting',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masukkan opsi kegiatan atau tempat yang akan dipilih dalam polling.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _VotingPointSummaryCard(
                    userPoints: widget.user.points,
                    minKetuaPoints: widget.minKetuaPoints,
                    canCreateKetua: canCreateKetua,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Jenis voting',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<VotingType>(
                    segments: const [
                      ButtonSegment(
                        value: VotingType.kegiatan,
                        label: Text('Polling Kegiatan'),
                        icon: Icon(Icons.event_note_outlined),
                      ),
                      ButtonSegment(
                        value: VotingType.ketua,
                        label: Text('Voting Ketua'),
                        icon: Icon(Icons.emoji_events_outlined),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedType = selection.first;
                        _titleController.text =
                            _selectedType == VotingType.ketua
                            ? 'Voting Ketua Ormawa'
                            : 'Polling Kegiatan Ormawa';
                      });
                    },
                  ),
                  if (_selectedType == VotingType.ketua && !canCreateKetua) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Voting ketua terkunci sampai akumulasi poin mencapai batas minimum.',
                      style: TextStyle(color: Colors.amberAccent),
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Judul Voting',
                      hintText: 'Contoh: Polling Lokasi Seminar',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Opsi Polling',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan minimal 2 kegiatan atau tempat yang akan dipilih.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_optionControllers.length, (index) {
                    final controller = _optionControllers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Opsi ${index + 1}',
                                hintText:
                                    'Contoh: Aula Utama / Gedung Serbaguna',
                              ),
                            ),
                          ),
                          if (_optionControllers.length > 2)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  controller.dispose();
                                  _optionControllers.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.redAccent,
                            ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(
                          () => _optionControllers.add(TextEditingController()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Opsi'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Tanggal Mulai',
                          value: _formatDate(_startDate),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked == null) return;
                            setState(() {
                              _startDate = picked;
                              if (!_endDate.isAfter(_startDate)) {
                                _endDate = _startDate.add(
                                  const Duration(days: 14),
                                );
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'Tanggal Selesai',
                          value: _formatDate(_endDate),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate.add(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked == null) return;
                            setState(() => _endDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canSubmit ? _submit : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _selectedType == VotingType.ketua
                            ? 'Simpan Voting Ketua'
                            : 'Simpan Polling Kegiatan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> get _pollOptions {
    return _optionControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  Future<void> _submit() async {
    final pollOptions = _pollOptions;
    if (pollOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan minimal 2 opsi polling.')),
      );
      return;
    }

    if (_selectedType == VotingType.ketua &&
        widget.user.points < widget.minKetuaPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poin ormawa belum mencukupi untuk voting ketua.'),
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul voting wajib diisi.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(votingControllerProvider.notifier)
          .createVoting(
            title: _titleController.text.trim(),
            type: _selectedType,
            startDate: _startDate,
            endDate: _endDate,
            pollOptions: pollOptions,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voting berhasil dibuat.')));
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Gagal membuat voting.')
          : 'Gagal membuat voting.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuat voting.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingPointSummaryCard extends StatelessWidget {
  const _VotingPointSummaryCard({
    required this.userPoints,
    required this.minKetuaPoints,
    required this.canCreateKetua,
  });

  final int userPoints;
  final int minKetuaPoints;
  final bool canCreateKetua;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1630),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _PointChip(
            label: 'Poin ormawa',
            value: '$userPoints',
            highlighted: true,
          ),
          _PointChip(label: 'Minimum ketua', value: '$minKetuaPoints'),
          _PointChip(
            label: 'Voting ketua',
            value: canCreateKetua ? 'Terbuka' : 'Terkunci',
            highlighted: canCreateKetua,
          ),
        ],
      ),
    );
  }
}

class _PointChip extends StatelessWidget {
  const _PointChip({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? const Color(0xFF6D28D9).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = highlighted ? const Color(0xFF8B5CF6) : Colors.white12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _VotingCard extends ConsumerWidget {
  const _VotingCard({required this.voting, required this.canManagePeriod});

  final Voting voting;
  final bool canManagePeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final totalVotes = voting.options.fold<int>(
      0,
      (sum, option) => sum + option.votes,
    );
    final hasVoted = user != null && voting.voterIds.contains(user.id);
    final periodText =
        '${DateFormat('dd MMM').format(voting.startDate)} - ${DateFormat('dd MMM yyyy').format(voting.endDate)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voting.type == VotingType.kegiatan
                  ? 'Voting Penilaian Kegiatan'
                  : 'Voting Ketua Ormawa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Periode: $periodText'),
            const SizedBox(height: 10),
            ...voting.options.map((option) {
              final ratio = totalVotes == 0 ? 0.0 : option.votes / totalVotes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(option.title)),
                        Text('${option.votes} suara'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: ratio),
                    const SizedBox(height: 4),
                    FilledButton.tonal(
                      onPressed: (voting.isActive && !hasVoted && user != null)
                          ? () {
                              ref
                                  .read(votingControllerProvider.notifier)
                                  .castVote(
                                    votingId: voting.id,
                                    optionId: option.id,
                                  );
                            }
                          : null,
                      child: const Text('Pilih'),
                    ),
                  ],
                ),
              );
            }),
            if (hasVoted) const Text('Anda sudah menggunakan hak suara.'),
            if (canManagePeriod)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    await ref
                        .read(votingControllerProvider.notifier)
                        .updatePeriod(
                          votingId: voting.id,
                          startDate: now,
                          endDate: now.add(const Duration(days: 14)),
                        );
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Atur Periode'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
