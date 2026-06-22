import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/custom_button.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/custom_text_field.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/common/widgets/primary_button.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/domain/entities/user_role.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAdminActivationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Silakan hubungi admin kampus untuk aktivasi akun atau SSO.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        switch (next.user!.role) {
          case UserRole.adminFaculty:
            context.go('/admin');
          case UserRole.ormawaAccount:
            context.go('/ormawa');
          case UserRole.memberAccount:
            context.go('/member');
        }
      }

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authControllerProvider);
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
                    Row(
                      children: const [
                        Icon(Icons.emoji_events_outlined,
                            color: Color(0xFFFFD66B), size: 32),
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
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your activities and earn rewards.',
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
                            label: 'Email',
                            hintText: 'Masukkan email',
                            controller: _emailController,
                            validator: validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Password',
                            hintText: 'Input your password',
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            validator: validatePassword,
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
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Log In',
                            isLoading: authState.isLoading,
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              ref.read(authControllerProvider.notifier).login(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                            },
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          CustomButton(
                            label: 'Login with University SSO',
                            isOutlined: true,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'SSO belum diaktifkan. Gunakan akun mock.',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Belum punya akun?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buat akun terlebih dahulu atau hubungi admin untuk mengaktifkan SSO.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: authState.isLoading
                                        ? null
                                        : () => context.push('/register'),
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Buat Akun'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _showAdminActivationMessage,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.support_agent_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Hubungi Admin / Aktifkan SSO',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Privacy Policy'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Terms of Service'),
                        ),
                      ],
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
}
