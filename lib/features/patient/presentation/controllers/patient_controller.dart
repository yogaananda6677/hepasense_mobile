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
  int _generation = 0;

  @override
  PatientState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
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
    final request = ++_generation;
    state = const PatientLoading();
    try {
      final result = await ref.read(patientRepositoryProvider).getMe();
      if (!_active || request != _generation) return;
      state = switch (result) {
        LinkedPatient(:final patient) => PatientLinked(patient),
        UnlinkedPatient() => const PatientUnlinked(),
      };
    } on ApiError catch (error) {
      if (!_active || request != _generation) return;
      state = PatientFailure(error.message);
    } catch (_) {
      if (!_active || request != _generation) return;
      state = const PatientFailure(
        'Data pasien tidak dapat dimuat. Coba lagi.',
      );
    }
  }
}
