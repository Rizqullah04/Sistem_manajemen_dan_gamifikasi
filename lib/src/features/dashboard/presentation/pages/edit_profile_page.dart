import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MemberProfileData {
  const MemberProfileData({
    required this.fullName,
    required this.nim,
    required this.email,
    required this.phoneNumber,
    required this.faculty,
    required this.studyProgram,
    required this.batchYear,
    required this.ormawa,
    required this.birthDate,
    this.profileImagePath,
  });

  final String fullName;
  final String nim;
  final String email;
  final String phoneNumber;
  final String faculty;
  final String studyProgram;
  final String batchYear;
  final String ormawa;
  final DateTime birthDate;
  final String? profileImagePath;

  MemberProfileData copyWith({
    String? fullName,
    String? nim,
    String? email,
    String? phoneNumber,
    String? faculty,
    String? studyProgram,
    String? batchYear,
    String? ormawa,
    DateTime? birthDate,
    String? profileImagePath,
  }) {
    return MemberProfileData(
      fullName: fullName ?? this.fullName,
      nim: nim ?? this.nim,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      faculty: faculty ?? this.faculty,
      studyProgram: studyProgram ?? this.studyProgram,
      batchYear: batchYear ?? this.batchYear,
      ormawa: ormawa ?? this.ormawa,
      birthDate: birthDate ?? this.birthDate,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    required this.initialData,
    super.key,
  });

  final MemberProfileData initialData;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _backgroundColor = Color(0xFF0B0819);
  static const _surfaceColor = Color(0xFF16122D);
  static const _fieldColor = Color(0xFF120E24);
  static const _primaryColor = Color(0xFF8B5CF6);
  static const _secondaryColor = Color(0xFF6D28D9);

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _fullNameController;
  late final TextEditingController _nimController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _facultyController;
  late final TextEditingController _studyProgramController;
  late final TextEditingController _batchYearController;
  late final TextEditingController _birthDateController;

  late String _selectedOrmawa;
  late DateTime _selectedBirthDate;
  String? _profileImagePath;

  static const List<String> _ormawaOptions = [
    'BEM',
    'HIMA',
    'UKM Musik',
    'UKM Seni',
    'UKM Olahraga',
    'UKM Teater',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    _fullNameController = TextEditingController(text: initial.fullName);
    _nimController = TextEditingController(text: initial.nim);
    _emailController = TextEditingController(text: initial.email);
    _phoneController = TextEditingController(text: initial.phoneNumber);
    _facultyController = TextEditingController(text: initial.faculty);
    _studyProgramController = TextEditingController(text: initial.studyProgram);
    _batchYearController = TextEditingController(text: initial.batchYear);
    _selectedBirthDate = initial.birthDate;
    _birthDateController = TextEditingController(
      text: _formatDate(_selectedBirthDate),
    );
    _selectedOrmawa = initial.ormawa;
    _profileImagePath = initial.profileImagePath;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _studyProgramController.dispose();
    _batchYearController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text(
          'Lengkapi Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Identitas Utama'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _nimController,
                  label: 'NIM',
                  hint: 'Masukkan NIM',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Masukkan email aktif',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Nomor HP',
                  hint: 'Masukkan nomor HP',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Data organisasi, peran, dan poin dikelola oleh sistem dan tidak dapat diubah dari profil.',
                  style: TextStyle(color: Colors.white60, height: 1.4),
                ),
                const SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primaryColor, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: _surfaceColor,
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null
                      ? const Icon(Icons.person_rounded, color: Colors.white, size: 46)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  height: 34,
                  width: 108,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(54),
                    ),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'EDIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library_outlined, color: _primaryColor),
            label: const Text(
              'Unggah foto dari galeri',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: _inputDecoration(label: label, hint: hint),
    );
  }

  Widget _buildOrmawaDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedOrmawa),
      initialValue: _selectedOrmawa,
      dropdownColor: _surfaceColor,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white70,
      decoration: _inputDecoration(
        label: 'Pilih Ormawa',
        hint: 'Pilih organisasi yang diikuti',
      ),
      items: _ormawaOptions
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedOrmawa = value);
      },
    );
  }

  Widget _buildBirthDateField(BuildContext context) {
    return TextFormField(
      controller: _birthDateController,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Tanggal Lahir',
        hint: 'Pilih tanggal lahir',
      ).copyWith(
        suffixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tanggal Lahir wajib diisi';
        }
        return null;
      },
      onTap: () => _selectBirthDate(context),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _secondaryColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.34),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Simpan Perubahan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _primaryColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    if (!mounted) return;
    setState(() => _profileImagePath = image.path);
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primaryColor,
              surface: _surfaceColor,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: _surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() {
      _selectedBirthDate = picked;
      _birthDateController.text = _formatDate(picked);
    });
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      widget.initialData.copyWith(
        fullName: _fullNameController.text.trim(),
        nim: _nimController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        faculty: _facultyController.text.trim(),
        studyProgram: _studyProgramController.text.trim(),
        batchYear: _batchYearController.text.trim(),
        ormawa: _selectedOrmawa,
        birthDate: _selectedBirthDate,
        profileImagePath: _profileImagePath,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
