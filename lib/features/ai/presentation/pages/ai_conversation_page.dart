import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../data/ai_providers.dart';
import '../../domain/ai_models.dart';
import '../../domain/ai_state.dart';
import '../widgets/ai_composer.dart';

class AiConversationPage extends ConsumerStatefulWidget {
  const AiConversationPage({super.key, required this.conversationId});

  final int? conversationId;

  @override
  ConsumerState<AiConversationPage> createState() => _AiConversationPageState();
}

class _AiConversationPageState extends ConsumerState<AiConversationPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.conversationId;
      if (id != null && id > 0) {
        ref.read(aiControllerProvider.notifier).loadConversation(id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _send(String message) async {
    final sent = await ref.read(aiControllerProvider.notifier).send(message);
    if (sent && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
    return sent;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiControllerProvider);
    final active = state is AiReady ? state.active : null;
    final matches = active?.id == widget.conversationId;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(AppRoutes.aiAssistant);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali ke riwayat percakapan',
            onPressed: () => context.go(AppRoutes.aiAssistant),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(matches ? active!.title : 'Tanya AI'),
          actions: [
            IconButton(
              tooltip: 'Percakapan baru',
              onPressed: state is AiReady && !state.isSubmitting
                  ? () async {
                      final id = await ref
                          .read(aiControllerProvider.notifier)
                          .startConversation();
                      if (id != null && context.mounted) {
                        context.go(AppRoutes.aiConversationPath(id));
                      }
                    }
                  : null,
              icon: const Icon(Icons.add_comment_outlined),
            ),
            IconButton(
              key: const Key('ai-delete-active'),
              tooltip: 'Hapus percakapan',
              onPressed: matches ? _confirmDelete : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: _body(state, matches ? active : null),
        ),
        bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
      ),
    );
  }

  Widget _body(AiState state, AiConversation? active) {
    if (widget.conversationId == null || widget.conversationId! <= 0) {
      return _unavailable('Percakapan ini sudah tidak tersedia.');
    }
    if (state case AiReady(
      actionFailure: final error,
    ) when active == null && error != null) {
      return _unavailable(error.message);
    }
    if (active == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ready = state as AiReady;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _ConversationSafetyNotice(),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('ai-message-list'),
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            itemCount: active.messages.length + (ready.isSubmitting ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == active.messages.length) {
                return const _GeneratingIndicator();
              }
              return _MessageBubble(message: active.messages[index]);
            },
          ),
        ),
        if (ready.actionFailure != null)
          _ConversationError(message: ready.actionFailure!.message),
        AiComposer(isSubmitting: ready.isSubmitting, onSend: _send),
      ],
    );
  }

  Widget _unavailable(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(AppRoutes.aiAssistant),
            child: const Text('Kembali ke riwayat'),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmDelete() async {
    final id = widget.conversationId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus percakapan?'),
        content: const Text('Percakapan ini akan dihapus dari riwayat Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final deleted = await ref
          .read(aiControllerProvider.notifier)
          .deleteConversation(id);
      if (deleted && mounted) context.go(AppRoutes.aiAssistant);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AiMessage message;

  @override
  Widget build(BuildContext context) => Semantics(
    label: message.isUser ? 'Pesan Anda' : 'Jawaban Tanya AI',
    child: Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key(message.isUser ? 'ai-user-bubble' : 'ai-assistant-bubble'),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.infoSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser
              ? null
              : Border.all(color: AppColors.borderSoft),
        ),
        child: SelectableText(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.isUser ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    ),
  );
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Chip(
        avatar: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('Sedang menyusun jawaban…'),
      ),
    ),
  );
}

class _ConversationSafetyNotice extends StatelessWidget {
  const _ConversationSafetyNotice();

  @override
  Widget build(BuildContext context) => const Text(
    'Informasi edukatif — bukan pengganti evaluasi medis profesional.',
    textAlign: TextAlign.center,
    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
  );
}

class _ConversationError extends StatelessWidget {
  const _ConversationError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      key: const Key('ai-conversation-error'),
      width: double.infinity,
      color: AppColors.statusWarningSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
