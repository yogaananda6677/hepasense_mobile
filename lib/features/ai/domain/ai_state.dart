import 'ai_models.dart';

sealed class AiState {
  const AiState();
}

class AiInitial extends AiState {
  const AiInitial();
}

class AiLoading extends AiState {
  const AiLoading();
}

class AiFailure extends AiState {
  const AiFailure(this.kind, this.message);
  final AiFailureKind kind;
  final String message;
}

class AiReady extends AiState {
  const AiReady({
    required this.conversations,
    required this.page,
    required this.hasNext,
    this.active,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.actionFailure,
  });

  final List<AiConversation> conversations;
  final int page;
  final bool hasNext;
  final AiConversation? active;
  final bool isLoadingMore;
  final bool isSubmitting;
  final AiFeatureException? actionFailure;

  AiReady copyWith({
    List<AiConversation>? conversations,
    int? page,
    bool? hasNext,
    AiConversation? active,
    bool clearActive = false,
    bool? isLoadingMore,
    bool? isSubmitting,
    AiFeatureException? actionFailure,
    bool clearActionFailure = false,
  }) => AiReady(
    conversations: conversations ?? this.conversations,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    active: clearActive ? null : active ?? this.active,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    actionFailure: clearActionFailure
        ? null
        : actionFailure ?? this.actionFailure,
  );
}
