import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_view.dart';
import '../../data/ai_providers.dart';
import '../../domain/ai_models.dart';
import '../../domain/ai_state.dart';
import '../widgets/ai_composer.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(aiControllerProvider) is AiInitial) {
        ref.read(aiControllerProvider.notifier).loadHistory();
      }
    });
  }

  Future<bool> _startWithMessage(String message) async {
    final id = await ref
        .read(aiControllerProvider.notifier)
        .startConversation(message);
    if (id == null || !mounted) return false;
    context.go(AppRoutes.aiConversationPath(id));
    return true;
  }

  Future<void> _newConversation() async {
    final id = await ref
        .read(aiControllerProvider.notifier)
        .startConversation();
    if (id != null && mounted) context.go(AppRoutes.aiConversationPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tanya AI'),
        actions: [
          IconButton(
            key: const Key('ai-new-conversation'),
            tooltip: 'Percakapan baru',
            onPressed: state is AiReady && !state.isSubmitting
                ? _newConversation
                : null,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: SafeArea(bottom: false, child: _body(state)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
    );
  }

  Widget _body(AiState state) => switch (state) {
    AiInitial() || AiLoading() => const StateView(
      state: ViewState.loading,
      loadingMessage: 'Memuat riwayat percakapan...',
    ),
    AiFailure(:final message) => StateView(
      state: ViewState.error,
      errorMessage: message,
      onRetry: () =>
          ref.read(aiControllerProvider.notifier).loadHistory(refresh: true),
    ),
    AiReady() => Column(
      children: [
        Expanded(child: _history(state)),
        if (state.actionFailure != null)
          _AiErrorBanner(failure: state.actionFailure!),
        AiComposer(isSubmitting: state.isSubmitting, onSend: _startWithMessage),
      ],
    ),
  };

  Widget _history(AiReady state) {
    if (state.conversations.isEmpty) return const _AiLanding();
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(aiControllerProvider.notifier).loadHistory(refresh: true),
      child: ListView.builder(
        key: const Key('ai-conversation-history'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: state.conversations.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Riwayat Percakapan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }
          if (index > state.conversations.length) {
            if (!state.hasNext) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () => ref.read(aiControllerProvider.notifier).loadMore(),
                child: Text(
                  state.isLoadingMore ? 'Memuat…' : 'Muat percakapan lainnya',
                ),
              ),
            );
          }
          final conversation = state.conversations[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ConversationRow(
              conversation: conversation,
              onOpen: () =>
                  context.go(AppRoutes.aiConversationPath(conversation.id)),
              onDelete: () => _confirmDelete(conversation),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(AiConversation conversation) async {
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
      await ref
          .read(aiControllerProvider.notifier)
          .deleteConversation(conversation.id);
    }
  }
}

class _AiLanding extends StatelessWidget {
  const _AiLanding();

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('ai-empty-landing'),
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
    children: [
      Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 34,
            color: AppColors.primary,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'Tanyakan seputar HepaSense',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Dapatkan informasi edukatif tentang skrining dan kesehatan hati.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      const _SafetyNotice(),
      const SizedBox(height: 18),
      Text('Contoh pertanyaan', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final prompt in const [
        'Apa fungsi HepaSense?',
        'Apa arti hasil Waspada?',
        'Bagaimana menjaga kesehatan hati?',
        'Kenapa sampel pemeriksaan bisa tidak valid?',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(prompt),
          ),
        ),
    ],
  );
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.onOpen,
    required this.onDelete,
  });

  final AiConversation conversation;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppCard(
    semanticLabel: 'Buka percakapan ${conversation.title}',
    padding: EdgeInsets.zero,
    onTap: onOpen,
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primary,
        child: Icon(Icons.chat_bubble_outline, size: 19),
      ),
      title: Text(
        conversation.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        JakartaDateTime.display(
          conversation.lastMessageAt ?? conversation.createdAt,
        ),
      ),
      trailing: IconButton(
        tooltip: 'Hapus percakapan',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.infoSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSoft),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tanya AI memberikan informasi edukatif dan tidak menggantikan evaluasi tenaga kesehatan.',
          ),
        ),
      ],
    ),
  );
}

class _AiErrorBanner extends StatelessWidget {
  const _AiErrorBanner({required this.failure});
  final AiFeatureException failure;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      key: Key('ai-error-${failure.kind.name}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.statusWarningSurface,
      child: Text(
        failure.message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
