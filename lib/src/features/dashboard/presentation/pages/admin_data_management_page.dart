import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';

class AdminDataManagementPage extends ConsumerStatefulWidget {
  const AdminDataManagementPage({super.key});

  @override
  ConsumerState<AdminDataManagementPage> createState() =>
      _AdminDataManagementPageState();
}

class _AdminDataManagementPageState
    extends ConsumerState<AdminDataManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/activity-types'),
        _dio.get<Map<String, dynamic>>('/poin-logs'),
      ]);
      if (!mounted) return;
      setState(() {
        _types = _list(responses[0]);
        _logs = _list(responses[1]);
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        error.response?.data?['message']?.toString() ??
            'Data audit gamifikasi gagal dimuat.',
      );
    }
  }

  List<Map<String, dynamic>> _list(
    Response<Map<String, dynamic>> response,
  ) {
    final value = response.data?['data'];
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Gamifikasi'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Aturan Poin'),
            Tab(text: 'Riwayat Transaksi'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: _editType,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Aturan'),
              )
            : const SizedBox.shrink(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabs,
                children: [_typeList(), _logList()],
              ),
            ),
    );
  }

  Widget _typeList() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AuditExplanation(
            title: 'Aturan dan Sumber Poin',
            message:
                'Kelola aktivitas yang dapat menghasilkan poin. Aturan nonaktif tetap disimpan sebagai rancangan, tetapi tidak dihitung oleh sistem.',
          ),
          const SizedBox(height: 12),
          if (_types.isEmpty)
            const _EmptyAudit(message: 'Belum ada aturan poin.')
          else
            for (final item in _types)
              Card(
                child: SwitchListTile(
                  value: item['is_active'] == true || item['is_active'] == 1,
                  onChanged: (_) => _editType(item),
                  title: Text(item['name']?.toString() ?? '-'),
                  subtitle: Text(
                    '${item['code'] ?? '-'} · ${item['point_value'] ?? 0} poin',
                  ),
                  secondary: IconButton(
                    tooltip: 'Hapus aturan',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteType(item),
                  ),
                ),
              ),
          const SizedBox(height: 88),
        ],
      );

  Widget _logList() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AuditExplanation(
            title: 'Jejak Audit Poin',
            message:
                'Setiap transaksi menampilkan penerima, nilai, sumber, alasan, dan tanggal. Data ini digunakan untuk memeriksa transparansi leaderboard.',
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            const _EmptyAudit(message: 'Belum ada transaksi poin.')
          else
            for (final item in _logs)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${item['poin'] ?? 0}')),
                  title: Text(_recipient(item)),
                  subtitle: Text(
                    '${item['sumber'] ?? '-'} · ${item['keterangan'] ?? '-'}',
                  ),
                  trailing: Text(
                    item['tanggal']?.toString().split('T').first ?? '-',
                  ),
                ),
              ),
        ],
      );

  String _recipient(Map<String, dynamic> item) {
    final user = item['user'] as Map?;
    final organization = item['ormawa'] as Map?;
    return user?['nama']?.toString() ??
        organization?['nama_ormawa']?.toString() ??
        'Sistem';
  }

  Future<void> _editType([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name']?.toString() ?? '');
    final code = TextEditingController(text: item?['code']?.toString() ?? '');
    final points = TextEditingController(
      text: item?['point_value']?.toString() ?? '0',
    );
    var active = item == null ||
        item['is_active'] == true ||
        item['is_active'] == 1;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Tambah Aturan Poin' : 'Edit Aturan Poin'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nama aktivitas'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Kode unik'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: points,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nilai poin'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      return parsed == null || parsed < 0
                          ? 'Poin wajib berupa angka minimal 0'
                          : null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (value) =>
                        setDialogState(() => active = value),
                    title: const Text('Aturan aktif'),
                    subtitle: const Text(
                      'Aturan nonaktif tidak digunakan dalam perhitungan.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final data = {
        'name': name.text.trim(),
        'code': code.text.trim().toUpperCase(),
        'point_value': int.parse(points.text),
        'frequency_level': item?['frequency_level'] ?? 'medium',
        'difficulty_level': item?['difficulty_level'] ?? 'medium',
        'organizational_impact': item?['organizational_impact'] ?? 'medium',
        'is_active': active,
      };
      try {
        if (item == null) {
          await _dio.post<Map<String, dynamic>>('/activity-types', data: data);
        } else {
          await _dio.patch<Map<String, dynamic>>(
            '/activity-types/${item['id_activity_type']}',
            data: data,
          );
        }
        await _load();
      } on DioException catch (error) {
        _message(
          error.response?.data?['message']?.toString() ??
              'Aturan poin gagal disimpan.',
        );
      }
    }

    name.dispose();
    code.dispose();
    points.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Bagian ini wajib diisi'
      : null;

  Future<void> _confirmDeleteType(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aturan Poin?'),
        content: Text(
          'Aturan "${item['name'] ?? '-'}" hanya dapat dihapus jika belum pernah digunakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/activity-types/${item['id_activity_type']}',
      );
      await _load();
    } on DioException catch (error) {
      _message(
        error.response?.data?['message']?.toString() ??
            'Aturan poin gagal dihapus.',
      );
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AuditExplanation extends StatelessWidget {
  const _AuditExplanation({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(message),
      ),
    );
  }
}

class _EmptyAudit extends StatelessWidget {
  const _EmptyAudit({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(child: Text(message)),
    );
  }
}
