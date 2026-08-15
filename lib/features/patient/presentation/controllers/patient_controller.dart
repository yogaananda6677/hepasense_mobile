import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../auth/domain/auth_status.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/patient_providers.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_state.dart';

class PatientController extends Notifier<PatientState> {
  bool _active = false;

  @override
  PatientState build() {
    _active = true;
    ref.onDispose(() => _active = false);
    final auth = ref.watch(authControllerProvider);
    if (auth is Authenticated) {
      unawaited(Future<void>.microtask(load));
    }
    return const PatientInitial();
  }

  Future<void> load() async {
    if (ref.read(authControllerProvider) is! Authenticated) {
      state = const PatientInitial();
      return;
    }
    if (state is PatientLoading) return;
    state = const PatientLoading();
    try {
      final result = await ref.read(patientRepositoryProvider).getMe();
      if (!_active) return;
      state = switch (result) {
        LinkedPatient(:final patient) => PatientLinked(patient),
        UnlinkedPatient() => const PatientUnlinked(),
      };
    } on ApiError catch (error) {
      if (!_active) return;
      state = PatientFailure(error.message);
    } catch (_) {
      if (!_active) return;
      state = const PatientFailure(
        'Data pasien tidak dapat dimuat. Coba lagi.',
      );
    }
  }
}
