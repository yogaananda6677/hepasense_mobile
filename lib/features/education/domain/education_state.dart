import 'education_content.dart';

sealed class EducationState {
  const EducationState();
}

class EducationInitial extends EducationState {
  const EducationInitial();
}

class EducationLoading extends EducationState {
  const EducationLoading();
}

class EducationFailure extends EducationState {
  const EducationFailure(this.message);
  final String message;
}

class EducationLoaded extends EducationState {
  const EducationLoaded({
    required this.items,
    required this.categories,
    required this.page,
    required this.hasNext,
    required this.type,
    this.categorySlug,
    this.search = '',
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.nextPageError,
  });

  final List<EducationArticle> items;
  final List<EducationCategory> categories;
  final int page;
  final bool hasNext;
  final EducationType type;
  final String? categorySlug;
  final String search;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? nextPageError;

  bool get isEmpty => items.isEmpty;

  EducationLoaded copyWith({
    List<EducationArticle>? items,
    List<EducationCategory>? categories,
    int? page,
    bool? hasNext,
    EducationType? type,
    String? categorySlug,
    String? search,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? nextPageError,
    bool clearCategory = false,
    bool clearNextPageError = false,
  }) => EducationLoaded(
    items: items ?? this.items,
    categories: categories ?? this.categories,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    type: type ?? this.type,
    categorySlug: clearCategory ? null : categorySlug ?? this.categorySlug,
    search: search ?? this.search,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextPageError: clearNextPageError
        ? null
        : nextPageError ?? this.nextPageError,
  );
}

sealed class ArticleDetailState {
  const ArticleDetailState();
}

class ArticleDetailInitial extends ArticleDetailState {
  const ArticleDetailInitial();
}

class ArticleDetailLoading extends ArticleDetailState {
  const ArticleDetailLoading();
}

class ArticleDetailLoaded extends ArticleDetailState {
  const ArticleDetailLoaded(this.article);
  final EducationArticle article;
}

class ArticleDetailFailure extends ArticleDetailState {
  const ArticleDetailFailure(this.message);
  final String message;
}
