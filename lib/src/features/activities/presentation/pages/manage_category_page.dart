import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({
    required this.initialCategories,
    required this.dio,
    this.onCategoriesChanged,
    super.key,
  });

  final List<String> initialCategories;
  final Dio dio;
  final ValueChanged<List<String>>? onCategoriesChanged;

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List<String>.from(widget.initialCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: _categories.isEmpty
          ? const _EmptyCategoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _CategoryTile(
                  category: category,
                  onEdit: () =>
                      _showCategoryDialog(initialValue: category, index: index),
                  onDelete: () => _confirmDelete(index),
                );
              },
            ),
    );
  }

  Future<void> _showCategoryDialog({String? initialValue, int? index}) async {
    final isEditing = index != null;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CategoryNameDialog(
        initialValue: initialValue,
        isEditing: isEditing,
        existingCategories: _categories,
        editingIndex: index,
      ),
    );

    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted || result == null || result.isEmpty) return;

    try {
      if (isEditing) {
        final id = await _findId(initialValue!);
        await widget.dio.patch<Map<String, dynamic>>(
          '/kategori-kegiatans/$id',
          data: {'nama_kategori': result},
        );
      } else {
        await widget.dio.post<Map<String, dynamic>>(
          '/kategori-kegiatans',
          data: {'nama_kategori': result},
        );
      }
      await _reloadCategories();
    } on DioException catch (error) {
      if (!mounted) return;
      _showError(
        error.response?.data?['message']?.toString() ??
            'Kategori gagal disimpan.',
      );
    }
  }

  Future<void> _confirmDelete(int index) async {
    final category = _categories[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B1024),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFFCA5A5),
          ),
          title: const Text(
            'Hapus Kategori?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Kategori "$category" akan dihapus dari daftar pilihan.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) return;
    if (confirmed != true) return;
    try {
      final id = await _findId(category);
      await widget.dio.delete<Map<String, dynamic>>('/kategori-kegiatans/$id');
      await _reloadCategories();
    } on DioException catch (error) {
      if (!mounted) return;
      _showError(
        error.response?.data?['message']?.toString() ??
            'Kategori gagal dihapus.',
      );
    }
  }

  Future<String> _findId(String name) async {
    final response = await widget.dio.get<Map<String, dynamic>>(
      '/kategori-kegiatans',
    );
    final data = response.data?['data'];
    if (data is List) {
      for (final item in data.whereType<Map<String, dynamic>>()) {
        if (item['nama_kategori']?.toString() == name) {
          return item['id'].toString();
        }
      }
    }
    throw StateError('Kategori tidak ditemukan.');
  }

  Future<void> _reloadCategories() async {
    final response = await widget.dio.get<Map<String, dynamic>>(
      '/kategori-kegiatans',
    );
    final data = response.data?['data'];
    if (!mounted || data is! List) return;
    final categories = data
        .whereType<Map<String, dynamic>>()
        .map((item) => item['nama_kategori']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    setState(() {
      _categories
        ..clear()
        ..addAll(categories);
    });
    _notifyChanged();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _notifyChanged() {
    widget.onCategoriesChanged?.call(List<String>.from(_categories));
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({
    required this.initialValue,
    required this.isEditing,
    required this.existingCategories,
    required this.editingIndex,
  });

  final String? initialValue;
  final bool isEditing;
  final List<String> existingCategories;
  final int? editingIndex;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1024),
      title: Text(
        widget.isEditing ? 'Edit Kategori' : 'Tambah Kategori',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Nama kategori wajib diisi';
            final exists = widget.existingCategories.asMap().entries.any(
              (entry) =>
                  entry.key != widget.editingIndex &&
                  entry.value.toLowerCase() == text.toLowerCase(),
            );
            if (exists) return 'Kategori sudah ada';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isClosing ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
          onPressed: _isClosing ? null : _submit,
          child: Text(widget.isEditing ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  void _submit() {
    if (_isClosing || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isClosing = true);
    Navigator.pop(context, _controller.text.trim());
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10162F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.18),
          child: const Icon(Icons.sell_outlined, color: Color(0xFFC4B5FD)),
        ),
        title: Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit kategori',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus kategori',
              onPressed: onDelete,
              color: const Color(0xFFFCA5A5),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada kategori',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tekan tombol tambah untuk membuat kategori pertama.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
