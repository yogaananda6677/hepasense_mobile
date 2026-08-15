class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.screeningId,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final int? screeningId;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  AppNotification copyWith({bool? isRead, String? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    screeningId: screeningId,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        screeningId: json['screening_id'] as int?,
        isRead: json['is_read'] as bool,
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String,
      );
}

class NotificationPage {
  const NotificationPage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<AppNotification> results;

  bool get hasNext => next != null;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        count: json['count'] as int,
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        results: (json['results'] as List<dynamic>)
            .map(
              (item) => AppNotification.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}
