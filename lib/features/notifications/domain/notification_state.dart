import 'app_notification.dart';

sealed class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.message);
  final String message;
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded({
    required this.items,
    required this.page,
    required this.hasNext,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
    this.markingReadIds = const {},
    this.nextPageError,
    this.mutationError,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasNext;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMarkingAll;
  final Set<int> markingReadIds;
  final String? nextPageError;
  final String? mutationError;

  bool get isEmpty => items.isEmpty;
  int get visibleUnread => items.where((item) => !item.isRead).length;

  NotificationLoaded copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasNext,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMarkingAll,
    Set<int>? markingReadIds,
    String? nextPageError,
    String? mutationError,
    bool clearNextPageError = false,
    bool clearMutationError = false,
  }) => NotificationLoaded(
    items: items ?? this.items,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isMarkingAll: isMarkingAll ?? this.isMarkingAll,
    markingReadIds: markingReadIds ?? this.markingReadIds,
    nextPageError: clearNextPageError
        ? null
        : nextPageError ?? this.nextPageError,
    mutationError: clearMutationError
        ? null
        : mutationError ?? this.mutationError,
  );
}

sealed class UnreadCountState {
  const UnreadCountState();
}

class UnreadCountInitial extends UnreadCountState {
  const UnreadCountInitial();
}

class UnreadCountLoading extends UnreadCountState {
  const UnreadCountLoading();
}

class UnreadCountReady extends UnreadCountState {
  const UnreadCountReady(this.count);
  final int count;
}

class UnreadCountFailure extends UnreadCountState {
  const UnreadCountFailure();
}
