enum EducationType {
  education('education'),
  nutrition('nutrition'),
  help('help');

  const EducationType(this.apiValue);
  final String apiValue;
}

class EducationCategory {
  const EducationCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.articleCount,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final int? articleCount;

  factory EducationCategory.fromJson(Map<String, dynamic> json) =>
      EducationCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        icon: json['icon']?.toString(),
        articleCount: (json['article_count'] as num?)?.toInt(),
      );
}

class EducationArticle {
  const EducationArticle({
    required this.id,
    required this.type,
    required this.title,
    required this.slug,
    required this.summary,
    required this.thumbnail,
    required this.isFeatured,
    required this.readTimeMinutes,
    required this.publishedAt,
    required this.category,
    this.content,
    this.updatedAt,
  });

  final int id;
  final String type;
  final String title;
  final String slug;
  final String summary;
  final String? thumbnail;
  final bool isFeatured;
  final int readTimeMinutes;
  final String publishedAt;
  final EducationCategory? category;
  final String? content;
  final String? updatedAt;

  factory EducationArticle.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    return EducationArticle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'education',
      title: json['title']?.toString() ?? 'Artikel HepaSense',
      slug: json['slug']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      isFeatured: json['is_featured'] == true,
      readTimeMinutes: (json['read_time_minutes'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at']?.toString() ?? '',
      category: rawCategory is Map<String, dynamic>
          ? EducationCategory.fromJson(rawCategory)
          : null,
      content: json['content']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class EducationPage {
  const EducationPage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<EducationArticle> results;

  bool get hasNext => next != null;

  factory EducationPage.fromJson(Map<String, dynamic> json) => EducationPage(
    count: (json['count'] as num?)?.toInt() ?? 0,
    next: json['next']?.toString(),
    previous: json['previous']?.toString(),
    results: (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EducationArticle.fromJson)
        .toList(growable: false),
  );
}
