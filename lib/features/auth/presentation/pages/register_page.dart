import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/register_request.dart';
import '../../domain/auth_status.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .register(
          RegisterRequest(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirm: _confirmPasswordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          ),
        );
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (mounted) setState(() => _isSubmitting = false);
      if (next is AuthFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is Authenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun HepaSense',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Isi data Anda untuk mendaftar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Nama Depan',
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Nama Belakang',
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Nomor Telepon',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Kata Sandi',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Konfirmasi Kata Sandi',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) async => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  onPressed: _isSubmitting ? null : _submit,
                  text: 'Daftar',
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Sudah punya akun? Masuk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
