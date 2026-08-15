import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../data/screening_providers.dart';
import '../../data/screening_repository.dart';
import '../../domain/detail_state.dart';

class DetailController extends Notifier<DetailState> {
  bool _active = false;
  bool _requestInFlight = false;
  int _generation = 0;
  int? _screeningId;

  @override
  DetailState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    ref.watch(patientControllerProvider);
    return const DetailInitial();
  }

  Future<void> load(int id, {bool refresh = false}) async {
    if (id <= 0 || ref.read(patientControllerProvider) is! PatientLinked) {
      state = const DetailNotFound();
      return;
    }
    if (_requestInFlight && _screeningId == id) return;

    final request = ++_generation;
    _screeningId = id;
    _requestInFlight = true;
    final previous = state;
    state = refresh && previous is DetailLoaded
        ? DetailLoaded(previous.screening, isRefreshing: true)
        : const DetailLoading();
    try {
      final result = await ref.read(screeningRepositoryProvider).detail(id);
      if (!_active || request != _generation) return;
      state = switch (result) {
        ScreeningDetailAvailable(:final screening) => DetailLoaded(screening),
        ScreeningDetailNotFound() => const DetailNotFound(),
      };
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = DetailFailure(error.message);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const DetailFailure(
          'Detail pemeriksaan belum dapat dimuat. Coba lagi.',
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }
}
