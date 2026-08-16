import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/app/router/app_router.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/features/auth/data/auth_providers.dart';
import 'package:hepasense_mobile/features/auth/data/auth_repository.dart';
import 'package:hepasense_mobile/features/auth/data/models/login_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/login_response.dart';
import 'package:hepasense_mobile/features/auth/data/models/token_pair.dart';
import 'package:hepasense_mobile/features/auth/data/token_repository.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenRepository extends Mock implements TokenRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoginRequest(email: '', password: ''));
    registerFallbackValue(const TokenPair(accessToken: '', refreshToken: ''));
  });

  test('login decoder matches the frozen MFA response contract', () {
    final response = LoginResponse.fromJson(const {
      'requires_2fa': true,
      'challenge': 'temporary-challenge',
      'message': 'Password valid. Verifikasi 2FA diperlukan.',
    });

    expect(response.requiresMfa, isTrue);
    expect(response.challenge, 'temporary-challenge');
    expect(response.tokens, isNull);
  });

  group('runtime login routing', () {
    late _MockAuthRepository authRepository;
    late _MockTokenRepository tokenRepository;
    late ProviderContainer container;

    setUp(() {
      authRepository = _MockAuthRepository();
      tokenRepository = _MockTokenRepository();
      when(
        () => tokenRepository.saveMfaChallenge(any()),
      ).thenAnswer((_) async {});
      when(() => tokenRepository.saveTokens(any())).thenAnswer((_) async {});
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          tokenRepositoryProvider.overrideWithValue(tokenRepository),
        ],
      );
      container.read(authControllerProvider.notifier).state =
          const AuthUnauthenticated();
      addTearDown(container.dispose);
    });

    Future<void> pumpLogin(WidgetTester tester) async {
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Masuk ke HepaSense'), findsOneWidget);
    }

    Future<void> enterCredentialsAndSubmit(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'patient@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kata Sandi'),
        'not-persisted',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();
    }

    for (final error in const [
      ApiError(
        code: 'INVALID_CREDENTIALS',
        message: 'Email atau password salah.',
      ),
      ApiError(
        code: 'NETWORK_ERROR',
        message: 'Tidak dapat terhubung ke server.',
      ),
      ApiError(code: 'SERVER_ERROR', message: 'Layanan sedang bermasalah.'),
    ]) {
      testWidgets('${error.code} remains on Login and surfaces its message', (
        tester,
      ) async {
        final response = Completer<LoginResponse>();
        when(
          () => authRepository.login(any()),
        ).thenAnswer((_) => response.future);
        await pumpLogin(tester);

        await enterCredentialsAndSubmit(tester);
        expect(container.read(authControllerProvider), isA<AuthLoading>());
        expect(find.text('Masuk ke HepaSense'), findsOneWidget);

        response.completeError(error);
        await tester.pumpAndSettle();

        expect(find.text(error.message), findsOneWidget);
        final fields = tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        );
        expect(fields.first.controller?.text, 'patient@example.com');
        expect(fields.last.controller?.text, isEmpty);
      });
    }

    testWidgets('MFA response keeps challenge, stores no JWT, and opens OTP', (
      tester,
    ) async {
      final response = Completer<LoginResponse>();
      when(
        () => authRepository.login(any()),
      ).thenAnswer((_) => response.future);
      await pumpLogin(tester);

      await enterCredentialsAndSubmit(tester);
      response.complete(
        const LoginResponse(
          requiresMfa: true,
          challenge: 'temporary-challenge',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi 2FA'), findsOneWidget);
      expect(
        container.read(authControllerProvider),
        const AuthMfaRequired(challenge: 'temporary-challenge'),
      );
      verify(
        () => tokenRepository.saveMfaChallenge('temporary-challenge'),
      ).called(1);
      verifyNever(() => tokenRepository.saveTokens(any()));
    });
  });
}
