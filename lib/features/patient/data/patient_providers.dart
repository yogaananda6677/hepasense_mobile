import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../presentation/controllers/patient_controller.dart';
import '../domain/patient_state.dart';
import 'patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(apiClientProvider));
});

final patientControllerProvider =
    NotifierProvider<PatientController, PatientState>(PatientController.new);
