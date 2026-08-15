import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/auth_status.dart';
import '../controllers/auth_controller.dart';

class MfaPage extends ConsumerStatefulWidget {
  const MfaPage({super.key});

  @override
  ConsumerState<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends ConsumerState<MfaPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .verifyMfa(_otpController.text.trim());
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (mounted) setState(() => _isSubmitting = false);
      if (next case AuthMfaRequired(errorMessage: final String message)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } else if (next is Authenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authControllerProvider.notifier).resetToUnauthenticated();
            context.go(AppRoutes.login);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Masukkan Kode Verifikasi',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Masukkan kode verifikasi dari aplikasi autentikator Anda.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Kode OTP',
                  hint: 'Masukkan 6 digit kode',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  controller: _otpController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kode wajib diisi';
                    }
                    if (v.trim().length != 6) {
                      return 'Kode harus 6 digit';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) async => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  onPressed: _isSubmitting ? null : _submit,
                  text: 'Verifikasi',
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    ref
                        .read(authControllerProvider.notifier)
                        .resetToUnauthenticated();
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
