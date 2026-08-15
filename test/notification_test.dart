import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/notifications/data/notification_providers.dart';
import 'package:hepasense_mobile/features/notifications/data/notification_repository.dart';
import 'package:hepasense_mobile/features/notifications/domain/app_notification.dart';
import 'package:hepasense_mobile/features/notifications/domain/notification_state.dart';
import 'package:hepasense_mobile/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:hepasense_mobile/features/notifications/presentation/pages/notification_page.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class FixedNotificationController extends NotificationController {
  FixedNotificationController(this.value);
  final NotificationState value;
  @override
  NotificationState build() => value;
  @override
  Future<void> loadInitial() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadMore() async {}
  @override
  Future<bool> markRead(int id) async => true;
  @override
  Future<bool> markAllRead() async => true;
}

class FixedUnreadController extends UnreadCountController {
  @override
  UnreadCountState build() => const UnreadCountReady(0);
  @override
  Future<void> load() async {}
}

Map<String, dynamic> notificationJson({
  int id = 1,
  String type = 'warning_result',
  bool read = false,
  int? screeningId = 15,
  String message = 'Hasil pemeriksaan terbaru perlu diperhatikan.',
}) => {
  'id': id,
  'type': type,
  'title': 'Hasil skrining tersedia',
  'message': message,
  'screening_id': screeningId,
  'is_read': read,
  'read_at': read ? '2026-08-13 09:10:00' : null,
  'created_at': '2026-08-13 09:00:00',
  'patient_id': 999,
  'device_credential': 'ignored',
};

AppNotification item({
  int id = 1,
  String type = 'warning_result',
  bool read = false,
  int? screeningId = 15,
  String message = 'Hasil pemeriksaan terbaru perlu diperhatikan.',
}) => AppNotification.fromJson(
  notificationJson(
    id: id,
    type: type,
    read: read,
    screeningId: screeningId,
    message: message,
  ),
);

NotificationPage page(
  List<AppNotification> items, {
  String? next,
  String? previous,
}) => NotificationPage(
  count: items.length,
  next: next,
  previous: previous,
  results: items,
);

void main() {
  group('Notification contract model', () {
    test('maps exact safe fields and nullable screening/read timestamp', () {
      final value = AppNotification.fromJson(
        notificationJson(screeningId: null),
      );
      expect(value.screeningId, isNull);
      expect(value.readAt, isNull);
      expect(value.isRead, isFalse);
    });

    test('unknown future type is retained without enum crash', () {
      expect(item(type: 'future_safe_type').type, 'future_safe_type');
    });

    test('parses DRF pagination envelope', () {
      final value = NotificationPage.fromJson({
        'count': 21,
        'next': 'page=2',
        'previous': null,
        'results': [notificationJson()],
      });
      expect(value.hasNext, isTrue);
      expect(value.results.single.id, 1);
    });
  });

  group('NotificationRepository', () {
    late MockApiClient api;
    late MockDio dio;
    late NotificationRepository repository;

    setUp(() {
      api = MockApiClient();
      dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      repository = NotificationRepository(api);
    });

    test('list uses one canonical paginated request', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/notifications/'),
          data: {'count': 0, 'next': null, 'previous': null, 'results': []},
        ),
      );
      await repository.list(page: 2);
      verify(
        () => dio.get('/api/v1/notifications/', queryParameters: {'page': 2}),
      ).called(1);
    });

    test('fetches authoritative unread count', () async {
      when(() => dio.get('/api/v1/notifications/unread-count/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'unread-count'),
          data: {'unread_count': 7},
        ),
      );
      expect(await repository.unreadCount(), 7);
    });

    test('mark read posts once and returns server object', () async {
      when(() => dio.post('/api/v1/notifications/1/read/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'read'),
          data: notificationJson(read: true),
        ),
      );
      expect((await repository.markRead(1)).isRead, isTrue);
      verify(() => dio.post('/api/v1/notifications/1/read/')).called(1);
    });

    test('mark all uses one supported bulk endpoint', () async {
      when(() => dio.post('/api/v1/notifications/read-all/')).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: 'read-all')),
      );
      await repository.markAllRead();
      verify(() => dio.post('/api/v1/notifications/read-all/')).called(1);
      verifyNoMoreInteractions(dio);
    });

    test('ordinary network failure maps to safe ApiError', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'notifications'),
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(repository.list(page: 1), throwsA(isA<ApiError>()));
    });
  });

  group('NotificationController', () {
    ProviderContainer container(MockNotificationRepository repository) {
      when(() => repository.unreadCount()).thenAnswer((_) async => 0);
      final value = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(value.dispose);
      return value;
    }

    test('success and empty are explicit loaded states', () async {
      final repository = MockNotificationRepository();
      when(() => repository.list(page: 1)).thenAnswer((_) async => page([]));
      final value = container(repository);
      await value.read(notificationControllerProvider.notifier).loadInitial();
      expect(
        (value.read(notificationControllerProvider) as NotificationLoaded)
            .isEmpty,
        isTrue,
      );
    });

    test('initial network failure exposes safe retry state', () async {
      final repository = MockNotificationRepository();
      when(() => repository.list(page: 1)).thenThrow(
        const ApiError(code: 'NETWORK', message: 'Tidak dapat terhubung.'),
      );
      final value = container(repository);
      await value.read(notificationControllerProvider.notifier).loadInitial();
      expect(
        value.read(notificationControllerProvider),
        isA<NotificationFailure>(),
      );
    });

    test('next page appends and deduplicates IDs', () async {
      final repository = MockNotificationRepository();
      when(() => repository.list(page: 1)).thenAnswer(
        (_) async => page([item(id: 1), item(id: 2)], next: 'page=2'),
      );
      when(() => repository.list(page: 2)).thenAnswer(
        (_) async => page([item(id: 2), item(id: 3)], previous: 'page=1'),
      );
      final value = container(repository);
      final controller = value.read(notificationControllerProvider.notifier);
      await controller.loadInitial();
      await controller.loadMore();
      expect(
        (value.read(notificationControllerProvider) as NotificationLoaded).items
            .map((item) => item.id),
        [1, 2, 3],
      );
    });

    test('duplicate load more is prevented', () async {
      final repository = MockNotificationRepository();
      final pending = Completer<NotificationPage>();
      when(
        () => repository.list(page: 1),
      ).thenAnswer((_) async => page([item()], next: 'page=2'));
      when(() => repository.list(page: 2)).thenAnswer((_) => pending.future);
      final value = container(repository);
      final controller = value.read(notificationControllerProvider.notifier);
      await controller.loadInitial();
      final first = controller.loadMore();
      final second = controller.loadMore();
      pending.complete(page([item(id: 2)]));
      await Future.wait([first, second]);
      verify(() => repository.list(page: 2)).called(1);
    });

    test('next-page failure preserves existing notifications', () async {
      final repository = MockNotificationRepository();
      when(
        () => repository.list(page: 1),
      ).thenAnswer((_) async => page([item()], next: 'page=2'));
      when(() => repository.list(page: 2)).thenThrow(
        const ApiError(code: 'NETWORK', message: 'Jaringan bermasalah.'),
      );
      final value = container(repository);
      final controller = value.read(notificationControllerProvider.notifier);
      await controller.loadInitial();
      await controller.loadMore();
      final state =
          value.read(notificationControllerProvider) as NotificationLoaded;
      expect(state.items.single.id, 1);
      expect(state.nextPageError, 'Jaringan bermasalah.');
    });

    test('mark read changes state only after server success', () async {
      final repository = MockNotificationRepository();
      when(
        () => repository.list(page: 1),
      ).thenAnswer((_) async => page([item()]));
      when(
        () => repository.markRead(1),
      ).thenAnswer((_) async => item(read: true));
      final value = container(repository);
      final controller = value.read(notificationControllerProvider.notifier);
      await controller.loadInitial();
      expect(await controller.markRead(1), isTrue);
      expect(
        (value.read(notificationControllerProvider) as NotificationLoaded)
            .items
            .single
            .isRead,
        isTrue,
      );
    });

    test('mark read failure preserves unread server truth', () async {
      final repository = MockNotificationRepository();
      when(
        () => repository.list(page: 1),
      ).thenAnswer((_) async => page([item()]));
      when(
        () => repository.markRead(1),
      ).thenThrow(const ApiError(code: 'NETWORK', message: 'Gagal menandai.'));
      final value = container(repository);
      final controller = value.read(notificationControllerProvider.notifier);
      await controller.loadInitial();
      expect(await controller.markRead(1), isFalse);
      final state =
          value.read(notificationControllerProvider) as NotificationLoaded;
      expect(state.items.single.isRead, isFalse);
      expect(state.mutationError, 'Gagal menandai.');
    });

    test(
      'mark all uses bulk call and updates loaded rows after success',
      () async {
        final repository = MockNotificationRepository();
        when(
          () => repository.list(page: 1),
        ).thenAnswer((_) async => page([item(), item(id: 2)]));
        when(() => repository.markAllRead()).thenAnswer((_) async {});
        final value = container(repository);
        final controller = value.read(notificationControllerProvider.notifier);
        await controller.loadInitial();
        expect(await controller.markAllRead(), isTrue);
        expect(
          (value.read(notificationControllerProvider) as NotificationLoaded)
              .items
              .every((item) => item.isRead),
          isTrue,
        );
        verify(() => repository.markAllRead()).called(1);
      },
    );

    test(
      'provider invalidation clears User A memory before account switch',
      () async {
        final repository = MockNotificationRepository();
        when(
          () => repository.list(page: 1),
        ).thenAnswer((_) async => page([item()]));
        final value = container(repository);
        await value.read(notificationControllerProvider.notifier).loadInitial();
        expect(
          (value.read(notificationControllerProvider) as NotificationLoaded)
              .items,
          isNotEmpty,
        );
        value.invalidate(notificationControllerProvider);
        expect(
          value.read(notificationControllerProvider),
          isA<NotificationInitial>(),
        );
      },
    );
  });

  group('Notification Center widgets', () {
    Future<void> pump(WidgetTester tester, NotificationState state) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            notificationControllerProvider.overrideWith(
              () => FixedNotificationController(state),
            ),
            unreadCountControllerProvider.overrideWith(
              FixedUnreadController.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const NotificationPageView(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders loading, empty, and error retry', (tester) async {
      await pump(tester, const NotificationLoading());
      expect(find.text('Memuat notifikasi...'), findsOneWidget);
      await pump(
        tester,
        const NotificationLoaded(items: [], page: 1, hasNext: false),
      );
      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      await pump(tester, const NotificationFailure('Jaringan bermasalah.'));
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('unread/read styling has semantic text indicator', (
      tester,
    ) async {
      await pump(
        tester,
        NotificationLoaded(
          items: [item(), item(id: 2, read: true)],
          page: 1,
          hasNext: false,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Belum dibaca')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Sudah dibaca')), findsOneWidget);
    });

    testWidgets('null screening and unknown type render without action', (
      tester,
    ) async {
      await pump(
        tester,
        NotificationLoaded(
          items: [item(type: 'future_type', screeningId: null)],
          page: 1,
          hasNext: false,
        ),
      );
      expect(find.text('Hasil skrining tersedia'), findsOneWidget);
      expect(find.text('Buka detail pemeriksaan'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('long message and larger text scale do not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: ProviderScope(
            overrides: [
              notificationControllerProvider.overrideWith(
                () => FixedNotificationController(
                  NotificationLoaded(
                    items: [
                      item(message: List.filled(18, 'Pesan panjang').join(' ')),
                    ],
                    page: 1,
                    hasNext: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const NotificationPageView(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('linked screening navigates to existing detail path', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationPageView(),
          ),
          GoRoute(
            path: '/screenings/:id',
            builder: (_, state) => Text('detail-${state.pathParameters['id']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationControllerProvider.overrideWith(
              () => FixedNotificationController(
                NotificationLoaded(
                  items: [item(read: true)],
                  page: 1,
                  hasNext: false,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Hasil skrining tersedia'));
      await tester.pumpAndSettle();
      expect(find.text('detail-15'), findsOneWidget);
    });
  });
}
