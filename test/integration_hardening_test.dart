import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hepasense_mobile/core/errors/status_mapping.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/widgets/app_bottom_navigation.dart';
import 'package:hepasense_mobile/features/screening/domain/screening.dart';

void main() {
  group('Phase 11 network semantics', () {
    test('429 maps to a safe retry-later message', () {
      final error = ApiError.fromDioException(_dioError(statusCode: 429));
      expect(error.code, 'THROTTLED');
      expect(error.message, contains('Coba lagi'));
    });

    for (final status in [500, 503]) {
      test('$status maps to a non-technical service message', () {
        final error = ApiError.fromDioException(_dioError(statusCode: status));
        expect(error.code, 'SERVER_ERROR');
        expect(error.message, isNot(contains(status.toString())));
      });
    }

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type maps to the consistent timeout message', () {
        final error = ApiError.fromDioException(_dioError(type: type));
        expect(error.code, 'NETWORK_ERROR');
        expect(error.message, 'Koneksi timeout. Periksa jaringan Anda.');
      });
    }
  });

  group('Phase 11 medical display guards', () {
    test('invalid sample cannot retain a risk classification', () {
      expect(
        () => Screening.fromJson(_screeningJson(sampleValid: false)),
        throwsFormatException,
      );
    });

    test('high-risk description explicitly rejects diagnosis semantics', () {
      expect(
        StatusMapping.descriptionFor(ScreenStatus.highRisk).toLowerCase(),
        contains('bukan diagnosis'),
      );
    });

    test('confidence remains a model score and is not coerced', () {
      const result = ScreeningResult(confidenceScore: '0.8750');
      expect(result.confidenceValue, 0.875);
      expect(result.confidenceScore, '0.8750');
    });
  });

  testWidgets('one shared bottom navigation exposes all primary routes', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            bottomNavigationBar: AppBottomNavigation(selectedIndex: 0),
          ),
        ),
        GoRoute(
          path: '/screenings',
          builder: (_, _) => const Scaffold(body: Text('Riwayat target')),
        ),
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('Akun target')),
        ),
        GoRoute(
          path: '/education',
          builder: (_, _) => const Scaffold(body: Text('Gizi target')),
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (_, _) => const Scaffold(body: Text('Chat AI target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Gizi'), findsOneWidget);
    expect(find.text('Chat AI'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat target'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gizi'));
    await tester.pumpAndSettle();
    expect(find.text('Gizi target'), findsOneWidget);
  });
}

DioException _dioError({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final request = RequestOptions(path: '/api/v1/test/');
  return DioException(
    requestOptions: request,
    type: type,
    response: statusCode == null
        ? null
        : Response<void>(requestOptions: request, statusCode: statusCode),
  );
}

Map<String, dynamic> _screeningJson({required bool sampleValid}) => {
  'id': 1,
  'screening_uid': 'screening-1',
  'measured_at': '2026-08-15T10:00:00+07:00',
  'status': 'high_risk',
  'sample_valid': sampleValid,
  'measurement': <String, dynamic>{
    'nh3_corrected': '0.25',
    'nh3_unit': 'ppm',
    'temperature_celsius': '27.00',
    'humidity_percent': '60.00',
    'flow_quality': 'good',
    'expiration_duration_seconds': '8.00',
  },
  'result': <String, dynamic>{
    'classification': 'high_risk',
    'confidence_score': '0.8750',
  },
};
