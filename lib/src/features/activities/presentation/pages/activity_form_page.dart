import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/error/app_exception.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/entities/activity.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/domain/repositories/activity_repository.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/activities/presentation/providers/activity_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';

class ActivityFormPage extends ConsumerStatefulWidget {
  const ActivityFormPage({super.key, required this.categories, this.activity});

  final List<String> categories;
  final Activity? activity;

  @override
  ConsumerState<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends ConsumerState<ActivityFormPage> {
  static const _maxPhotos = 5;
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _documentationUrlController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  final List<ActivityPhotoUpload> _newPhotos = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity?.title);
    _descriptionController = TextEditingController(
      text: widget.activity?.description,
    );
    _documentationUrlController = TextEditingController(
      text: widget.activity?.documentation,
    );
    _selectedDate = widget.activity?.date ?? DateTime.now();
    final categories = _categories;
    _selectedCategory = categories.contains(widget.activity?.category)
        ? widget.activity!.category
        : categories.first;
  }

  List<String> get _categories =>
      widget.categories.isEmpty ? const ['Tanpa Kategori'] : widget.categories;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _documentationUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isDpm = user?.role == UserRole.adminFaculty;
    final existingPhotos = widget.activity?.documentationPhotos ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kegiatan' : 'Input Kegiatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _PublicationInfoCard(isDpm: isDpm, isEditing: _isEditing),
            const SizedBox(height: 20),
            Text(
              'Informasi kegiatan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul kegiatan',
                prefixIcon: Icon(Icons.event_note_outlined),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Tanggal kegiatan'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isSubmitting ? null : _pickDate,
            ),
            const SizedBox(height: 24),
            Text(
              'Dokumentasi utama',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Unggah maksimal $_maxPhotos foto JPG/PNG, masing-masing maksimal 5 MB.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (existingPhotos.isNotEmpty)
              Text(
                '${existingPhotos.length} foto sebelumnya sudah tersimpan.',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            if (_newPhotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = _newPhotos[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            photo.bytes,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Hapus foto',
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(
                                    () => _newPhotos.removeAt(index),
                                  ),
                            icon: const Icon(Icons.close, size: 17),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_newPhotos.isEmpty ? 'Pilih Foto' : 'Tambah Foto'),
            ),
            const SizedBox(height: 24),
            Text(
              'Dokumentasi lengkap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _documentationUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL Drive/OneDrive (opsional)',
                hintText: 'https://drive.google.com/...',
                prefixIcon: Icon(Icons.link_rounded),
                helperText: 'Pastikan tautan dapat dilihat oleh pemilik link.',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final uri = Uri.tryParse(text);
                if (uri == null ||
                    !uri.hasScheme ||
                    (uri.scheme != 'http' && uri.scheme != 'https')) {
                  return 'Masukkan URL http/https yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.publish_rounded),
          label: Text(
            _isEditing
                ? 'Simpan Perubahan'
                : isDpm
                ? 'Publikasikan Kegiatan'
                : 'Ajukan Kegiatan',
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickPhotos() async {
    final remaining =
        _maxPhotos -
        (widget.activity?.documentationPhotos.length ?? 0) -
        _newPhotos.length;
    if (remaining <= 0) {
      _showMessage('Maksimal $_maxPhotos foto dokumentasi.');
      return;
    }
    final images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (images.isEmpty || !mounted) return;

    for (final image in images.take(remaining)) {
      final bytes = await image.readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        _showMessage('${image.name} melebihi batas 5 MB.');
        continue;
      }
      _newPhotos.add(
        ActivityPhotoUpload(
          bytes: Uint8List.fromList(bytes),
          fileName: image.name,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final hasExistingPhoto =
        widget.activity?.documentationPhotos.isNotEmpty ?? false;
    if (!hasExistingPhoto && _newPhotos.isEmpty) {
      _showMessage('Unggah minimal satu foto dokumentasi kegiatan.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(activityControllerProvider.notifier);
      if (_isEditing) {
        await notifier.update(
          activity: widget.activity!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          documentation: _documentationUrlController.text.trim(),
          category: _selectedCategory,
          photos: _newPhotos,
        );
      } else {
        await notifier.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          documentation: _documentationUrlController.text.trim(),
          category: _selectedCategory,
          photos: _newPhotos,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      _showMessage(error.message);
      if (mounted) setState(() => _isSubmitting = false);
    } catch (_) {
      _showMessage('Kegiatan gagal disimpan.');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PublicationInfoCard extends StatelessWidget {
  const _PublicationInfoCard({required this.isDpm, required this.isEditing});

  final bool isDpm;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(isDpm ? Icons.public_rounded : Icons.fact_check_outlined),
        title: Text(isDpm ? 'Publikasi DPM' : 'Pengajuan Ormawa'),
        subtitle: Text(
          isDpm
              ? 'Kegiatan langsung ditampilkan untuk transparansi dan tidak menghasilkan poin organisasi.'
              : isEditing
              ? 'Perubahan kegiatan akan diajukan kembali untuk diverifikasi DPM.'
              : 'Kegiatan akan tampil setelah diverifikasi oleh DPM.',
        ),
      ),
    );
  }
}
