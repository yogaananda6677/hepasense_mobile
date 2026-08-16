import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_view.dart';
import '../../data/education_providers.dart';
import '../../domain/education_content.dart';
import '../../domain/education_state.dart';

class EducationPageView extends ConsumerStatefulWidget {
  const EducationPageView({super.key});

  @override
  ConsumerState<EducationPageView> createState() => _EducationPageViewState();
}

class _EducationPageViewState extends ConsumerState<EducationPageView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(educationControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 180) {
      ref.read(educationControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(educationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edukasi')),
      body: SafeArea(child: _body(state)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
    );
  }

  Widget _body(EducationState state) => switch (state) {
    EducationInitial() || EducationLoading() => const StateView(
      state: ViewState.loading,
      loadingMessage: 'Memuat konten edukasi...',
    ),
    EducationFailure(:final message) => StateView(
      state: ViewState.error,
      errorMessage: message,
      onRetry: () =>
          ref.read(educationControllerProvider.notifier).loadInitial(),
    ),
    EducationLoaded() => _loaded(state),
  };

  Widget _loaded(EducationLoaded state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(educationControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.list(
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    state.type == EducationType.education
                        ? 'Informasi untuk Anda'
                        : 'Saran Gizi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  state.type == EducationType.education
                      ? 'Pelajari informasi kesehatan hati dan penggunaan HepaSense dengan aman.'
                      : 'Informasi gizi umum untuk mendukung pola hidup seimbang.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<EducationType>(
                  segments: const [
                    ButtonSegment(
                      value: EducationType.education,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('Edukasi'),
                    ),
                    ButtonSegment(
                      value: EducationType.nutrition,
                      icon: Icon(Icons.restaurant_outlined),
                      label: Text('Saran Gizi'),
                    ),
                  ],
                  selected: {state.type},
                  onSelectionChanged: (value) {
                    _searchController.clear();
                    ref
                        .read(educationControllerProvider.notifier)
                        .setType(value.single);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  maxLength: 200,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Cari judul atau ringkasan',
                    counterText: '',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(educationControllerProvider.notifier)
                                  .search('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onSubmitted: (value) => ref
                      .read(educationControllerProvider.notifier)
                      .search(value),
                ),
                if (state.categories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryChip('Semua', null, state.categorySlug),
                        for (final category in state.categories)
                          _categoryChip(
                            category.name,
                            category.slug,
                            state.categorySlug,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _informationCard(state.type),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.search.isEmpty ? 'Artikel terbaru' : 'Hasil pencarian',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          if (state.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                state: ViewState.empty,
                emptyTitle: 'Belum ada artikel',
                emptyMessage: state.search.isEmpty
                    ? 'Konten yang tersedia akan muncul di sini.'
                    : 'Tidak ada artikel yang cocok dengan pencarian Anda.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList.separated(
                itemCount: state.items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index < state.items.length) {
                    return _ArticleCard(article: state.items[index]);
                  }
                  return _footer(state);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String? value, String? selected) =>
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: FilterChip(
          label: Text(label),
          selected: value == selected,
          onSelected: (_) =>
              ref.read(educationControllerProvider.notifier).setCategory(value),
        ),
      );

  Widget _informationCard(EducationType type) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            type == EducationType.education
                ? Icons.lightbulb_outline
                : Icons.info_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi penting',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                type == EducationType.education
                    ? 'HepaSense adalah alat bantu skrining awal dan bukan pengganti diagnosis tenaga kesehatan.'
                    : 'Panduan ini bersifat umum, bukan rekomendasi diet personal atau pengobatan.',
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _footer(EducationLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.nextPageError != null) {
      return Column(
        children: [
          Text(state.nextPageError!, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'Coba Lagi',
            variant: AppButtonVariant.outline,
            onPressed: () =>
                ref.read(educationControllerProvider.notifier).loadMore(),
          ),
        ],
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final EducationArticle article;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Buka artikel ${article.title}',
    child: AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: article.slug.isEmpty
          ? null
          : () => context.push(AppRoutes.educationDetailPath(article.slug)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 132),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                article.type == 'nutrition'
                    ? Icons.restaurant_outlined
                    : Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.isFeatured)
                    Text(
                      'PILIHAN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      if (article.category?.name.isNotEmpty == true)
                        article.category!.name,
                      if (article.readTimeMinutes > 0)
                        '${article.readTimeMinutes} menit baca',
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}
