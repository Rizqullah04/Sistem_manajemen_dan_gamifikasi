import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_responsive.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class AdminOrmawaAwardsPage extends ConsumerWidget {
  const AdminOrmawaAwardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Ormawa Awards',
      onLogout: () {
        ref.read(authControllerProvider.notifier).logout();
        context.go('/login');
      },
      body: const _AdminOrmawaAwardsContent(),
    );
  }
}

class _AdminOrmawaAwardsContent extends ConsumerStatefulWidget {
  const _AdminOrmawaAwardsContent();

  @override
  ConsumerState<_AdminOrmawaAwardsContent> createState() =>
      _AdminOrmawaAwardsContentState();
}

class _AdminOrmawaAwardsContentState
    extends ConsumerState<_AdminOrmawaAwardsContent> {
  final _formKey = GlobalKey<FormState>();
  final _periodController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _pointsWeightController = TextEditingController(text: '40');
  final _votingWeightController = TextEditingController(text: '20');
  final _discussionWeightController = TextEditingController(text: '20');
  final _attendanceWeightController = TextEditingController(text: '20');
  final _dateFormat = DateFormat('yyyy-MM-dd');

  OrmawaAwardPreview? _preview;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodController.text = 'Ormawa Awards ${now.year}';
    _startController.text = _dateFormat.format(DateTime(now.year));
    _endController.text = _dateFormat.format(DateTime(now.year, 12, 31));
    Future.microtask(_loadPreview);
  }

  @override
  void dispose() {
    _periodController.dispose();
    _startController.dispose();
    _endController.dispose();
    _pointsWeightController.dispose();
    _votingWeightController.dispose();
    _discussionWeightController.dispose();
    _attendanceWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user?.role != UserRole.adminFaculty) {
      return const EmptyState(
        title: 'Akses khusus admin',
        subtitle: 'Penilaian Ormawa Awards hanya tersedia untuk admin.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = DashboardResponsive.getContentPadding(width);
        final spacing = DashboardResponsive.getSpacing(width);
        final isWide = width >= DashboardResponsive.desktopMinWidth;

        return RefreshIndicator(
          onRefresh: _loadPreview,
          child: ListView(
            padding: padding,
            children: [
              _HeaderCard(
                isBusy: _isLoading || _isSaving,
                onPreview: _loadPreview,
                onGenerate: _generateAwards,
              ),
              SizedBox(height: spacing),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFormCard(context)),
                    SizedBox(width: spacing),
                    Expanded(child: _buildSummaryCard(context)),
                  ],
                )
              else ...[
                _buildFormCard(context),
                SizedBox(height: spacing),
                _buildSummaryCard(context),
              ],
              SizedBox(height: spacing),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_preview == null)
                Column(
                  children: [
                    const EmptyState(
                      title: 'Preview belum tersedia',
                      subtitle: 'Isi periode dan bobot, lalu muat preview.',
                      icon: Icons.fact_check_outlined,
                    ),
                    FilledButton.icon(
                      onPressed: _loadPreview,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Muat Preview'),
                    ),
                  ],
                )
              else
                _AwardsTable(preview: _preview!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Periode dan Kriteria',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _periodController,
                decoration: const InputDecoration(
                  labelText: 'Nama Periode Penilaian',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _required('Nama periode wajib diisi'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      controller: _startController,
                      label: 'Mulai',
                      onPick: () => _pickDate(_startController),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      controller: _endController,
                      label: 'Selesai',
                      onPick: () => _pickDate(_endController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _WeightField(
                controller: _pointsWeightController,
                label: 'Poin',
                icon: Icons.stars_outlined,
              ),
              const SizedBox(height: 10),
              _WeightField(
                controller: _votingWeightController,
                label: 'Voting',
                icon: Icons.how_to_vote_outlined,
              ),
              const SizedBox(height: 10),
              _WeightField(
                controller: _discussionWeightController,
                label: 'Diskusi',
                icon: Icons.forum_outlined,
              ),
              const SizedBox(height: 10),
              _WeightField(
                controller: _attendanceWeightController,
                label: 'Kehadiran',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final preview = _preview;
    final entries = preview?.entries ?? const <OrmawaAwardEntry>[];
    final top = entries.isEmpty ? null : entries.first;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekap Penilaian',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              icon: Icons.apartment_rounded,
              label: 'Ormawa Dinilai',
              value: '${entries.length}',
            ),
            _SummaryRow(
              icon: Icons.percent_rounded,
              label: 'Total Bobot',
              value: preview == null
                  ? '-'
                  : preview.weightTotal.toStringAsFixed(0),
            ),
            _SummaryRow(
              icon: Icons.emoji_events_outlined,
              label: 'Peringkat Teratas',
              value: top?.name ?? '-',
            ),
            _SummaryRow(
              icon: Icons.scoreboard_outlined,
              label: 'Nilai Teratas',
              value: top == null ? '-' : top.totalScore.toStringAsFixed(2),
            ),
          ],
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked == null) return;
    controller.text = _dateFormat.format(picked);
  }

  Future<void> _loadPreview() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/ormawa-awards/preview',
            data: _payload(),
          );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        setState(() => _preview = OrmawaAwardPreview.fromJson(data));
      }
    } on DioException catch (error) {
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAwards() async {
    if (!_validateForm()) return;
    setState(() => _isSaving = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/ormawa-awards/generate',
            data: _payload(),
          );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        setState(() => _preview = OrmawaAwardPreview.fromJson(data));
      }
      ref.invalidate(ormawaLeaderboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil Ormawa Awards berhasil disimpan.')),
      );
    } on DioException catch (error) {
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;

    final start = DateTime.tryParse(_startController.text);
    final end = DateTime.tryParse(_endController.text);
    if (start == null || end == null || end.isBefore(start)) {
      _showError('Tanggal periode tidak valid.');
      return false;
    }

    final totalWeight = _weight(_pointsWeightController) +
        _weight(_votingWeightController) +
        _weight(_discussionWeightController) +
        _weight(_attendanceWeightController);
    if (totalWeight <= 0) {
      _showError('Total bobot harus lebih dari 0.');
      return false;
    }

    return true;
  }

  Map<String, dynamic> _payload() {
    return {
      'period_name': _periodController.text.trim(),
      'starts_on': _startController.text.trim(),
      'ends_on': _endController.text.trim(),
      'weights': {
        'points': _weight(_pointsWeightController),
        'voting': _weight(_votingWeightController),
        'discussion': _weight(_discussionWeightController),
        'attendance': _weight(_attendanceWeightController),
      },
    };
  }

  double _weight(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Tidak dapat memproses Ormawa Awards.';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isBusy,
    required this.onPreview,
    required this.onGenerate,
  });

  final bool isBusy;
  final VoidCallback onPreview;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penilaian Ormawa Awards',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hitung peringkat berdasarkan poin, voting, diskusi, dan kehadiran dalam periode penilaian.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onPreview,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Preview'),
                ),
                FilledButton.icon(
                  onPressed: isBusy ? null : onGenerate,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Hitung & Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.onPick,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onPick,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.event_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || DateTime.tryParse(value) == null) {
          return 'Tanggal wajib valid';
        }
        return null;
      },
    );
  }
}

class _WeightField extends StatelessWidget {
  const _WeightField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Bobot $label',
        prefixIcon: Icon(icon),
        suffixText: '%',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
        if (parsed == null || parsed < 0 || parsed > 100) {
          return 'Bobot 0 sampai 100';
        }
        return null;
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AwardsTable extends StatelessWidget {
  const _AwardsTable({required this.preview});

  final OrmawaAwardPreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.entries.isEmpty) {
      return const EmptyState(
        title: 'Belum ada data penilaian',
        subtitle: 'Tidak ada Ormawa yang dapat dihitung pada periode ini.',
        icon: Icons.table_chart_outlined,
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Rank')),
            DataColumn(label: Text('Ormawa')),
            DataColumn(label: Text('Kegiatan')),
            DataColumn(label: Text('Poin')),
            DataColumn(label: Text('Voting')),
            DataColumn(label: Text('Diskusi')),
            DataColumn(label: Text('Kehadiran')),
            DataColumn(label: Text('Nilai')),
          ],
          rows: preview.entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text('#${entry.ranking}')),
                DataCell(Text(entry.name)),
                DataCell(Text('${entry.metrics.activities}')),
                DataCell(Text('${entry.metrics.points}')),
                DataCell(Text('${entry.metrics.votingVotes}')),
                DataCell(Text('${entry.metrics.discussions}')),
                DataCell(Text('${entry.metrics.attendance}')),
                DataCell(Text(entry.totalScore.toStringAsFixed(2))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class OrmawaAwardPreview {
  const OrmawaAwardPreview({
    required this.weightTotal,
    required this.entries,
  });

  final double weightTotal;
  final List<OrmawaAwardEntry> entries;

  factory OrmawaAwardPreview.fromJson(Map<String, dynamic> json) {
    final data = json['entries'];
    return OrmawaAwardPreview(
      weightTotal:
          double.tryParse(json['criteria_weight_total']?.toString() ?? '0') ??
              0,
      entries: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(OrmawaAwardEntry.fromJson)
              .toList()
          : const <OrmawaAwardEntry>[],
    );
  }
}

class OrmawaAwardEntry {
  const OrmawaAwardEntry({
    required this.name,
    required this.ranking,
    required this.totalScore,
    required this.metrics,
  });

  final String name;
  final int ranking;
  final double totalScore;
  final OrmawaAwardMetrics metrics;

  factory OrmawaAwardEntry.fromJson(Map<String, dynamic> json) {
    return OrmawaAwardEntry(
      name: json['name']?.toString() ?? '-',
      ranking: int.tryParse(json['ranking']?.toString() ?? '0') ?? 0,
      totalScore: double.tryParse(json['total_score']?.toString() ?? '0') ?? 0,
      metrics: OrmawaAwardMetrics.fromJson(
        json['metrics'] is Map<String, dynamic>
            ? json['metrics'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
    );
  }
}

class OrmawaAwardMetrics {
  const OrmawaAwardMetrics({
    required this.activities,
    required this.points,
    required this.votingVotes,
    required this.discussions,
    required this.attendance,
  });

  final int activities;
  final int points;
  final int votingVotes;
  final int discussions;
  final int attendance;

  factory OrmawaAwardMetrics.fromJson(Map<String, dynamic> json) {
    return OrmawaAwardMetrics(
      activities: int.tryParse(json['activities']?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      votingVotes: int.tryParse(json['voting_votes']?.toString() ?? '0') ?? 0,
      discussions: int.tryParse(json['discussions']?.toString() ?? '0') ?? 0,
      attendance: int.tryParse(json['attendance']?.toString() ?? '0') ?? 0,
    );
  }
}
