class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String role;
  final String content;
  final String createdAt;

  bool get isUser => role == 'user';

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
    id: json['id'] as int,
    role: json['role'] as String,
    content: json['content'] as String,
    createdAt: json['created_at'] as String,
  );
}

class AiConversation {
  const AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.messages = const [],
  });

  final int id;
  final String title;
  final String? lastMessageAt;
  final String createdAt;
  final String updatedAt;
  final List<AiMessage> messages;

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
    id: json['id'] as int,
    title: json['title'] as String,
    lastMessageAt: json['last_message_at'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    messages: (json['messages'] as List<dynamic>? ?? const [])
        .map((item) => AiMessage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class AiConversationPage {
  const AiConversationPage({
    required this.count,
    required this.hasNext,
    required this.results,
  });

  final int count;
  final bool hasNext;
  final List<AiConversation> results;

  factory AiConversationPage.fromJson(Map<String, dynamic> json) =>
      AiConversationPage(
        count: json['count'] as int,
        hasNext: json['next'] != null,
        results: (json['results'] as List<dynamic>)
            .map(
              (item) => AiConversation.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

enum AiFailureKind {
  providerUnavailable,
  rateLimited,
  network,
  notFound,
  other,
}

class AiFeatureException implements Exception {
  const AiFeatureException(this.kind, this.message);

  final AiFailureKind kind;
  final String message;
}
