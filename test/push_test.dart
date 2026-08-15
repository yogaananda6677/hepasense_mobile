import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/features/push/data/push_device_repository.dart';
import 'package:hepasense_mobile/features/push/data/push_service.dart';
import 'package:hepasense_mobile/features/push/domain/push_signal.dart';
import 'package:hepasense_mobile/features/push/presentation/push_coordinator.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockPushDeviceRepository extends Mock implements PushDeviceRepository {}

class FakePushService implements PushService {
  bool initializeResult = true;
  String? fid = 'fid-for-test';
  PushPermission permission = PushPermission.authorized;
  PushSignal? initial;
  int initializeCalls = 0;
  int fidCalls = 0;
  int permissionCalls = 0;
  final foreground = StreamController<PushSignal>.broadcast();
  final opened = StreamController<PushSignal>.broadcast();

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return initializeResult;
  }

  @override
  Future<String?> getInstallationId() async {
    fidCalls++;
    return fid;
  }

  @override
  Future<PushPermission> requestPermission() async {
    permissionCalls++;
    return permission;
  }

  @override
  Stream<PushSignal> get foregroundSignals => foreground.stream;

  @override
  Stream<PushSignal> get openedSignals => opened.stream;

  @override
  Future<PushSignal?> getInitialSignal() async => initial;

  Future<void> close() async {
    await foreground.close();
    await opened.close();
  }
}

void main() {
  group('Firebase production adapter boundary', () {
    test('initializes once before exposing installation ID', () async {
      var initializeCalls = 0;
      var fidCalls = 0;
      final service = FirebasePushService(
        initializeFirebase: () async => initializeCalls++,
        obtainInstallationId: () async {
          fidCalls++;
          return 'test-fid';
        },
        obtainPermission: () async => PushPermission.authorized,
        foregroundData: () => const Stream.empty(),
        openedData: () => const Stream.empty(),
        obtainInitialData: () async => null,
      );
      expect(await service.getInstallationId(), isNull);
      expect(await service.initialize(), isTrue);
      expect(await service.initialize(), isTrue);
      expect(await service.getInstallationId(), 'test-fid');
      expect(initializeCalls, 1);
      expect(fidCalls, 1);
    });

    test(
      'initialization failure is non-fatal and keeps streams inert',
      () async {
        final service = FirebasePushService(
          initializeFirebase: () async => throw Exception('unavailable'),
          obtainInstallationId: () async => throw StateError('must not run'),
          obtainPermission: () async => PushPermission.authorized,
          foregroundData: () => throw StateError('must not run'),
          openedData: () => throw StateError('must not run'),
          obtainInitialData: () async => throw StateError('must not run'),
        );
        expect(await service.initialize(), isFalse);
        expect(await service.getInstallationId(), isNull);
        expect(await service.requestPermission(), PushPermission.unavailable);
        expect(await service.foregroundSignals.isEmpty, isTrue);
      },
    );

    test(
      'permission result is delegated without repeated coordinator prompts',
      () async {
        var permissionCalls = 0;
        final service = FirebasePushService(
          initializeFirebase: () async {},
          obtainInstallationId: () async => 'test-fid',
          obtainPermission: () async {
            permissionCalls++;
            return PushPermission.denied;
          },
          foregroundData: () => const Stream.empty(),
          openedData: () => const Stream.empty(),
          obtainInitialData: () async => null,
        );
        expect(await service.initialize(), isTrue);
        expect(await service.requestPermission(), PushPermission.denied);
        expect(permissionCalls, 1);
      },
    );

    test('maps valid message streams and drops malformed payloads', () async {
      final foreground = StreamController<Map<String, dynamic>>();
      final service = FirebasePushService(
        initializeFirebase: () async {},
        obtainInstallationId: () async => 'test-fid',
        obtainPermission: () async => PushPermission.authorized,
        foregroundData: () => foreground.stream,
        openedData: () => const Stream.empty(),
        obtainInitialData: () async => {
          'notification_id': '8',
          'type': 'screening_ready',
        },
      );
      await service.initialize();
      final received = service.foregroundSignals.first;
      foreground
        ..add({'notification_id': 'bad', 'type': 'warning_result'})
        ..add({'notification_id': '7', 'type': 'future_type'});
      expect((await received).notificationId, 7);
      expect((await service.getInitialSignal())?.notificationId, 8);
      await foreground.close();
    });
  });

  group('Push payload validation', () {
    test('accepts the minimal backend payload', () {
      final signal = PushSignal.fromData({
        'notification_id': '42',
        'type': 'warning_result',
      });
      expect(signal?.notificationId, 42);
      expect(signal?.type, 'warning_result');
    });

    test('unknown future type remains safe', () {
      expect(
        PushSignal.fromData({'notification_id': 1, 'type': 'future_type'}),
        isNotNull,
      );
    });

    test('malformed or missing notification ID is rejected', () {
      expect(PushSignal.fromData({'type': 'warning_result'}), isNull);
      expect(
        PushSignal.fromData({
          'notification_id': 'not-an-id',
          'type': 'warning_result',
        }),
        isNull,
      );
      expect(
        PushSignal.fromData({'notification_id': -1, 'type': 'warning_result'}),
        isNull,
      );
    });

    test('medical payload extras are ignored', () {
      final signal = PushSignal.fromData({
        'notification_id': '7',
        'type': 'high_risk_result',
        'classification': 'healthy',
        'nh3': '999',
        'confidence': '1.0',
      });
      expect(signal?.notificationId, 7);
    });
  });

  group('PushDeviceRepository contract', () {
    test('register sends fid and platform without legacy token', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'push-devices'),
          data: {'id': 3, 'fid_hint': '...12345678'},
        ),
      );
      await PushDeviceRepository(api).register('private-fid');
      final captured =
          verify(
                () => dio.post(
                  '/api/v1/notifications/push-devices/',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {'fid': 'private-fid', 'platform': 'android'});
      expect(captured.containsKey('token'), isFalse);
    });

    test('logout revokes only the registered device ID', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(
        () => dio.delete('/api/v1/notifications/push-devices/3/'),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: 'revoke')),
      );
      await PushDeviceRepository(api).revoke(3);
      verify(
        () => dio.delete('/api/v1/notifications/push-devices/3/'),
      ).called(1);
    });
  });

  group('PushCoordinator', () {
    late FakePushService service;
    late MockPushDeviceRepository repository;
    late List<PushSignal> opens;
    late int refreshes;
    late PushCoordinator coordinator;

    setUp(() {
      service = FakePushService();
      repository = MockPushDeviceRepository();
      opens = [];
      refreshes = 0;
      when(() => repository.register(any())).thenAnswer(
        (_) async =>
            const PushDeviceRegistration(id: 3, fidHint: '...12345678'),
      );
      when(() => repository.revoke(any())).thenAnswer((_) async {});
      coordinator = PushCoordinator(
        service: service,
        repository: repository,
        refreshNotifications: () async => refreshes++,
        onOpen: opens.add,
      );
      addTearDown(() async {
        await coordinator.dispose();
        await service.close();
      });
    });

    test('authenticated session obtains and registers FID', () async {
      await coordinator.onAuthenticated();
      verify(() => repository.register('fid-for-test')).called(1);
      expect(service.fidCalls, 1);
    });

    test('same FID is deduplicated on lifecycle resync', () async {
      await coordinator.onAuthenticated();
      await coordinator.onAuthenticated();
      await coordinator.syncInstallation();
      verify(() => repository.register('fid-for-test')).called(1);
      expect(service.permissionCalls, 1);
    });

    test('changed FID is registered on safe resync', () async {
      await coordinator.onAuthenticated();
      service.fid = 'rotated-fid';
      await coordinator.syncInstallation();
      verify(() => repository.register('rotated-fid')).called(1);
    });

    test('registration failure does not escape or break session', () async {
      when(() => repository.register(any())).thenThrow(Exception('network'));
      await expectLater(coordinator.onAuthenticated(), completes);
      await expectLater(coordinator.syncInstallation(), completes);
    });

    test('Firebase unavailable does not register or prompt', () async {
      service.initializeResult = false;
      await coordinator.onAuthenticated();
      verifyNever(() => repository.register(any()));
      expect(service.permissionCalls, 0);
    });

    test('permission denial is an optional service result', () async {
      service.permission = PushPermission.denied;
      expect(await service.requestPermission(), PushPermission.denied);
      await expectLater(coordinator.onAuthenticated(), completes);
    });

    test('foreground push refreshes canonical notifications only', () async {
      await coordinator.onAuthenticated();
      service.foreground.add(
        const PushSignal(notificationId: 1, type: 'screening_ready'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
      expect(opens, isEmpty);
    });

    test(
      'duplicate pushes only produce refresh signals, not local records',
      () async {
        await coordinator.onAuthenticated();
        const signal = PushSignal(notificationId: 1, type: 'screening_ready');
        service.foreground
          ..add(signal)
          ..add(signal);
        await Future<void>.delayed(Duration.zero);
        expect(refreshes, 2);
        verify(() => repository.register(any())).called(1);
      },
    );

    test('opened push is deferred until authentication is ready', () async {
      await coordinator.initialize();
      service.opened.add(
        const PushSignal(notificationId: 1, type: 'screening_ready'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(opens, isEmpty);
      await coordinator.onAuthenticated();
      expect(opens.single.notificationId, 1);
    });

    test('initial message is delivered only after authentication', () async {
      service.initial = const PushSignal(
        notificationId: 9,
        type: 'warning_result',
      );
      await coordinator.initialize();
      expect(opens, isEmpty);
      await coordinator.onAuthenticated();
      expect(opens.single.notificationId, 9);
    });

    test(
      'logout revokes current backend registration and clears open state',
      () async {
        await coordinator.onAuthenticated();
        await coordinator.onLogout();
        verify(() => repository.revoke(3)).called(1);
        service.opened.add(
          const PushSignal(notificationId: 2, type: 'warning_result'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(opens, isEmpty);
      },
    );

    test(
      'account switch registers again for backend reassignment safety',
      () async {
        await coordinator.onAuthenticated();
        await coordinator.onLogout();
        await coordinator.onAuthenticated();
        verify(() => repository.register('fid-for-test')).called(2);
      },
    );

    test('logout revoke failure does not escape', () async {
      await coordinator.onAuthenticated();
      when(() => repository.revoke(3)).thenThrow(Exception('offline'));
      await expectLater(coordinator.onLogout(), completes);
    });
  });

  test('unconfigured production fallback is inert and safe', () async {
    const service = UnconfiguredPushService();
    expect(await service.initialize(), isFalse);
    expect(await service.getInstallationId(), isNull);
    expect(await service.requestPermission(), PushPermission.unavailable);
    expect(await service.foregroundSignals.isEmpty, isTrue);
  });
}
