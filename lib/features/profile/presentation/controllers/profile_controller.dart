import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../auth/domain/auth_status.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_providers.dart';
import '../../domain/account_profile.dart';
import '../../domain/profile_state.dart';

class ProfileController extends Notifier<ProfileState> {
  bool _active = false;

  @override
  ProfileState build() {
    _active = true;
    ref.onDispose(() => _active = false);
    ref.watch(authControllerProvider);
    return const ProfileInitial();
  }

  Future<void> load() async {
    if (ref.read(authControllerProvider) is! Authenticated) return;
    if (state is ProfileLoading) return;
    state = const ProfileLoading();
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (!_active) return;
      state = ProfileLoaded(profile);
    } on ApiError catch (error) {
      state = ProfileFailure(error.message);
    } catch (_) {
      state = const ProfileFailure(
        'Profil akun tidak dapat dimuat. Coba lagi.',
      );
    }
  }

  Future<bool> save(AccountProfileUpdate update) async {
    final current = state;
    if (current is! ProfileLoaded || current.isSaving) return false;
    state = ProfileLoaded(current.profile, isSaving: true);
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .updateProfile(update);
      if (!_active) return false;
      state = ProfileLoaded(profile, message: 'Profil berhasil diperbarui.');
      return true;
    } on ApiError catch (error) {
      state = ProfileLoaded(current.profile, message: error.message);
      return false;
    } catch (_) {
      state = ProfileLoaded(
        current.profile,
        message: 'Profil tidak dapat diperbarui. Coba lagi.',
      );
      return false;
    }
  }
}
