import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/profile_state.dart';
import '../presentation/controllers/profile_controller.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
