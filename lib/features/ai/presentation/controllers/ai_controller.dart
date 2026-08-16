import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/ai_providers.dart';
import '../../domain/ai_models.dart';
import '../../domain/ai_state.dart';

class AiController extends Notifier<AiState> {
  bool _requestInFlight = false;
  int _generation = 0;

  @override
  AiState build() {
    ref.watch(authControllerProvider);
    _generation++;
    _requestInFlight = false;
    return const AiInitial();
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (_requestInFlight) return;
    final current = state;
    if (!refresh && current is AiReady && current.conversations.isNotEmpty) {
      return;
    }
    final request = ++_generation;
    _requestInFlight = true;
    state = const AiLoading();
    try {
      final result = await ref.read(aiRepositoryProvider).list(page: 1);
      if (request != _generation) return;
      state = AiReady(
        conversations: result.results,
        page: 1,
        hasNext: result.hasNext,
      );
    } on AiFeatureException catch (error) {
      if (request == _generation) state = AiFailure(error.kind, error.message);
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AiReady || !current.hasNext || _requestInFlight) return;
    final request = _generation;
    _requestInFlight = true;
    state = current.copyWith(isLoadingMore: true, clearActionFailure: true);
    try {
      final result = await ref
          .read(aiRepositoryProvider)
          .list(page: current.page + 1);
      if (request != _generation) return;
      final merged = {for (final item in current.conversations) item.id: item};
      for (final item in result.results) {
        merged[item.id] = item;
      }
      state = current.copyWith(
        conversations: merged.values.toList(growable: false),
        page: current.page + 1,
        hasNext: result.hasNext,
        isLoadingMore: false,
      );
    } on AiFeatureException catch (error) {
      if (request == _generation) {
        state = current.copyWith(isLoadingMore: false, actionFailure: error);
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<int?> startConversation([String? firstMessage]) async {
    if (_requestInFlight) return null;
    final current = state is AiReady
        ? state as AiReady
        : const AiReady(conversations: [], page: 1, hasNext: false);
    final request = ++_generation;
    _requestInFlight = true;
    state = current.copyWith(isSubmitting: true, clearActionFailure: true);
    try {
      final created = await ref.read(aiRepositoryProvider).create();
      if (request != _generation) return null;
      var next = current.copyWith(
        conversations: [created, ...current.conversations],
        active: created,
        isSubmitting: firstMessage?.trim().isNotEmpty == true,
      );
      state = next;
      if (firstMessage?.trim().isNotEmpty == true) {
        try {
          await ref
              .read(aiRepositoryProvider)
              .send(id: created.id, message: firstMessage!.trim());
          final detail = await ref
              .read(aiRepositoryProvider)
              .detail(created.id);
          if (request != _generation) return null;
          next = _withConversation(
            next,
            detail,
          ).copyWith(active: detail, isSubmitting: false);
          state = next;
        } on AiFeatureException catch (error) {
          if (request == _generation) {
            state = next.copyWith(isSubmitting: false, actionFailure: error);
          }
        }
      }
      return created.id;
    } on AiFeatureException catch (error) {
      if (request == _generation) {
        state = current.copyWith(isSubmitting: false, actionFailure: error);
      }
      return null;
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<void> loadConversation(int id) async {
    final current = state;
    if (current is AiReady && current.active?.id == id) return;
    if (_requestInFlight) return;
    final base = current is AiReady
        ? current
        : const AiReady(conversations: [], page: 1, hasNext: false);
    final request = ++_generation;
    _requestInFlight = true;
    state = base.copyWith(clearActionFailure: true);
    try {
      final detail = await ref.read(aiRepositoryProvider).detail(id);
      if (request != _generation) return;
      state = _withConversation(base, detail).copyWith(active: detail);
    } on AiFeatureException catch (error) {
      if (request == _generation) {
        state = base.copyWith(actionFailure: error, clearActive: true);
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<bool> send(String message) async {
    final current = state;
    final trimmed = message.trim();
    if (current is! AiReady ||
        current.active == null ||
        trimmed.isEmpty ||
        _requestInFlight) {
      return false;
    }
    final request = ++_generation;
    _requestInFlight = true;
    state = current.copyWith(isSubmitting: true, clearActionFailure: true);
    try {
      await ref
          .read(aiRepositoryProvider)
          .send(id: current.active!.id, message: trimmed);
      final detail = await ref
          .read(aiRepositoryProvider)
          .detail(current.active!.id);
      if (request != _generation) return false;
      state = _withConversation(
        current,
        detail,
      ).copyWith(active: detail, isSubmitting: false);
      return true;
    } on AiFeatureException catch (error) {
      if (request == _generation) {
        state = current.copyWith(isSubmitting: false, actionFailure: error);
      }
      return false;
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<bool> deleteConversation(int id) async {
    if (_requestInFlight) return false;
    final current = state;
    if (current is! AiReady) return false;
    final request = ++_generation;
    _requestInFlight = true;
    try {
      await ref.read(aiRepositoryProvider).delete(id);
      if (request != _generation) return false;
      state = current.copyWith(
        conversations: current.conversations
            .where((item) => item.id != id)
            .toList(growable: false),
        clearActive: current.active?.id == id,
        clearActionFailure: true,
      );
      return true;
    } on AiFeatureException catch (error) {
      if (request == _generation) {
        state = current.copyWith(actionFailure: error);
      }
      return false;
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  AiReady _withConversation(AiReady current, AiConversation conversation) {
    final items = [
      conversation,
      ...current.conversations.where((item) => item.id != conversation.id),
    ];
    return current.copyWith(conversations: items);
  }
}
