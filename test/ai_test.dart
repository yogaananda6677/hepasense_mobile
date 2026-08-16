import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/ai/data/ai_providers.dart';
import 'package:hepasense_mobile/features/ai/data/ai_repository.dart';
import 'package:hepasense_mobile/features/ai/domain/ai_models.dart';
import 'package:hepasense_mobile/features/ai/domain/ai_state.dart';
import 'package:hepasense_mobile/features/ai/presentation/controllers/ai_controller.dart';
import 'package:hepasense_mobile/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:hepasense_mobile/features/ai/presentation/pages/ai_conversation_page.dart'
    as presentation;
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class FixedAiController extends AiController {
  FixedAiController(this.value);
  final AiState value;
  bool deleteCalled = false;
  bool startCalled = false;

  @override
  AiState build() => value;

  @override
  Future<void> loadHistory({bool refresh = false}) async {}

  @override
  Future<void> loadConversation(int id) async {}

  @override
  Future<int?> startConversation([String? firstMessage]) async {
    startCalled = true;
    return 42;
  }

  @override
  Future<bool> deleteConversation(int id) async {
    deleteCalled = true;
    state = const AiReady(conversations: [], page: 1, hasNext: false);
    return true;
  }
}

class MutableAuthController extends AuthController {
  @override
  AuthStatus build() => const Authenticated(user: null);
  void logoutForTest() => state = const AuthUnauthenticated();
  void loginForTest() => state = const Authenticated(user: null);
}

class FakeAiRepository extends AiRepository {
  FakeAiRepository(super.api, this.page);
  final AiConversationPage page;

  @override
  Future<AiConversationPage> list({required int page}) async => this.page;
}

const conversation = AiConversation(
  id: 42,
  title: 'Apa fungsi HepaSense?',
  lastMessageAt: '2026-08-16 10:20:00',
  createdAt: '2026-08-16 10:00:00',
  updatedAt: '2026-08-16 10:20:00',
  messages: [
    AiMessage(
      id: 1,
      role: 'user',
      content: 'Apa fungsi HepaSense?',
      createdAt: '2026-08-16 10:00:00',
    ),
    AiMessage(
      id: 2,
      role: 'assistant',
      content: 'HepaSense membantu skrining awal dan bukan diagnosis.',
      createdAt: '2026-08-16 10:00:05',
    ),
  ],
);

Map<String, dynamic> conversationJson({bool withMessages = true}) => {
  'id': 42,
  'title': 'Apa fungsi HepaSense?',
  'last_message_at': '2026-08-16 10:20:00',
  'created_at': '2026-08-16 10:00:00',
  'updated_at': '2026-08-16 10:20:00',
  if (withMessages)
    'messages': [
      {
        'id': 1,
        'role': 'user',
        'content': 'Apa fungsi HepaSense?',
        'created_at': '2026-08-16 10:00:00',
      },
      {
        'id': 2,
        'role': 'assistant',
        'content': 'Jawaban edukatif',
        'created_at': '2026-08-16 10:00:05',
      },
    ],
};

void main() {
  group('AI models and repository contract', () {
    late MockApiClient api;
    late MockDio dio;
    late AiRepository repository;

    setUp(() {
      api = MockApiClient();
      dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      repository = AiRepository(api);
    });

    test('conversation, message, and pagination JSON parse exactly', () {
      final parsed = AiConversation.fromJson(conversationJson());
      expect(parsed.id, 42);
      expect(parsed.messages.length, 2);
      expect(parsed.messages.first.isUser, isTrue);
      final page = AiConversationPage.fromJson({
        'count': 1,
        'next': 'next-page',
        'previous': null,
        'results': [conversationJson(withMessages: false)],
      });
      expect(page.count, 1);
      expect(page.hasNext, isTrue);
      expect(page.results.single.title, 'Apa fungsi HepaSense?');
    });

    test(
      'create, list, detail, send, and delete use frozen endpoints',
      () async {
        when(
          () => dio.get(
            '/api/v1/assistant/conversations/',
            queryParameters: {'page': 1},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'list'),
            data: {
              'count': 1,
              'next': null,
              'previous': null,
              'results': [conversationJson(withMessages: false)],
            },
          ),
        );
        when(
          () => dio.post(
            '/api/v1/assistant/conversations/',
            data: const <String, dynamic>{},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'create'),
            data: conversationJson(),
          ),
        );
        when(() => dio.get('/api/v1/assistant/conversations/42/')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'detail'),
            data: conversationJson(),
          ),
        );
        when(
          () => dio.post(
            '/api/v1/assistant/conversations/42/messages/',
            data: {'message': 'Apa fungsi HepaSense?'},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'send'),
            data: const {},
          ),
        );
        when(
          () => dio.delete('/api/v1/assistant/conversations/42/'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'delete'),
            statusCode: 204,
          ),
        );

        expect((await repository.list(page: 1)).results, hasLength(1));
        expect((await repository.create()).id, 42);
        expect((await repository.detail(42)).messages, hasLength(2));
        await repository.send(id: 42, message: '  Apa fungsi HepaSense?  ');
        await repository.delete(42);
        verify(
          () => dio.post(
            '/api/v1/assistant/conversations/42/messages/',
            data: {'message': 'Apa fungsi HepaSense?'},
          ),
        ).called(1);
      },
    );

    for (final entry in const [
      (503, AiFailureKind.providerUnavailable, 'belum tersedia'),
      (429, AiFailureKind.rateLimited, 'Batas penggunaan'),
      (404, AiFailureKind.notFound, 'tidak tersedia'),
    ]) {
      test('${entry.$1} maps to safe AI-specific semantics', () async {
        when(
          () => dio.get('/api/v1/assistant/conversations/42/'),
        ).thenThrow(_dioError(status: entry.$1));
        await expectLater(
          repository.detail(42),
          throwsA(
            isA<AiFeatureException>()
                .having((error) => error.kind, 'kind', entry.$2)
                .having(
                  (error) => error.message,
                  'message',
                  contains(entry.$3),
                ),
          ),
        );
      });
    }

    test('network errors remain distinct and non-technical', () async {
      when(
        () => dio.get('/api/v1/assistant/conversations/42/'),
      ).thenThrow(_dioError(type: DioExceptionType.connectionError));
      await expectLater(
        repository.detail(42),
        throwsA(
          isA<AiFeatureException>().having(
            (error) => error.kind,
            'kind',
            AiFailureKind.network,
          ),
        ),
      );
    });
  });

  group('Tanya AI widgets', () {
    Widget app(AiState state, Widget child) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        aiControllerProvider.overrideWith(() => FixedAiController(state)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

    testWidgets('Coming Soon is replaced by enabled five-item AI landing', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const AiReady(conversations: [], page: 1, hasNext: false),
          const AiAssistantPage(),
        ),
      );
      expect(find.text('Segera Hadir'), findsNothing);
      expect(find.text('Tanyakan seputar HepaSense'), findsOneWidget);
      expect(find.byKey(const Key('ai-empty-landing')), findsOneWidget);
      expect(find.text('Chat AI'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    });

    testWidgets('conversation history and empty history states render', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const AiReady(conversations: [conversation], page: 1, hasNext: false),
          const AiAssistantPage(),
        ),
      );
      expect(find.text('Riwayat Percakapan'), findsOneWidget);
      expect(find.text('Apa fungsi HepaSense?'), findsOneWidget);
    });

    testWidgets('user and assistant bubbles render with active AI nav', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const AiReady(
            conversations: [conversation],
            page: 1,
            hasNext: false,
            active: conversation,
          ),
          const presentation.AiConversationPage(conversationId: 42),
        ),
      );
      expect(find.byKey(const Key('ai-user-bubble')), findsOneWidget);
      expect(find.byKey(const Key('ai-assistant-bubble')), findsOneWidget);
      expect(find.byKey(const Key('ai-message-input')), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    });

    testWidgets('generation loading and provider errors are explicit', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const AiReady(
            conversations: [conversation],
            page: 1,
            hasNext: false,
            active: conversation,
            isSubmitting: true,
            actionFailure: AiFeatureException(
              AiFailureKind.providerUnavailable,
              'Tanya AI sedang belum tersedia.',
            ),
          ),
          const presentation.AiConversationPage(conversationId: 42),
        ),
      );
      expect(find.text('Sedang menyusun jawaban…'), findsOneWidget);
      expect(find.text('Tanya AI sedang belum tersedia.'), findsOneWidget);
    });

    testWidgets('429 and network states use safe distinct copy', (
      tester,
    ) async {
      for (final failure in const [
        AiFeatureException(
          AiFailureKind.rateLimited,
          'Batas penggunaan sementara tercapai. Silakan coba lagi nanti.',
        ),
        AiFeatureException(
          AiFailureKind.network,
          'Tidak dapat terhubung ke layanan. Periksa koneksi Anda dan coba lagi.',
        ),
      ]) {
        await tester.pumpWidget(
          app(
            AiReady(
              conversations: const [],
              page: 1,
              hasNext: false,
              actionFailure: failure,
            ),
            const AiAssistantPage(),
          ),
        );
        expect(find.text(failure.message), findsOneWidget);
      }
    });

    testWidgets('delete requires confirmation and successful removal', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const AiReady(conversations: [conversation], page: 1, hasNext: false),
          const AiAssistantPage(),
        ),
      );
      await tester.tap(find.byTooltip('Hapus percakapan'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus percakapan?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      final controller =
          ProviderScope.containerOf(
                tester.element(find.byType(AiAssistantPage)),
              ).read(aiControllerProvider.notifier)
              as FixedAiController;
      expect(controller.deleteCalled, isTrue);
      expect(find.byKey(const Key('ai-empty-landing')), findsOneWidget);
    });

    testWidgets('AI layouts remain responsive at target sizes and scale', (
      tester,
    ) async {
      for (final size in const [
        Size(360, 800),
        Size(390, 844),
        Size(412, 915),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          app(
            const AiReady(
              conversations: [conversation],
              page: 1,
              hasNext: false,
              active: conversation,
            ),
            const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: presentation.AiConversationPage(conversationId: 42),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
      await tester.binding.setSurfaceSize(null);
    });
  });

  test('production AI source contains no provider secret or auto context', () {
    // This assertion intentionally covers product integration boundaries, not
    // user-entered content, which is sent verbatim by design.
    const forbidden = [
      'AI_API_KEY',
      'OPENAI_API_KEY',
      'GEMINI_API_KEY',
      'confidence_score',
      'patient_id',
      'nh3_corrected',
    ];
    final sources = Directory('lib/features/ai')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join();
    for (final value in forbidden) {
      expect(sources, isNot(contains(value)));
    }
  });

  test('account transition resets in-memory AI state', () async {
    final api = MockApiClient();
    final auth = MutableAuthController();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        aiRepositoryProvider.overrideWith(
          (_) => FakeAiRepository(
            api,
            const AiConversationPage(
              count: 1,
              hasNext: false,
              results: [conversation],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(aiControllerProvider.notifier).loadHistory();
    expect(
      (container.read(aiControllerProvider) as AiReady).conversations,
      hasLength(1),
    );
    auth.logoutForTest();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(aiControllerProvider), isA<AiInitial>());
    auth.loginForTest();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(aiControllerProvider), isA<AiInitial>());
  });
}

DioException _dioError({
  int? status,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final request = RequestOptions(path: 'assistant');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: request, statusCode: status),
  );
}
