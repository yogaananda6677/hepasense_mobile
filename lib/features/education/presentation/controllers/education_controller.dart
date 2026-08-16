import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../data/education_providers.dart';
import '../../domain/education_content.dart';
import '../../domain/education_state.dart';

class EducationController extends Notifier<EducationState> {
  bool _active = false;
  bool _requestInFlight = false;
  int _generation = 0;
  EducationType _type = EducationType.education;
  String? _category;
  String _search = '';

  @override
  EducationState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    return const EducationInitial();
  }

  Future<void> loadInitial() async {
    if (_requestInFlight) return;
    final request = ++_generation;
    _requestInFlight = true;
    state = const EducationLoading();
    try {
      final repository = ref.read(educationRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.list(
          type: _type,
          page: 1,
          category: _category,
          search: _search,
        ),
        repository.categories(),
      ]);
      if (!_active || request != _generation) return;
      final page = results[0] as EducationPage;
      state = EducationLoaded(
        items: page.results,
        categories: results[1] as List<EducationCategory>,
        page: 1,
        hasNext: page.hasNext,
        type: _type,
        categorySlug: _category,
        search: _search,
      );
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = EducationFailure(error.message);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const EducationFailure(
          'Konten edukasi belum dapat dimuat. Coba lagi.',
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<void> setType(EducationType type) async {
    if (_type == type) return;
    _type = type;
    _category = null;
    _search = '';
    await loadInitial();
  }

  Future<void> setCategory(String? slug) async {
    if (_category == slug) return;
    _category = slug;
    await loadInitial();
  }

  Future<void> search(String value) async {
    final safeValue = value.trim();
    if (safeValue.length > 200 || _search == safeValue) return;
    _search = safeValue;
    await loadInitial();
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! EducationLoaded || _requestInFlight) return;
    final request = ++_generation;
    _requestInFlight = true;
    state = current.copyWith(isRefreshing: true, clearNextPageError: true);
    try {
      final page = await ref
          .read(educationRepositoryProvider)
          .list(type: _type, page: 1, category: _category, search: _search);
      if (!_active || request != _generation) return;
      state = current.copyWith(
        items: page.results,
        page: 1,
        hasNext: page.hasNext,
        isRefreshing: false,
      );
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = current.copyWith(
          isRefreshing: false,
          nextPageError: error.message,
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EducationLoaded || !current.hasNext || _requestInFlight) {
      return;
    }
    final request = _generation;
    _requestInFlight = true;
    state = current.copyWith(isLoadingMore: true, clearNextPageError: true);
    try {
      final nextPage = current.page + 1;
      final page = await ref
          .read(educationRepositoryProvider)
          .list(
            type: _type,
            page: nextPage,
            category: _category,
            search: _search,
          );
      if (!_active || request != _generation) return;
      final byId = {for (final item in current.items) item.id: item};
      for (final item in page.results) {
        byId[item.id] = item;
      }
      state = current.copyWith(
        items: byId.values.toList(growable: false),
        page: nextPage,
        hasNext: page.hasNext,
        isLoadingMore: false,
      );
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = current.copyWith(
          isLoadingMore: false,
          nextPageError: error.message,
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }
}

class ArticleDetailController extends Notifier<ArticleDetailState> {
  bool _active = false;
  int _generation = 0;

  @override
  ArticleDetailState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    return const ArticleDetailInitial();
  }

  Future<void> load(String slug) async {
    final request = ++_generation;
    state = const ArticleDetailLoading();
    try {
      final article = await ref.read(educationRepositoryProvider).detail(slug);
      if (_active && request == _generation) {
        state = ArticleDetailLoaded(article);
      }
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = ArticleDetailFailure(error.message);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const ArticleDetailFailure(
          'Artikel belum dapat dimuat. Coba lagi.',
        );
      }
    }
  }
}

class HelpController extends Notifier<EducationState> {
  bool _active = false;
  bool _requestInFlight = false;
  int _generation = 0;

  @override
  EducationState build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _generation++;
    });
    return const EducationInitial();
  }

  Future<void> load() async {
    if (_requestInFlight) return;
    final request = ++_generation;
    _requestInFlight = true;
    state = const EducationLoading();
    try {
      final page = await ref
          .read(educationRepositoryProvider)
          .list(type: EducationType.help, page: 1);
      if (_active && request == _generation) {
        state = EducationLoaded(
          items: page.results,
          categories: const [],
          page: 1,
          hasNext: page.hasNext,
          type: EducationType.help,
        );
      }
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = EducationFailure(error.message);
      }
    } catch (_) {
      if (_active && request == _generation) {
        state = const EducationFailure(
          'Bantuan belum dapat dimuat. Coba lagi.',
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EducationLoaded || !current.hasNext || _requestInFlight) {
      return;
    }
    final request = _generation;
    _requestInFlight = true;
    state = current.copyWith(isLoadingMore: true, clearNextPageError: true);
    try {
      final nextPage = current.page + 1;
      final page = await ref
          .read(educationRepositoryProvider)
          .list(type: EducationType.help, page: nextPage);
      if (!_active || request != _generation) return;
      final byId = {for (final item in current.items) item.id: item};
      for (final item in page.results) {
        byId[item.id] = item;
      }
      state = current.copyWith(
        items: byId.values.toList(growable: false),
        page: nextPage,
        hasNext: page.hasNext,
        isLoadingMore: false,
      );
    } on ApiError catch (error) {
      if (_active && request == _generation) {
        state = current.copyWith(
          isLoadingMore: false,
          nextPageError: error.message,
        );
      }
    } finally {
      if (request == _generation) _requestInFlight = false;
    }
  }
}
