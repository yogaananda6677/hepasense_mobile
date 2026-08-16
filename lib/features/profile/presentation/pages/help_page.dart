import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../education/data/education_providers.dart';
import '../../../education/domain/education_content.dart';
import '../../../education/domain/education_state.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(helpControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) {
      ref.read(helpControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan')),
      body: SafeArea(child: _body(state)),
    );
  }

  Widget _body(EducationState state) => switch (state) {
    EducationInitial() || EducationLoading() => const StateView(
      state: ViewState.loading,
      loadingMessage: 'Memuat bantuan...',
    ),
    EducationFailure(:final message) => StateView(
      state: ViewState.error,
      errorMessage: message,
      onRetry: () => ref.read(helpControllerProvider.notifier).load(),
    ),
    EducationLoaded() => _loaded(state),
  };

  Widget _loaded(EducationLoaded state) => RefreshIndicator(
    onRefresh: () => ref.read(helpControllerProvider.notifier).load(),
    child: ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Informasi penggunaan aplikasi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Temukan panduan resmi yang tersedia untuk menggunakan HepaSense dan memahami status aplikasi.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.isEmpty)
          const SizedBox(
            height: 420,
            child: StateView(
              state: ViewState.empty,
              emptyTitle: 'Belum ada konten bantuan',
              emptyMessage:
                  'Panduan resmi HepaSense yang tersedia akan muncul di sini.',
            ),
          )
        else ...[
          for (final article in state.items) ...[
            _HelpRow(article: article),
            const SizedBox(height: 12),
          ],
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.nextPageError != null) ...[
            Text(state.nextPageError!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Coba Lagi',
              variant: AppButtonVariant.outline,
              onPressed: () =>
                  ref.read(helpControllerProvider.notifier).loadMore(),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bantuan ini tidak memberikan diagnosis. Untuk pertanyaan kesehatan pribadi, konsultasikan dengan tenaga kesehatan.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.article});
  final EducationArticle article;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Buka bantuan ${article.title}',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: const Icon(Icons.help_outline),
        title: Text(article.title),
        subtitle: article.summary.isEmpty ? null : Text(article.summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: article.slug.isEmpty
            ? null
            : () => context.push(AppRoutes.educationDetailPath(article.slug)),
      ),
    ),
  );
}
