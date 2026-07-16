import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/empty_state.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';

class AdminOrmawaAwardsHistoryPage extends ConsumerStatefulWidget {
  const AdminOrmawaAwardsHistoryPage({super.key});

  @override
  ConsumerState<AdminOrmawaAwardsHistoryPage> createState() =>
      _AdminOrmawaAwardsHistoryPageState();
}

class _AdminOrmawaAwardsHistoryPageState
    extends ConsumerState<AdminOrmawaAwardsHistoryPage> {
  List<Map<String, dynamic>> _histories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/ormawa-awards/history');
      final data = response.data?['data'];
      if (!mounted) return;
      setState(() {
        _histories = data is List
            ? data.whereType<Map<String, dynamic>>().toList()
            : const [];
      });
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Hasil Ormawa Awards')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _histories.isEmpty
                ? const EmptyState(
                    title: 'Belum ada riwayat',
                    subtitle: 'Hasil yang dihitung dan disimpan akan tampil di sini.',
                    icon: Icons.history_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _histories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _HistoryCard(data: _histories[index], onDelete: _delete),
                  ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> history) async {
    final period = history['periode']?.toString() ?? 'periode ini';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Penilaian?'),
        content: Text(
          'Seluruh hasil dan peringkat "$period" akan dihapus permanen. Gunakan hanya jika riwayat salah atau tidak lagi diperlukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Riwayat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(dioProvider).delete<Map<String, dynamic>>(
            '/ormawa-awards/history/${history['history_id']}',
          );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Riwayat "$period" berhasil dihapus.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    return data is Map && data['message'] is String
        ? data['message'] as String
        : 'Tidak dapat memproses riwayat penilaian.';
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data, required this.onDelete});

  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    final entries = data['entries'] is List
        ? (data['entries'] as List).whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final calculated = DateTime.tryParse(data['calculated_at']?.toString() ?? '');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.fact_check_outlined)),
        title: Text(
          data['periode']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${data['starts_on'] ?? '-'} s.d. ${data['ends_on'] ?? '-'}\n'
          'Disimpan ${calculated == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(calculated.toLocal())}',
        ),
        trailing: IconButton(
          tooltip: 'Hapus riwayat ini',
          onPressed: () => onDelete(data),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        children: [
          const Divider(height: 1),
          for (final entry in entries) _HistoryEntry(data: entry),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scores = data['rubric_scores'] is Map
        ? Map<String, dynamic>.from(data['rubric_scores'] as Map)
        : const <String, dynamic>{};
    final metrics = data['system_metrics'] is Map
        ? Map<String, dynamic>.from(data['system_metrics'] as Map)
        : const <String, dynamic>{};
    final notes = data['rubric_notes']?.toString().trim() ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        '#${data['ranking'] ?? '-'}  ${data['ormawa'] ?? 'Ormawa'}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Disiplin ${scores['kedisiplinan'] ?? '-'} · Kompak ${scores['kekompakan'] ?? '-'} · '
        'Komunikasi ${scores['komunikasi'] ?? '-'} · Keaktifan ${scores['keaktifan'] ?? '-'} · '
        'ProKer ${scores['kesuksesan_proker'] ?? '-'}\n'
        'Catatan: ${notes.isEmpty ? '-' : notes}\n'
        'Data sistem: ${metrics['points'] ?? 0} poin, ${metrics['voting_votes'] ?? 0} suara, '
        '${metrics['discussions'] ?? 0} diskusi',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data['total_score']?.toString() ?? '0',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(data['predicate']?.toString() ?? '-'),
        ],
      ),
    );
  }
}
