import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/education/data/education_providers.dart';
import 'package:hepasense_mobile/features/education/data/education_repository.dart';
import 'package:hepasense_mobile/features/education/domain/education_content.dart';
import 'package:hepasense_mobile/features/education/domain/education_state.dart';
import 'package:hepasense_mobile/features/education/presentation/controllers/education_controller.dart';
import 'package:hepasense_mobile/features/education/presentation/pages/article_detail_page.dart';
import 'package:hepasense_mobile/features/education/presentation/pages/education_page.dart';
import 'package:hepasense_mobile/features/education/presentation/widgets/safe_article_body.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockEducationRepository extends Mock implements EducationRepository {}

class FixedEducationController extends EducationController {
  FixedEducationController(this.value);
  final EducationState value;

  @override
  EducationState build() => value;

  @override
  Future<void> loadInitial() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadMore() async {}
  @override
  Future<void> setType(EducationType type) async {}
  @override
  Future<void> setCategory(String? slug) async {}
  @override
  Future<void> search(String value) async {}
}

class FixedDetailController extends ArticleDetailController {
  FixedDetailController(this.value);
  final ArticleDetailState value;

  @override
  ArticleDetailState build() => value;

  @override
  Future<void> load(String slug) async {}
}

Map<String, dynamic> articleJson({
  int id = 1,
  String type = 'education',
  String title = 'Memahami skrining HepaSense',
  String slug = 'memahami-skrining',
  String summary = 'Informasi umum yang aman dan mudah dipahami.',
  bool featured = false,
  String? content,
}) => {
  'id': id,
  'type': type,
  'title': title,
  'slug': slug,
  'summary': summary,
  'thumbnail': null,
  'is_featured': featured,
  'read_time_minutes': 3,
  'published_at': '2026-08-12 09:00:00',
  'category': {
    'id': 2,
    'name': 'Kesehatan Hati',
    'slug': 'kesehatan-hati',
    'description': '',
    'icon': null,
  },
  'content': ?content,
  'updated_at': content == null ? null : '2026-08-12 10:00:00',
  'author': 'ignored',
  'patient_id': 99,
};

EducationArticle article({
  String type = 'education',
  String title = 'Memahami skrining HepaSense',
  String summary = 'Informasi umum yang aman dan mudah dipahami.',
  String? content,
}) => EducationArticle.fromJson(
  articleJson(type: type, title: title, summary: summary, content: content),
);

EducationPage page(List<EducationArticle> items, {String? next}) =>
    EducationPage(
      count: items.length,
      next: next,
      previous: null,
      results: items,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(EducationType.education);
  });

  group('Education contract models', () {
    test('maps final safe list fields and ignores unknown fields', () {
      final value = EducationArticle.fromJson(articleJson());
      expect(value.thumbnail, isNull);
      expect(value.readTimeMinutes, 3);
      expect(value.category?.name, 'Kesehatan Hati');
    });

    test('nullable and unknown values are handled safely', () {
      final value = EducationArticle.fromJson({
        'id': 4,
        'type': 'future_type',
        'title': null,
        'slug': 'future',
        'summary': null,
        'category': null,
      });
      expect(value.category, isNull);
      expect(value.title, 'Artikel HepaSense');
      expect(value.type, 'future_type');
    });

    test('parses DRF pagination envelope', () {
      final value = EducationPage.fromJson({
        'count': 21,
        'next': 'page=2',
        'previous': null,
        'results': [articleJson()],
      });
      expect(value.hasNext, isTrue);
      expect(value.results.single.slug, 'memahami-skrining');
    });
  });

  group('EducationRepository', () {
    late MockApiClient api;
    late MockDio dio;
    late EducationRepository repository;

    setUp(() {
      api = MockApiClient();
      dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      repository = EducationRepository(api);
    });

    test('uses only documented list filters and pagination', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'education'),
          data: {'count': 0, 'next': null, 'previous': null, 'results': []},
        ),
      );
      await repository.list(
        type: EducationType.nutrition,
        page: 2,
        category: 'gizi',
        search: 'seimbang',
      );
      verify(
        () => dio.get(
          '/api/v1/education/articles/',
          queryParameters: {
            'type': 'nutrition',
            'page': 2,
            'category': 'gizi',
            'search': 'seimbang',
          },
        ),
      ).called(1);
    });

    test('detail encodes slug and uses canonical endpoint', () async {
      when(() => dio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'detail'),
          data: articleJson(content: '# Informasi'),
        ),
      );
      await repository.detail('aman dibaca');
      verify(
        () => dio.get('/api/v1/education/articles/aman%20dibaca/'),
      ).called(1);
    });

    test('ordinary content failure maps safely', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'education'),
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        repository.list(type: EducationType.education, page: 1),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('EducationController', () {
    ProviderContainer container(MockEducationRepository repository) {
      final value = ProviderContainer(
        overrides: [educationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(value.dispose);
      return value;
    }

    test('success and empty are explicit loaded states', () async {
      final repository = MockEducationRepository();
      when(() => repository.categories()).thenAnswer((_) async => []);
      when(
        () => repository.list(
          type: any(named: 'type'),
          page: any(named: 'page'),
          category: any(named: 'category'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => page([]));
      final value = container(repository);
      await value.read(educationControllerProvider.notifier).loadInitial();
      expect(
        (value.read(educationControllerProvider) as EducationLoaded).isEmpty,
        isTrue,
      );
    });

    test('initial error becomes retryable failure state', () async {
      final repository = MockEducationRepository();
      when(() => repository.categories()).thenAnswer((_) async => []);
      when(
        () => repository.list(
          type: any(named: 'type'),
          page: any(named: 'page'),
          category: any(named: 'category'),
          search: any(named: 'search'),
        ),
      ).thenThrow(const ApiError(code: 'NETWORK', message: 'Jaringan gagal.'));
      final value = container(repository);
      await value.read(educationControllerProvider.notifier).loadInitial();
      expect(value.read(educationControllerProvider), isA<EducationFailure>());
    });

    test('next-page failure preserves existing articles', () async {
      final repository = MockEducationRepository();
      when(() => repository.categories()).thenAnswer((_) async => []);
      when(
        () => repository.list(
          type: EducationType.education,
          page: 1,
          category: null,
          search: '',
        ),
      ).thenAnswer((_) async => page([article()], next: 'page=2'));
      when(
        () => repository.list(
          type: EducationType.education,
          page: 2,
          category: null,
          search: '',
        ),
      ).thenThrow(const ApiError(code: 'SERVER', message: 'Coba lagi.'));
      final value = container(repository);
      final controller = value.read(educationControllerProvider.notifier);
      await controller.loadInitial();
      await controller.loadMore();
      final state = value.read(educationControllerProvider) as EducationLoaded;
      expect(state.items, hasLength(1));
      expect(state.nextPageError, 'Coba lagi.');
    });
  });

  group('Education medical-safe UI', () {
    Widget app({
      required EducationState state,
      Size size = const Size(390, 844),
    }) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        educationControllerProvider.overrideWith(
          () => FixedEducationController(state),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EducationPageView(),
        ),
      ),
    );

    testWidgets('loading, error, and retry render', (tester) async {
      await tester.pumpWidget(app(state: const EducationLoading()));
      expect(find.text('Memuat konten edukasi...'), findsOneWidget);
      await tester.pumpWidget(
        app(state: const EducationFailure('Konten belum tersedia.')),
      );
      expect(find.text('Konten belum tersedia.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets(
      'nutrition uses general wording without personalized inference',
      (tester) async {
        await tester.pumpWidget(
          app(
            state: EducationLoaded(
              items: [article(type: 'nutrition', title: 'Pola makan seimbang')],
              categories: const [],
              page: 1,
              hasNext: false,
              type: EducationType.nutrition,
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text('Informasi gizi umum untuk mendukung pola hidup seimbang.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('rekomendasi diet personal'),
          findsOneWidget,
        );
        expect(find.textContaining('NH3'), findsNothing);
        expect(find.textContaining('Risiko Tinggi'), findsNothing);
        expect(find.textContaining('menyembuhkan'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('long Indonesian content does not overflow at 360 width', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          size: const Size(360, 800),
          state: EducationLoaded(
            items: [
              article(
                title:
                    'Informasi kesehatan hati yang sangat panjang dan perlu dibaca dengan cermat',
                summary:
                    'Informasi ini merupakan penjelasan umum yang panjang, aman, dan harus tetap membungkus secara alami pada layar telepon yang lebih sempit.',
              ),
            ],
            categories: const [],
            page: 1,
            hasNext: false,
            type: EducationType.education,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('article tap integrates detail navigation', (tester) async {
      final router = GoRouter(
        initialLocation: '/education',
        routes: [
          GoRoute(
            path: '/education',
            builder: (_, _) => ProviderScope(
              overrides: [
                educationControllerProvider.overrideWith(
                  () => FixedEducationController(
                    EducationLoaded(
                      items: [article()],
                      categories: const [],
                      page: 1,
                      hasNext: false,
                      type: EducationType.education,
                    ),
                  ),
                ),
              ],
              child: const EducationPageView(),
            ),
          ),
          GoRoute(
            path: '/education/:slug',
            builder: (_, state) =>
                Text('DETAIL ${state.pathParameters['slug']}'),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Memahami skrining HepaSense'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL memahami-skrining'), findsOneWidget);
    });

    testWidgets('production UI contains no plant or marketplace content', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          state: EducationLoaded(
            items: [article()],
            categories: const [],
            page: 1,
            hasNext: false,
            type: EducationType.education,
          ),
        ),
      );
      for (final prohibited in [
        'Plant Guard',
        'Tomato Plant',
        'NPK 16-16-16',
        'Shopee',
        'Tokopedia',
      ]) {
        expect(find.textContaining(prohibited), findsNothing);
      }
    });
  });

  group('Safe article detail', () {
    testWidgets('raw HTML is not created or executed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArticleBody(
              content: '# Informasi\n<script>alert("unsafe")</script>\n- Aman',
            ),
          ),
        ),
      );
      expect(find.text('Informasi'), findsOneWidget);
      expect(find.textContaining('<script>'), findsNothing);
      expect(find.byType(SafeArticleBody), findsOneWidget);
    });

    testWidgets('detail preserves screening disclaimer and safe body', (
      tester,
    ) async {
      final value = article(
        content: '# Informasi umum\nHasil Risiko Tinggi bukan diagnosis.',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            articleDetailControllerProvider.overrideWith(
              () => FixedDetailController(ArticleDetailLoaded(value)),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ArticleDetailPage(slug: 'memahami-skrining'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Hasil Risiko Tinggi bukan diagnosis.'), findsOneWidget);
      expect(find.textContaining('bukan pengganti diagnosis'), findsOneWidget);
      expect(find.textContaining('probabilitas penyakit'), findsNothing);
    });
  });
}
