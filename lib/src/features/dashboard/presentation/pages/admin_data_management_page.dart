import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';

class AdminDataManagementPage extends ConsumerStatefulWidget {
  const AdminDataManagementPage({super.key});

  @override
  ConsumerState<AdminDataManagementPage> createState() => _AdminDataManagementPageState();
}

class _AdminDataManagementPageState extends ConsumerState<AdminDataManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _scores = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
        _dio.get<Map<String, dynamic>>('/penilaians'),
        _dio.get<Map<String, dynamic>>('/activity-types'),
        _dio.get<Map<String, dynamic>>('/poin-logs'),
        _dio.get<Map<String, dynamic>>('/kegiatans'),
      ]);
      if (!mounted) return;
      setState(() {
        _scores = _list(responses[0]);
        _types = _list(responses[1]);
        _logs = _list(responses[2]);
        _activities = _list(responses[3]);
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(error.response?.data?['message']?.toString() ?? 'Data gagal dimuat.');
    }
  }

  List<Map<String, dynamic>> _list(Response<Map<String, dynamic>> response) {
    final value = response.data?['data'];
    return value is List ? value.whereType<Map<String, dynamic>>().toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Gamifikasi & Penilaian'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Penilaian'),
            Tab(text: 'Tipe Aktivitas'),
            Tab(text: 'Riwayat Poin'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, _) => _tabs.index == 2
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: _tabs.index == 0 ? _editScore : _editType,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabs,
                children: [_scoreList(), _typeList(), _logList()],
              ),
            ),
    );
  }

  Widget _scoreList() => _items(
        _scores,
        (item) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.fact_check_outlined)),
          title: Text((item['kegiatan'] as Map?)?['nama_kegiatan']?.toString() ?? 'Kegiatan #${item['kegiatan_id']}'),
          subtitle: Text('Total ${item['total_nilai'] ?? 0} • ${item['komentar'] ?? 'Tanpa komentar'}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? _editScore(item) : _delete('/penilaians/${item['id']}'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ),
      );

  Widget _typeList() => _items(
        _types,
        (item) => SwitchListTile(
          value: item['is_active'] == true || item['is_active'] == 1,
          onChanged: (_) => _editType(item),
          title: Text(item['name']?.toString() ?? '-'),
          subtitle: Text('${item['code']} • ${item['point_value']} poin'),
          secondary: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete('/activity-types/${item['id_activity_type']}')),
        ),
      );

  Widget _logList() => _items(
        _logs,
        (item) {
          final user = item['user'] as Map?;
          final org = item['ormawa'] as Map?;
          return ListTile(
            leading: CircleAvatar(child: Text('${item['poin'] ?? 0}')),
            title: Text(user?['nama']?.toString() ?? org?['nama_ormawa']?.toString() ?? 'Sistem'),
            subtitle: Text('${item['sumber'] ?? '-'} • ${item['keterangan'] ?? '-'}'),
            trailing: Text(item['tanggal']?.toString().split('T').first ?? '-'),
          );
        },
      );

  Widget _items(List<Map<String, dynamic>> data, Widget Function(Map<String, dynamic>) builder) {
    if (data.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('Belum ada data')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => Card(child: builder(data[index])),
    );
  }

  Future<void> _editScore([Map<String, dynamic>? item]) async {
    if (_activities.isEmpty) return _message('Belum ada kegiatan yang dapat dinilai.');
    var activityId = item?['kegiatan_id']?.toString() ?? _activities.first['id_kegiatan'].toString();
    final fields = ['nilai_kreativitas', 'nilai_dampak', 'nilai_partisipasi', 'nilai_publikasi'];
    final controllers = {for (final field in fields) field: TextEditingController(text: item?[field]?.toString() ?? '0')};
    final comment = TextEditingController(text: item?['komentar']?.toString() ?? '');
    final saved = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(item == null ? 'Tambah Penilaian' : 'Edit Penilaian'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: activityId, isExpanded: true, items: _activities.map((a) => DropdownMenuItem(value: a['id_kegiatan'].toString(), child: Text(a['nama_kegiatan']?.toString() ?? '-'))).toList(), onChanged: (v) => setDialogState(() => activityId = v!)),
        ...fields.map((field) => Padding(padding: const EdgeInsets.only(top: 10), child: TextField(controller: controllers[field], keyboardType: TextInputType.number, decoration: InputDecoration(labelText: field.replaceAll('nilai_', 'Nilai '))))),
        Padding(padding: const EdgeInsets.only(top: 10), child: TextField(controller: comment, decoration: const InputDecoration(labelText: 'Komentar'))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    )));
    if (saved != true) return;
    final data = {'kegiatan_id': activityId, for (final field in fields) field: int.tryParse(controllers[field]!.text) ?? 0, 'komentar': comment.text.trim()};
    if (item == null) { await _dio.post<Map<String, dynamic>>('/penilaians', data: data); } else { await _dio.patch<Map<String, dynamic>>('/penilaians/${item['id']}', data: data); }
    await _load();
  }

  Future<void> _editType([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name']?.toString() ?? '');
    final code = TextEditingController(text: item?['code']?.toString() ?? '');
    final points = TextEditingController(text: item?['point_value']?.toString() ?? '0');
    var active = item == null || item['is_active'] == true || item['is_active'] == 1;
    final saved = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(item == null ? 'Tambah Tipe Aktivitas' : 'Edit Tipe Aktivitas'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')), TextField(controller: code, decoration: const InputDecoration(labelText: 'Kode')), TextField(controller: points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poin')), SwitchListTile(value: active, onChanged: (v) => setDialogState(() => active = v), title: const Text('Aktif'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    )));
    if (saved != true) return;
    final data = {'name': name.text.trim(), 'code': code.text.trim(), 'point_value': int.tryParse(points.text) ?? 0, 'frequency_level': item?['frequency_level'] ?? 'medium', 'difficulty_level': item?['difficulty_level'] ?? 'medium', 'organizational_impact': item?['organizational_impact'] ?? 'medium', 'is_active': active};
    if (item == null) { await _dio.post<Map<String, dynamic>>('/activity-types', data: data); } else { await _dio.patch<Map<String, dynamic>>('/activity-types/${item['id_activity_type']}', data: data); }
    await _load();
  }

  Future<void> _delete(String path) async { await _dio.delete<Map<String, dynamic>>(path); await _load(); }
  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
