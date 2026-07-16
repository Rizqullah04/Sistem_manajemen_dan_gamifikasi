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
      onLogout: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (!context.mounted) return;
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
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final Map<int, _DpmRubricScore> _rubricScores = {};

  OrmawaAwardPreview? _preview;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    _periodController.text = 'Ormawa Awards ${now.year}-$month';
    _startController.text = _dateFormat.format(DateTime(now.year, now.month));
    _endController.text = _dateFormat.format(
      DateTime(now.year, now.month + 1, 0),
    );
    Future.microtask(_loadPreview);
  }

  @override
  void dispose() {
    _periodController.dispose();
    _startController.dispose();
    _endController.dispose();
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
                      subtitle: 'Isi rentang penilaian, lalu muat preview.',
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
                _AwardsTable(
                  preview: _preview!,
                  scores: _rubricScores,
                  onScoreChanged: _setRubricScore,
                ),
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
                'Rentang Penilaian dan Kriteria',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _periodController,
                decoration: const InputDecoration(
                  labelText: 'Nama Rentang Penilaian',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _required('Nama rentang penilaian wajib diisi'),
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
              const _RubricInfo(),
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
              label: 'Kriteria DPM',
              value: preview == null ? '-' : '5',
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
        setState(() {
          _preview = OrmawaAwardPreview.fromJson(data);
          _syncRubricScores();
        });
      }
    } on DioException catch (error) {
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAwards() async {
    if (!_validateForm()) return;
    if (!_validateRubricScores()) return;
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
        setState(() {
          _preview = OrmawaAwardPreview.fromJson(data);
          _syncRubricScores();
        });
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
      _showError('Tanggal rentang penilaian tidak valid.');
      return false;
    }

    return true;
  }

  bool _validateRubricScores() {
    final entries = _preview?.entries ?? const <OrmawaAwardEntry>[];
    for (final entry in entries) {
      final score = _rubricScores[entry.ormawaId];
      if (score == null || !score.isComplete) {
        _showError(
          'Lengkapi skor Kedisiplinan, Kekompakan, Komunikasi, dan Kesuksesan ProKer untuk ${entry.name}.',
        );
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> _payload() {
    return {
      'period_name': _periodController.text.trim(),
      'starts_on': _startController.text.trim(),
      'ends_on': _endController.text.trim(),
      'weights': {
        'points': 40,
        'voting': 20,
        'discussion': 20,
        'attendance': 20,
      },
      'rubric_scores': _rubricScores.map(
        (id, score) => MapEntry(id.toString(), score.toJson()),
      ),
    };
  }

  void _syncRubricScores() {
    final entries = _preview?.entries ?? const <OrmawaAwardEntry>[];
    for (final entry in entries) {
      _rubricScores.putIfAbsent(
        entry.ormawaId,
        () => _DpmRubricScore.fromEntry(entry),
      );
    }
  }

  void _setRubricScore(int ormawaId, _DpmRubricScore score) {
    setState(() => _rubricScores[ormawaId] = score);
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                    'DPM FT mengisi skor rubrik 1-5 berdasarkan penilaian dan bukti kegiatan. Sistem menghitung Keaktifan otomatis dari data aktivitas, lalu menyimpan peringkat.',
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

class _RubricInfo extends StatelessWidget {
  const _RubricInfo();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rubrik DPM FT',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Nilai 1-5 bukan dibuat otomatis oleh sistem. DPM FT mengisi Kedisiplinan, Kekompakan, Komunikasi, dan Kesuksesan ProKer berdasarkan rubrik penilaian serta bukti/observasi kegiatan. Keaktifan dihitung otomatis dari poin aktivitas Ormawa pada periode ini.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Skala: 1 sangat kurang, 2 kurang, 3 cukup, 4 baik, 5 sangat baik.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
          Expanded(
            flex: 2,
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardsTable extends StatelessWidget {
  const _AwardsTable({
    required this.preview,
    required this.scores,
    required this.onScoreChanged,
  });

  final OrmawaAwardPreview preview;
  final Map<int, _DpmRubricScore> scores;
  final void Function(int ormawaId, _DpmRubricScore score) onScoreChanged;

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
            DataColumn(label: Text('Disiplin')),
            DataColumn(label: Text('Kompak')),
            DataColumn(label: Text('Komunikasi')),
            DataColumn(label: Text('Keaktifan')),
            DataColumn(label: Text('ProKer')),
            DataColumn(label: Text('Rata-rata')),
            DataColumn(label: Text('Predikat')),
            DataColumn(label: Text('Data Sistem')),
          ],
          rows: preview.entries.map((entry) {
            final score = scores[entry.ormawaId] ?? _DpmRubricScore.fromEntry(entry);
            return DataRow(
              cells: [
                DataCell(Text('#${entry.ranking}')),
                DataCell(Text(entry.name)),
                DataCell(
                  _ScoreSelect(
                    value: score.kedisiplinan,
                    onChanged: (value) => onScoreChanged(
                      entry.ormawaId,
                      score.copyWith(kedisiplinan: value),
                    ),
                  ),
                ),
                DataCell(
                  _ScoreSelect(
                    value: score.kekompakan,
                    onChanged: (value) => onScoreChanged(
                      entry.ormawaId,
                      score.copyWith(kekompakan: value),
                    ),
                  ),
                ),
                DataCell(
                  _ScoreSelect(
                    value: score.komunikasi,
                    onChanged: (value) => onScoreChanged(
                      entry.ormawaId,
                      score.copyWith(komunikasi: value),
                    ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: entry.metrics.systemActivityBasis,
                    child: Chip(
                      label: Text('${entry.metrics.systemActivityScore}'),
                      avatar: const Icon(Icons.auto_graph_outlined, size: 16),
                    ),
                  ),
                ),
                DataCell(
                  _ScoreSelect(
                    value: score.kesuksesanProker,
                    onChanged: (value) => onScoreChanged(
                      entry.ormawaId,
                      score.copyWith(kesuksesanProker: value),
                    ),
                  ),
                ),
                DataCell(Text(entry.totalScore.toStringAsFixed(2))),
                DataCell(Text(entry.predicate)),
                DataCell(
                  Text(
                    'Kegiatan ${entry.metrics.activities} | Poin ${entry.metrics.points} | Voting ${entry.metrics.votingVotes} | Diskusi ${entry.metrics.discussions} | Hadir ${entry.metrics.attendance}',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ScoreSelect extends StatelessWidget {
  const _ScoreSelect({
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isDense: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: const [1, 2, 3, 4, 5]
            .map(
              (score) => DropdownMenuItem<int>(
                value: score,
                child: Text('$score'),
              ),
            )
            .toList(),
        onChanged: onChanged,
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
    required this.ormawaId,
    required this.name,
    required this.ranking,
    required this.totalScore,
    required this.predicate,
    required this.metrics,
    required this.rubricScores,
  });

  final int ormawaId;
  final String name;
  final int ranking;
  final double totalScore;
  final String predicate;
  final OrmawaAwardMetrics metrics;
  final Map<String, int?> rubricScores;

  factory OrmawaAwardEntry.fromJson(Map<String, dynamic> json) {
    return OrmawaAwardEntry(
      ormawaId: int.tryParse(json['id_ormawa']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '-',
      ranking: int.tryParse(json['ranking']?.toString() ?? '0') ?? 0,
      totalScore: double.tryParse(json['total_score']?.toString() ?? '0') ?? 0,
      predicate: json['predicate']?.toString() ?? 'Belum Lengkap',
      metrics: OrmawaAwardMetrics.fromJson(
        json['metrics'] is Map<String, dynamic>
            ? json['metrics'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      rubricScores: _parseRubricScores(json['rubric_scores']),
    );
  }

  static Map<String, int?> _parseRubricScores(Object? data) {
    if (data is! Map<String, dynamic>) return const <String, int?>{};

    return data.map(
      (key, value) => MapEntry(key, int.tryParse(value?.toString() ?? '')),
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
    required this.systemActivityScore,
    required this.systemActivityBasis,
  });

  final int activities;
  final int points;
  final int votingVotes;
  final int discussions;
  final int attendance;
  final int systemActivityScore;
  final String systemActivityBasis;

  factory OrmawaAwardMetrics.fromJson(Map<String, dynamic> json) {
    return OrmawaAwardMetrics(
      activities: int.tryParse(json['activities']?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      votingVotes: int.tryParse(json['voting_votes']?.toString() ?? '0') ?? 0,
      discussions: int.tryParse(json['discussions']?.toString() ?? '0') ?? 0,
      attendance: int.tryParse(json['attendance']?.toString() ?? '0') ?? 0,
      systemActivityScore:
          int.tryParse(json['system_activity_score']?.toString() ?? '1') ?? 1,
      systemActivityBasis:
          json['system_activity_basis']?.toString() ??
          'Dihitung dari data aktivitas sistem.',
    );
  }
}

class _DpmRubricScore {
  const _DpmRubricScore({
    this.kedisiplinan,
    this.kekompakan,
    this.komunikasi,
    this.kesuksesanProker,
  });

  final int? kedisiplinan;
  final int? kekompakan;
  final int? komunikasi;
  final int? kesuksesanProker;

  bool get isComplete =>
      kedisiplinan != null &&
      kekompakan != null &&
      komunikasi != null &&
      kesuksesanProker != null;

  factory _DpmRubricScore.fromEntry(OrmawaAwardEntry entry) {
    return _DpmRubricScore(
      kedisiplinan: entry.rubricScores['kedisiplinan'],
      kekompakan: entry.rubricScores['kekompakan'],
      komunikasi: entry.rubricScores['komunikasi'],
      kesuksesanProker: entry.rubricScores['kesuksesan_proker'],
    );
  }

  _DpmRubricScore copyWith({
    int? kedisiplinan,
    int? kekompakan,
    int? komunikasi,
    int? kesuksesanProker,
  }) {
    return _DpmRubricScore(
      kedisiplinan: kedisiplinan ?? this.kedisiplinan,
      kekompakan: kekompakan ?? this.kekompakan,
      komunikasi: komunikasi ?? this.komunikasi,
      kesuksesanProker: kesuksesanProker ?? this.kesuksesanProker,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (kedisiplinan != null) 'kedisiplinan': kedisiplinan,
      if (kekompakan != null) 'kekompakan': kekompakan,
      if (komunikasi != null) 'komunikasi': komunikasi,
      if (kesuksesanProker != null) 'kesuksesan_proker': kesuksesanProker,
    };
  }
}
