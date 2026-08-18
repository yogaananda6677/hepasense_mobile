import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_button.dart';
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
      backgroundColor: AppColors.background,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.list(
              children: [
                // Top Header Surface
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Text(
                            'P',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            state.type == EducationType.education
                                ? 'Informasi untuk Anda'
                                : 'Saran Gizi',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.statusHealthy,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.type == EducationType.education
                      ? 'Pelajari informasi kesehatan hati dan penggunaan HepaSense dengan aman.'
                      : 'Rekomendasi dan saran nutrisi harian untuk Anda.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                // Type Switcher SegmentedButton (Edukasi vs Saran Gizi)
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<EducationType>(
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: AppColors.primary,
                          selectedForegroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: EducationType.education,
                            icon: Icon(Icons.menu_book_outlined, size: 16),
                            label: Text(
                              'Edukasi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ButtonSegment(
                            value: EducationType.nutrition,
                            icon: Icon(Icons.restaurant_outlined, size: 16),
                            label: Text(
                              'Saran Gizi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hero Banner ("Penuhi Nutrisi Harian Anda") - shown in Saran Gizi view
                if (state.type == EducationType.nutrition) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Container(
                          height: 115,
                          width: double.infinity,
                          color: AppColors.primary,
                          child: Image.asset(
                            'assets/images/nutrition_hero.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          height: 115,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.heroGradientStart.withOpacity(0.94),
                                AppColors.heroGradientEnd.withOpacity(0.80),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Penuhi Nutrisi Harian Anda',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Pelajari cara menyeimbangkan diet untuk stamina & kesehatan hati maksimal.',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Mulai Belajar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Search Input
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    maxLength: 200,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Cari judul atau ringkasan',
                      hintText: 'Cari artikel gizi..',
                      counterText: '',
                      prefixIcon: const Icon(Icons.search, color: AppColors.outline, size: 20),
                      suffixIcon: state.search.isEmpty
                          ? null
                          : IconButton(
                              iconSize: 18,
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(educationControllerProvider.notifier)
                                    .search('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                    onSubmitted: (value) => ref
                        .read(educationControllerProvider.notifier)
                        .search(value),
                  ),
                ),
                const SizedBox(height: 10),

                // Kategori Utama (Category Filter Carousel)
                Text(
                  'Kategori Utama',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _categoryChip('Semua', null, state.categorySlug),
                      _categoryChip('Pola Makan Sehat', 'pola-makan-sehat', state.categorySlug),
                      _categoryChip('Nutrisi', 'nutrisi', state.categorySlug),
                      for (final category in state.categories)
                        if (category.slug != 'pola-makan-sehat' && category.slug != 'nutrisi')
                          _categoryChip(
                            category.name,
                            category.slug,
                            state.categorySlug,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Advice Card / Information Disclaimer
                _informationCard(state.type),
                const SizedBox(height: 12),

                // Artikel Terbaru Header
                Text(
                  state.search.isEmpty ? 'Artikel terbaru' : 'Hasil pencarian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.separated(
                itemCount: state.items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index < state.items.length) {
                    return _StitchArticleCard(
                      article: state.items[index],
                      index: index,
                    );
                  }
                  return _footer(state);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String? value, String? selected) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        onSelected: (_) =>
            ref.read(educationControllerProvider.notifier).setCategory(value),
      ),
    );
  }

  Widget _informationCard(EducationType type) {
    if (type == EducationType.nutrition) {
      return _doctorAdviceCard();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.statusHealthySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi penting',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'HepaSense adalah alat bantu skrining awal dan bukan pengganti diagnosis tenaga kesehatan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.statusHealthySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saran dari Dokter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Berdasarkan monitoring terakhir',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.outline,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“Berdasarkan kadar kolesterol Anda yang sedikit meningkat minggu ini, kami sarankan untuk meningkatkan asupan serat dari sayuran hijau dan mengurangi penggunaan minyak jenuh.”',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurface,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusHealthySurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Penting',
                        style: TextStyle(
                          color: AppColors.statusHealthy,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '— dr. Sarah Wijaya, Sp.GK',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontStyle: FontStyle.italic,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Informasi gizi umum untuk mendukung pola hidup seimbang.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              fontSize: 9,
            ),
          ),
          Text(
            'Panduan ini bersifat umum, bukan rekomendasi diet personal atau pengobatan.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

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

class _StitchArticleCard extends StatelessWidget {
  const _StitchArticleCard({
    required this.article,
    required this.index,
  });

  final EducationArticle article;
  final int index;

  String _assetImageForIndex() {
    switch (index % 4) {
      case 0:
        return 'assets/images/article_protein.png';
      case 1:
        return 'assets/images/article_lemon.png';
      case 2:
        return 'assets/images/article_spices.png';
      case 3:
      default:
        return 'assets/images/article_hydration.png';
    }
  }

  String _categoryTag() {
    if (article.category?.name.isNotEmpty == true) {
      return article.category!.name.toUpperCase();
    }
    return index % 2 == 0 ? 'NUTRISI' : 'TIPS';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetImageForIndex();
    final readTime = article.readTimeMinutes > 0
        ? '${article.readTimeMinutes} menit baca'
        : '4 menit baca';

    return AppCard(
      padding: EdgeInsets.zero,
      semanticLabel: 'Buka artikel ${article.title}',
      onTap: article.slug.isEmpty
          ? null
          : () => context.push(AppRoutes.educationDetailPath(article.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Article Header Banner Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                Container(
                  height: 125,
                  width: double.infinity,
                  color: AppColors.primarySoft,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 125,
                      color: AppColors.primarySoft,
                      child: const Icon(
                        Icons.restaurant_outlined,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _categoryTag(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Article Content Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
                if (article.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      readTime,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Baca Selengkapnya',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
