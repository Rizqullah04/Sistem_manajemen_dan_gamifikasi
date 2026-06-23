import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_home_action.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/domain/entities/voting.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/voting/presentation/pages/live_voting_preview_page.dart';
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
  late final List<Uint8List?> _optionImageBytes;
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = VotingType.kegiatan;
    _titleController = TextEditingController(text: 'Polling Kegiatan Ormawa');
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate.add(const Duration(days: 14));
    _optionControllers = [TextEditingController(), TextEditingController()];
    _optionImageBytes = [null, null];
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
                    final imageBytes = _optionImageBytes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Opsi ${index + 1}',
                                hintText:
                                    'Contoh: Aula Utama / Gedung Serbaguna',
                                prefixIcon: const Icon(
                                  Icons.event_available_outlined,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (imageBytes != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundImage:
                                              MemoryImage(imageBytes),
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Pilih gambar opsi',
                                      onPressed: () =>
                                          _pickOptionImage(index),
                                      icon: Icon(
                                        imageBytes == null
                                            ? Icons.add_photo_alternate_outlined
                                            : Icons.photo_camera_back_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_optionControllers.length > 2)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  controller.dispose();
                                  _optionControllers.removeAt(index);
                                  _optionImageBytes.removeAt(index);
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _optionControllers.add(TextEditingController());
                          _optionImageBytes.add(null);
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Opsi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        side: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 1.3,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
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

  Future<void> _pickOptionImage(int index) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (index >= _optionImageBytes.length) return;
    setState(() => _optionImageBytes[index] = bytes);
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1630).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PointMetricChip(
            icon: Icons.bolt_rounded,
            label: 'Poin ormawa',
            value: '$userPoints',
            highlighted: true,
          ),
          _PointMetricChip(
            icon: Icons.flag_circle_outlined,
            label: 'Minimum ketua',
            value: '$minKetuaPoints',
          ),
          _PointMetricChip(
            icon: canCreateKetua
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            label: 'Voting ketua',
            value: canCreateKetua ? 'Terbuka' : 'Terkunci',
            highlighted: canCreateKetua,
          ),
        ],
      ),
    );
  }
}

class _PointMetricChip extends StatelessWidget {
  const _PointMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? const Color(0xFFC4B5FD) : Colors.white70;
    final backgroundColor = highlighted
        ? const Color(0xFF7C3AED).withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.07);

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(
        color: highlighted ? const Color(0xFF8B5CF6) : Colors.white12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _OrmawaCreatorBadge extends StatelessWidget {
  const _OrmawaCreatorBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFF6D28D9).withValues(alpha: 0.15),
          child: Text(
            _optionInitials(name),
            style: const TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Pembuat',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
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
    final canUseVote = user?.role == UserRole.memberAccount;
    final creatorOrmawaName = _creatorOrmawaNameFor(voting);
    final periodText =
        '${DateFormat('dd MMM').format(voting.startDate)} - ${DateFormat('dd MMM yyyy').format(voting.endDate)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrmawaCreatorBadge(name: creatorOrmawaName),
            const SizedBox(height: 10),
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
              return _VoteOptionTile(
                option: option,
                ratio: ratio,
                canTap: voting.isActive && !hasVoted && user != null,
                canVote: canUseVote,
                ormawaName: creatorOrmawaName,
                onOpenPreview: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LiveVotingPreviewPage(
                        data: _buildLivePreviewData(
                          voting: voting,
                          creatorOrmawaName: creatorOrmawaName,
                        ),
                        onCandidateVote: (_) => Navigator.of(context).pop(),
                        onActivityVote: (_) => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
                onVote: () async {
                  try {
                    await ref
                        .read(votingControllerProvider.notifier)
                        .castVote(votingId: voting.id, optionId: option.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vote berhasil disimpan.')),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_errorMessage(error))),
                    );
                  }
                },
              );
            }),
            if (user != null && !canUseVote)
              Text(
                'Voting hanya tersedia untuk akun anggota resmi $creatorOrmawaName.',
              ),
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

class _VoteOptionTile extends StatelessWidget {
  const _VoteOptionTile({
    required this.option,
    required this.ratio,
    required this.canTap,
    required this.canVote,
    required this.ormawaName,
    required this.onOpenPreview,
    required this.onVote,
  });

  final VoteOption option;
  final double ratio;
  final bool canTap;
  final bool canVote;
  final String ormawaName;
  final VoidCallback onOpenPreview;
  final Future<void> Function() onVote;

  @override
  Widget build(BuildContext context) {
    final color = _optionColor(option.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onOpenPreview,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Text(
                    _optionInitials(option.title),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${option.votes} suara',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _LiveDetailBadge(color: color),
                          Text(
                            'Tap untuk melihat preview live',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AnimatedVoteBar(value: ratio, color: color),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 6),
                    _VoteActionButton(
                      canTap: canTap,
                      canVote: canVote,
                      ormawaName: ormawaName,
                      onVote: onVote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDetailBadge extends StatelessWidget {
  const _LiveDetailBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Lihat Detail/Live',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedVoteBar extends StatelessWidget {
  const _AnimatedVoteBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 9,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: animatedValue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.58)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VoteActionButton extends StatefulWidget {
  const _VoteActionButton({
    required this.canTap,
    required this.canVote,
    required this.ormawaName,
    required this.onVote,
  });

  final bool canTap;
  final bool canVote;
  final String ormawaName;
  final Future<void> Function() onVote;

  @override
  State<_VoteActionButton> createState() => _VoteActionButtonState();
}

class _VoteActionButtonState extends State<_VoteActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: widget.canTap && !_isSubmitting ? _handlePressed : null,
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _isSubmitting
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(key: ValueKey('label'), 'Pilih'),
      ),
    );

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: button,
    );
  }

  Future<void> _handlePressed() async {
    if (!widget.canVote) {
      await _shakeController.forward(from: 0);
      if (!mounted) return;
      _showMemberOnlySheet(context, widget.ormawaName);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onVote();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

void _showMemberOnlySheet(BuildContext context, String ormawaName) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(sheetContext).colorScheme.primaryContainer,
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: Theme.of(sheetContext).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fitur ini khusus Anggota',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voting hanya tersedia untuk akun anggota resmi $ormawaName. Yuk, daftar atau lengkapi profilmu di sini untuk ikut voting!',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/profile');
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Lengkapi Profil'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _optionInitials(String title) {
  final words = title.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.runes
        .take(2)
        .map(String.fromCharCode)
        .join()
        .toUpperCase();
  }
  return words
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
}

Color _optionColor(String seed) {
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];
  return colors[seed.hashCode.abs() % colors.length];
}

String _creatorOrmawaNameFor(Voting voting) {
  const names = [
    'BEM Fakultas Teknik',
    'Himpunan Mahasiswa Teknologi Informasi',
    'Himpunan Mahasiswa Sistem Informasi',
    'Unit Kegiatan Mahasiswa Teknologi',
  ];
  final seed = '${voting.relatedId}-${voting.id}';
  return names[seed.hashCode.abs() % names.length];
}

VotingModel _buildLivePreviewData({
  required Voting voting,
  required String creatorOrmawaName,
}) {
  final totalVotes = voting.options.fold<int>(
    0,
    (sum, option) => sum + option.votes,
  );
  final participantTarget = totalVotes <= 0 ? 100 : totalVotes + 30;
  final isKetua = voting.type == VotingType.ketua;

  return VotingModel(
    tipeVoting: isKetua ? 'KETUA' : 'KEGIATAN',
    title: isKetua
        ? 'Voting Ketua Ormawa - $creatorOrmawaName'
        : 'Voting Program Kegiatan - $creatorOrmawaName',
    endTime: voting.endDate,
    totalParticipants: totalVotes,
    targetParticipants: participantTarget,
    candidates: isKetua
        ? voting.options
              .map(
                (option) => CandidateVotingOption(
                  name: option.title,
                  slogan: 'Bersama membangun ormawa yang aktif dan berdampak.',
                  voteCount: option.votes,
                ),
              )
              .toList()
        : const [],
    activities: isKetua
        ? const []
        : voting.options
              .map(
                (option) => ActivityVotingOption(
                  name: option.title,
                  description:
                      'Rencana kegiatan kolaboratif dari $creatorOrmawaName.',
                  estimatedDate: voting.startDate.add(
                    Duration(days: voting.options.indexOf(option) * 7),
                  ),
                  voteCount: option.votes,
                  icon: option.title.toLowerCase().contains('webinar')
                      ? Icons.school_rounded
                      : Icons.event_available_rounded,
                ),
              )
              .toList(),
  );
}

String _errorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }
  }
  return 'Gagal menyimpan vote.';
}
