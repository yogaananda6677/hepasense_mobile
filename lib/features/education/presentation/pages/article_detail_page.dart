import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/state_view.dart';
import '../../data/education_providers.dart';
import '../../domain/education_state.dart';
import '../widgets/safe_article_body.dart';

class ArticleDetailPage extends ConsumerStatefulWidget {
  const ArticleDetailPage({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends ConsumerState<ArticleDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articleDetailControllerProvider.notifier).load(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleDetailControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Edukasi')),
      body: SafeArea(
        child: switch (state) {
          ArticleDetailInitial() || ArticleDetailLoading() => const StateView(
            state: ViewState.loading,
            loadingMessage: 'Memuat artikel...',
          ),
          ArticleDetailFailure(:final message) => StateView(
            state: ViewState.error,
            errorMessage: message,
            onRetry: () => ref
                .read(articleDetailControllerProvider.notifier)
                .load(widget.slug),
          ),
          ArticleDetailLoaded(:final article) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (article.category?.name.isNotEmpty == true)
                Text(
                  article.category!.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (article.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  article.summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (article.readTimeMinutes > 0)
                    Text('${article.readTimeMinutes} menit baca'),
                  if (article.publishedAt.isNotEmpty)
                    Text(JakartaDateTime.display(article.publishedAt)),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              SafeArticleBody(content: article.content ?? ''),
              const SizedBox(height: AppSpacing.lg),
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
                        'HepaSense merupakan alat bantu skrining awal dan bukan pengganti diagnosis atau konsultasi tenaga kesehatan.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
