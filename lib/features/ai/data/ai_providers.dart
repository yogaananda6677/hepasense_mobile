import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/ai_state.dart';
import '../presentation/controllers/ai_controller.dart';
import 'ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(apiClientProvider));
});

final aiControllerProvider = NotifierProvider<AiController, AiState>(
  AiController.new,
);
