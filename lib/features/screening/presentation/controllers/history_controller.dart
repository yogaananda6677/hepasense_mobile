import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/status_mapping.dart';
import '../../../../core/network/api_error.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../data/screening_providers.dart';
import '../../domain/history_state.dart';

class HistoryController extends Notifier<HistoryState> {
  bool _active = false;
  bool _requestInFlight = false;

  @override
  HistoryState build() {
    _active = true;
    ref.onDispose(() => _active = false);
    ref.watch(patientControllerProvider);
    return const HistoryInitial();
  }

  Future<void> loadInitial() async {
    if (ref.read(patientControllerProvider) is! PatientLinked ||
        _requestInFlight) {
      return;
    }
    _requestInFlight = true;
    state = const HistoryLoading();
    try {
      final page = await ref.read(screeningRepositoryProvider).history(page: 1);
      if (!_active) return;
      state = HistoryLoaded(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
      );
    } on ApiError catch (error) {
      if (_active) state = HistoryFailure(error.message);
    } catch (_) {
      if (_active) {
        state = const HistoryFailure(
          'Riwayat pemeriksaan belum dapat dimuat. Coba lagi.',
        );
      }
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! HistoryLoaded || _requestInFlight) return;
    _requestInFlight = true;
    state = current.copyWith(isRefreshing: true, clearNextPageError: true);
    try {
      final page = await ref
          .read(screeningRepositoryProvider)
          .history(page: 1, status: current.filter);
      if (!_active) return;
      state = HistoryLoaded(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
        filter: current.filter,
      );
    } on ApiError catch (error) {
      if (_active) {
        state = current.copyWith(
          isRefreshing: false,
          nextPageError: error.message,
        );
      }
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! HistoryLoaded || !current.hasNext || _requestInFlight) {
      return;
    }
    _requestInFlight = true;
    state = current.copyWith(isLoadingMore: true, clearNextPageError: true);
    try {
      final nextPage = current.page + 1;
      final page = await ref
          .read(screeningRepositoryProvider)
          .history(page: nextPage, status: current.filter);
      if (!_active) return;
      final byId = {for (final item in current.items) item.id: item};
      for (final item in page.results) {
        byId[item.id] = item;
      }
      state = HistoryLoaded(
        items: byId.values.toList(growable: false),
        page: nextPage,
        hasNext: page.hasNext,
        filter: current.filter,
      );
    } on ApiError catch (error) {
      if (_active) {
        state = current.copyWith(
          isLoadingMore: false,
          nextPageError: error.message,
        );
      }
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> setFilter(ScreenStatus? filter) async {
    final current = state;
    if (current is HistoryLoaded && current.filter == filter) return;
    if (_requestInFlight ||
        ref.read(patientControllerProvider) is! PatientLinked) {
      return;
    }
    _requestInFlight = true;
    state = const HistoryLoading();
    try {
      final page = await ref
          .read(screeningRepositoryProvider)
          .history(page: 1, status: filter);
      if (!_active) return;
      state = HistoryLoaded(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
        filter: filter,
      );
    } on ApiError catch (error) {
      if (_active) state = HistoryFailure(error.message);
    } finally {
      _requestInFlight = false;
    }
  }
}
