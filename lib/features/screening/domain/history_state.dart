import '../../../core/errors/status_mapping.dart';
import 'screening.dart';

sealed class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryFailure extends HistoryState {
  const HistoryFailure(this.message);
  final String message;
}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded({
    required this.items,
    required this.page,
    required this.hasNext,
    this.filter,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.nextPageError,
  });

  final List<ScreeningSummary> items;
  final int page;
  final bool hasNext;
  final ScreenStatus? filter;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? nextPageError;

  bool get isEmpty => items.isEmpty;

  HistoryLoaded copyWith({
    List<ScreeningSummary>? items,
    int? page,
    bool? hasNext,
    ScreenStatus? filter,
    bool clearFilter = false,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? nextPageError,
    bool clearNextPageError = false,
  }) => HistoryLoaded(
    items: items ?? this.items,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    filter: clearFilter ? null : filter ?? this.filter,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextPageError: clearNextPageError
        ? null
        : nextPageError ?? this.nextPageError,
  );
}
