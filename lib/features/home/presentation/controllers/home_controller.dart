import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../../screening/data/screening_repository.dart';
import '../../../screening/data/screening_providers.dart';
import '../../domain/home_state.dart';

class HomeController extends Notifier<HomeState> {
  bool _active = false;
  int _generation = 0;

  @override
  HomeState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    final patient = ref.watch(patientControllerProvider);
    if (patient is PatientLinked) {
      Future<void>.microtask(load);
    }
    return const HomeInitial();
  }

  Future<void> load() async {
    if (ref.read(patientControllerProvider) is! PatientLinked) {
      state = const HomeInitial();
      return;
    }
    if (state is HomeLoading) return;
    final request = ++_generation;
    state = const HomeLoading();
    try {
      final result = await ref.read(screeningRepositoryProvider).latest();
      if (!_active || request != _generation) return;
      state = switch (result) {
        LatestAvailable(:final screening) => HomeLatest(screening),
        NoScreening() => const HomeNoScreening(),
      };
    } on ApiError catch (error) {
      if (!_active || request != _generation) return;
      state = HomeFailure(error.message);
    } catch (_) {
      if (!_active || request != _generation) return;
      state = const HomeFailure(
        'Hasil skrining belum dapat dimuat. Coba lagi.',
      );
    }
  }
}
