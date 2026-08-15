import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../data/notification_providers.dart';
import '../../domain/notification_state.dart';

class UnreadCountController extends Notifier<UnreadCountState> {
  bool _active = false;
  bool _requestInFlight = false;
  int _generation = 0;

  @override
  UnreadCountState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    return const UnreadCountInitial();
  }

  Future<void> load() async {
    if (_requestInFlight) return;
    final request = ++_generation;
    _requestInFlight = true;
    if (state is UnreadCountInitial) state = const UnreadCountLoading();
    try {
      final count = await ref
          .read(notificationRepositoryProvider)
          .unreadCount();
      if (_active && request == _generation) {
        state = UnreadCountReady(count);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const UnreadCountFailure();
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }
}

class NotificationController extends Notifier<NotificationState> {
  bool _active = false;
  bool _listRequestInFlight = false;
  int _generation = 0;

  @override
  NotificationState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    return const NotificationInitial();
  }

  Future<void> loadInitial() async {
    if (_listRequestInFlight) return;
    final request = ++_generation;
    _listRequestInFlight = true;
    state = const NotificationLoading();
    try {
      final page = await ref.read(notificationRepositoryProvider).list(page: 1);
      if (!_active || request != _generation) return;
      state = NotificationLoaded(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
      );
      await ref.read(unreadCountControllerProvider.notifier).load();
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = NotificationFailure(error.message);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const NotificationFailure(
          'Notifikasi belum dapat dimuat. Coba lagi.',
        );
      }
    } finally {
      if (request == _generation) _listRequestInFlight = false;
    }
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! NotificationLoaded || _listRequestInFlight) return;
    final request = ++_generation;
    _listRequestInFlight = true;
    state = current.copyWith(
      isRefreshing: true,
      clearNextPageError: true,
      clearMutationError: true,
    );
    try {
      final page = await ref.read(notificationRepositoryProvider).list(page: 1);
      if (!_active || request != _generation) return;
      state = NotificationLoaded(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
      );
      await ref.read(unreadCountControllerProvider.notifier).load();
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = current.copyWith(
          isRefreshing: false,
          mutationError: error.message,
        );
      }
    } finally {
      if (request == _generation) _listRequestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationLoaded ||
        !current.hasNext ||
        _listRequestInFlight) {
      return;
    }
    final request = _generation;
    _listRequestInFlight = true;
    state = current.copyWith(isLoadingMore: true, clearNextPageError: true);
    try {
      final nextPage = current.page + 1;
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(page: nextPage);
      if (!_active || request != _generation) return;
      final byId = {for (final item in current.items) item.id: item};
      for (final item in page.results) {
        byId[item.id] = item;
      }
      state = NotificationLoaded(
        items: byId.values.toList(growable: false),
        page: nextPage,
        hasNext: page.hasNext,
      );
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = current.copyWith(
          isLoadingMore: false,
          nextPageError: error.message,
        );
      }
    } finally {
      if (request == _generation) _listRequestInFlight = false;
    }
  }

  Future<bool> markRead(int id) async {
    final current = state;
    if (current is! NotificationLoaded) return false;
    final item = current.items.where((item) => item.id == id).firstOrNull;
    if (item == null || item.isRead || current.markingReadIds.contains(id)) {
      return item?.isRead ?? false;
    }
    state = current.copyWith(
      markingReadIds: {...current.markingReadIds, id},
      clearMutationError: true,
    );
    try {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .markRead(id);
      if (!_active || state is! NotificationLoaded) return false;
      final latest = state as NotificationLoaded;
      state = latest.copyWith(
        items: latest.items
            .map((item) => item.id == id ? updated : item)
            .toList(growable: false),
        markingReadIds: {...latest.markingReadIds}..remove(id),
      );
      await ref.read(unreadCountControllerProvider.notifier).load();
      return true;
    } on ApiError catch (error) {
      if (_active && state is NotificationLoaded) {
        final latest = state as NotificationLoaded;
        state = latest.copyWith(
          markingReadIds: {...latest.markingReadIds}..remove(id),
          mutationError: error.message,
        );
      }
      return false;
    }
  }

  Future<bool> markAllRead() async {
    final current = state;
    if (current is! NotificationLoaded ||
        current.isMarkingAll ||
        current.visibleUnread == 0) {
      return false;
    }
    state = current.copyWith(isMarkingAll: true, clearMutationError: true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      if (!_active || state is! NotificationLoaded) return false;
      final latest = state as NotificationLoaded;
      state = latest.copyWith(
        items: latest.items
            .map((item) => item.copyWith(isRead: true))
            .toList(growable: false),
        isMarkingAll: false,
      );
      await ref.read(unreadCountControllerProvider.notifier).load();
      return true;
    } on ApiError catch (error) {
      if (_active && state is NotificationLoaded) {
        state = (state as NotificationLoaded).copyWith(
          isMarkingAll: false,
          mutationError: error.message,
        );
      }
      return false;
    }
  }

  void dismissMutationError() {
    final current = state;
    if (current is NotificationLoaded) {
      state = current.copyWith(clearMutationError: true);
    }
  }
}
