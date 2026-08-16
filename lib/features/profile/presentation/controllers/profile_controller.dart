import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../auth/domain/auth_status.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_providers.dart';
import '../../domain/account_profile.dart';
import '../../domain/profile_state.dart';

class ProfileController extends Notifier<ProfileState> {
  bool _active = false;
  int _generation = 0;

  @override
  ProfileState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    ref.watch(authControllerProvider);
    return const ProfileInitial();
  }

  Future<void> load() async {
    if (ref.read(authControllerProvider) is! Authenticated) return;
    if (state is ProfileLoading) return;
    final request = ++_generation;
    state = const ProfileLoading();
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (!_active || request != _generation) return;
      state = ProfileLoaded(profile);
    } on ApiError catch (error) {
      if (!_active || request != _generation) return;
      state = ProfileFailure(error.message);
    } catch (_) {
      if (!_active || request != _generation) return;
      state = const ProfileFailure(
        'Profil akun tidak dapat dimuat. Coba lagi.',
      );
    }
  }

  Future<bool> save(AccountProfileUpdate update) async {
    final current = state;
    if (current is! ProfileLoaded || current.isSaving) return false;
    final request = ++_generation;
    state = ProfileLoaded(current.profile, isSaving: true);
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .updateProfile(update);
      if (!_active || request != _generation) return false;
      state = ProfileLoaded(profile, message: 'Profil berhasil diperbarui.');
      return true;
    } on ApiError catch (error) {
      if (!_active || request != _generation) return false;
      state = ProfileLoaded(current.profile, message: error.message);
      return false;
    } catch (_) {
      if (!_active || request != _generation) return false;
      state = ProfileLoaded(
        current.profile,
        message: 'Profil tidak dapat diperbarui. Coba lagi.',
      );
      return false;
    }
  }
}
