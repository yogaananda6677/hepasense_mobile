import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/education_state.dart';
import '../presentation/controllers/education_controller.dart';
import 'education_repository.dart';

final educationRepositoryProvider = Provider<EducationRepository>((ref) {
  return EducationRepository(ref.watch(apiClientProvider));
});

final educationControllerProvider =
    NotifierProvider<EducationController, EducationState>(
      EducationController.new,
    );

final articleDetailControllerProvider =
    NotifierProvider<ArticleDetailController, ArticleDetailState>(
      ArticleDetailController.new,
    );

final helpControllerProvider = NotifierProvider<HelpController, EducationState>(
  HelpController.new,
);
