import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_providers.dart';
import '../../domain/password_change_state.dart';

class PasswordChangeController extends Notifier<PasswordChangeState> {
  bool _active = false;

  @override
  PasswordChangeState build() {
    _active = true;
    ref.onDispose(() => _active = false);
    return const PasswordChangeIdle();
  }

  Future<bool> submit({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    if (state is PasswordChangeSubmitting) return false;
    state = const PasswordChangeSubmitting();
    try {
      final message = await ref
          .read(passwordRepositoryProvider)
          .change(
            oldPassword: oldPassword,
            newPassword: newPassword,
            newPasswordConfirm: newPasswordConfirm,
          );
      if (!_active) return false;
      state = PasswordChangeSuccess(message);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!_active) return true;
      await ref.read(authControllerProvider.notifier).invalidateSession();
      return true;
    } on ApiError catch (error) {
      if (_active) state = PasswordChangeFailure(error.message);
      return false;
    } catch (_) {
      if (_active) {
        state = const PasswordChangeFailure(
          'Password belum dapat diubah. Periksa jaringan dan coba lagi.',
        );
      }
      return false;
    }
  }
}
