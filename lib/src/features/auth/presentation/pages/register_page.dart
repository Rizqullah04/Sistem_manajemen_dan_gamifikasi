import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/custom_text_field.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/primary_button.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<_OrmawaOption> _ormawaOptions = [];
  String? _selectedOrmawaId;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingOrmawa = true;
  String? _ormawaErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrmawaOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadOrmawaOptions() async {
    setState(() {
      _isLoadingOrmawa = true;
      _ormawaErrorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ormawas'),
        headers: const {'Accept': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoadingOrmawa = false;
          _ormawaErrorMessage = _readErrorMessage(response.body);
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      final options = data is List
          ? data.whereType<Map<String, dynamic>>().map(_OrmawaOption.fromJson).toList()
          : <_OrmawaOption>[];

      setState(() {
        _ormawaOptions
          ..clear()
          ..addAll(options);
        _selectedOrmawaId = options.length == 1 ? options.first.id : _selectedOrmawaId;
        _isLoadingOrmawa = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingOrmawa = false;
        _ormawaErrorMessage = 'Tidak dapat memuat daftar Ormawa.';
      });
    }
  }

  Future<void> _register() async {
    if (_isLoadingOrmawa) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'id_ormawa': _selectedOrmawaId,
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil, silakan login')),
        );
        context.go('/login');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readErrorMessage(response.body))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat terhubung ke server API. Pastikan Laravel berjalan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _readErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          if (message.toLowerCase() == 'unauthenticated.') {
            return 'Daftar Ormawa belum bisa dimuat. Coba muat ulang.';
          }
          return message;
        }

        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final errors = data['errors'];
          if (errors is Map<String, dynamic> && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      }
    } catch (_) {
      // Fallback below keeps the UI message friendly when API response is not JSON.
    }

    return 'Registrasi gagal, periksa kembali data Anda';
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) return 'Format email tidak valid';
    return null;
  }

  String? _validateOrmawa(String? value) {
    if (value == null || value.isEmpty) return 'Ormawa wajib dipilih';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)');
    if (!regex.hasMatch(value)) {
      return 'Harus ada huruf besar, kecil, dan angka';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Konfirmasi password harus sama';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final formWidth = width > 560 ? 460.0 : double.infinity;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B0F56), Color(0xFF0D0B13)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      tooltip: 'Kembali',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFFFFD66B),
                          size: 32,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Ormawa Awards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Buat Akun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daftarkan akun anggota dan pilih Ormawa tujuan.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Nama lengkap',
                            hintText: 'Masukkan nama lengkap',
                            controller: _nameController,
                            validator: _validateName,
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Email',
                            hintText: 'nama@email.com',
                            controller: _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildOrmawaDropdown(),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Password',
                            hintText: 'Minimal 8 karakter',
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _hidePassword,
                            helperText:
                                'Password minimal 8 karakter, mengandung huruf besar, huruf kecil, dan angka',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Konfirmasi password',
                            hintText: 'Ulangi password',
                            controller: _confirmPasswordController,
                            validator: _validateConfirmPassword,
                            obscureText: _hideConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hideConfirmPassword =
                                    !_hideConfirmPassword,
                              ),
                              icon: Icon(
                                _hideConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Daftar',
                            isLoading: _isLoading,
                            onPressed: _isLoadingOrmawa ? null : _register,
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed:
                                _isLoading ? null : () => context.go('/login'),
                            child: const Text('Sudah punya akun? Login'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrmawaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ormawa',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedOrmawaId,
          validator: _validateOrmawa,
          isExpanded: true,
          dropdownColor: const Color(0xFF22133E),
          style: const TextStyle(color: Colors.white),
          selectedItemBuilder: (context) {
            return _ormawaOptions.map((option) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          decoration: InputDecoration(
            hintText:
                _isLoadingOrmawa ? 'Memuat daftar Ormawa...' : 'Pilih Ormawa',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            helperText: _ormawaErrorMessage ??
                (_ormawaOptions.isEmpty && !_isLoadingOrmawa
                    ? 'Belum ada Ormawa. Admin perlu menambahkan data Ormawa dulu.'
                    : 'Ormawa yang dipilih akan menerima notifikasi pendaftaran Anda'),
            helperStyle: TextStyle(
              color: _ormawaErrorMessage == null
                  ? Colors.white.withValues(alpha: 0.58)
                  : const Color(0xFFFFC0CB),
            ),
            fillColor: Colors.white.withValues(alpha: 0.1),
            errorStyle: const TextStyle(color: Color(0xFFFFC0CB)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFF9F87FF), width: 1.4),
            ),
            suffixIcon: _isLoadingOrmawa
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _loadOrmawaOptions,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Muat ulang Ormawa',
                  ),
          ),
          items: _ormawaOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option.id,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.description.isNotEmpty)
                      Text(
                        option.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.64),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: _isLoadingOrmawa || _ormawaOptions.isEmpty
              ? null
              : (value) => setState(() => _selectedOrmawaId = value),
        ),
      ],
    );
  }
}

class _OrmawaOption {
  const _OrmawaOption({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory _OrmawaOption.fromJson(Map<String, dynamic> json) {
    return _OrmawaOption(
      id: json['id_ormawa']?.toString() ?? '',
      name: json['nama_ormawa']?.toString() ?? '-',
      description: json['deskripsi']?.toString() ?? '',
    );
  }
}
