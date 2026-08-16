import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/profile_providers.dart';
import '../../domain/password_change_state.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _clearPasswords();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordChangeControllerProvider);
    final submitting = state is PasswordChangeSubmitting;
    ref.listen<PasswordChangeState>(passwordChangeControllerProvider, (
      previous,
      next,
    ) {
      if (next is PasswordChangeSuccess) {
        _clearPasswords();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Perbarui keamanan akun',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Setelah password berhasil diubah, seluruh sesi akan berakhir dan Anda perlu login kembali.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Password saat ini',
                  controller: _oldPassword,
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Password baru',
                  controller: _newPassword,
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Konfirmasi password baru',
                  controller: _confirmation,
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.done,
                  validator: _confirm,
                  onFieldSubmitted: (_) => submitting ? null : _submit(),
                ),
                if (state case PasswordChangeFailure(:final message)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Ubah Password',
                  isLoading: submitting,
                  onPressed: submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.isEmpty ? 'Password wajib diisi.' : null;

  String? _confirm(String? value) {
    if (value == null || value.isEmpty) return 'Konfirmasi wajib diisi.';
    if (value != _newPassword.text) return 'Konfirmasi password tidak cocok.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(passwordChangeControllerProvider.notifier)
        .submit(
          oldPassword: _oldPassword.text,
          newPassword: _newPassword.text,
          newPasswordConfirm: _confirmation.text,
        );
  }

  void _clearPasswords() {
    _oldPassword.clear();
    _newPassword.clear();
    _confirmation.clear();
  }
}
