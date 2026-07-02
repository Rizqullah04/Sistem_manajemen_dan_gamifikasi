import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/custom_text_field.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/primary_button.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/config/api_config.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiMessageException(
          _messageFrom(body, 'Email tidak ditemukan.'),
        );
      }

      final data = body['data'];
      final otp = data is Map ? data['otp']?.toString() ?? '1234' : '1234';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP demo: $otp')));
      context.push(
        '/forgot-password/otp',
        extra: {'email': _emailController.text.trim(), 'otp': otp},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthResetScaffold(
      title: 'Lupa Kata Sandi',
      subtitle:
          'Masukkan email akun yang terdaftar untuk mendapatkan OTP demo.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Email',
              hintText: 'Masukkan email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Kirim OTP Demo',
              isLoading: _isLoading,
              onPressed: _requestOtp,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () =>
                        context.canPop() ? context.pop() : context.go('/login'),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({
    required this.email,
    required this.expectedOtp,
    super.key,
  });

  final String email;
  final String expectedOtp;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;
    if (_otpController.text.trim() != widget.expectedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP tidak valid. Gunakan kode 1234.')),
      );
      return;
    }

    context.push(
      '/forgot-password/reset',
      extra: {'email': widget.email, 'otp': _otpController.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthResetScaffold(
      title: 'Verifikasi OTP',
      subtitle: 'Masukkan OTP demo untuk ${widget.email}. Kode demo: 1234.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'OTP',
              hintText: 'Masukkan 1234',
              controller: _otpController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'OTP wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Verifikasi OTP', onPressed: _verifyOtp),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
              child: const Text('Ganti Email'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.email, required this.otp, super.key});

  final String email;
  final String otp;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reset-password'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'otp': widget.otp,
          'password_baru': _passwordController.text,
        }),
      );
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiMessageException(
          _messageFrom(body, 'Password gagal diperbarui.'),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diperbarui.')),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthResetScaffold(
      title: 'Password Baru',
      subtitle: 'Buat kata sandi baru untuk ${widget.email}.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Password Baru',
              hintText: 'Minimal 8 karakter',
              controller: _passwordController,
              obscureText: _hidePassword,
              validator: validatePassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
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
              label: 'Konfirmasi Password',
              hintText: 'Ulangi password baru',
              controller: _confirmPasswordController,
              obscureText: _hidePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password wajib diisi';
                }
                if (value != _passwordController.text) {
                  return 'Konfirmasi password harus sama';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Simpan Password',
              isLoading: _isLoading,
              onPressed: _resetPassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthResetScaffold extends StatelessWidget {
  const _AuthResetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/login'),
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _decodeBody(String body) {
  if (body.isEmpty) return const {};
  final decoded = jsonDecode(body);
  return decoded is Map<String, dynamic> ? decoded : const {};
}

String _messageFrom(Map<String, dynamic> body, String fallback) {
  final message = body['message']?.toString();
  return message == null || message.isEmpty ? fallback : message;
}

String _errorMessage(Object error) {
  if (error is _ApiMessageException) return error.message;
  return 'Tidak dapat terhubung ke server.';
}

class _ApiMessageException implements Exception {
  const _ApiMessageException(this.message);

  final String message;
}
