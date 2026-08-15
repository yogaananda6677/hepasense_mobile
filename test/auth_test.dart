import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/network/auth_interceptor.dart';
import 'package:hepasense_mobile/core/network/refresh_interceptor.dart';
import 'package:hepasense_mobile/core/storage/secure_keys.dart';
import 'package:hepasense_mobile/core/storage/secure_storage.dart';
import 'package:hepasense_mobile/features/auth/data/auth_providers.dart';
import 'package:hepasense_mobile/features/auth/data/auth_repository.dart';
import 'package:hepasense_mobile/features/auth/data/models/auth_user.dart';
import 'package:hepasense_mobile/features/auth/data/models/login_response.dart';
import 'package:hepasense_mobile/features/auth/data/models/register_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/mfa_verify_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/login_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/mfa_verify_response.dart';
import 'package:hepasense_mobile/features/auth/data/models/register_response.dart';
import 'package:hepasense_mobile/features/auth/data/models/token_pair.dart';
import 'package:hepasense_mobile/features/auth/data/token_repository.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';

const _testUser = AuthUser(id: 1, email: 'test@example.com');

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenRepository extends Mock implements TokenRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class Listener {
  final List<(AuthStatus?, AuthStatus)> events = [];

  void call(AuthStatus? previous, AuthStatus next) {
    events.add((previous, next));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const TokenPair(accessToken: 'a', refreshToken: 'r'));
    registerFallbackValue(RequestOptions());
    registerFallbackValue(
      Response(requestOptions: RequestOptions(), data: {}, statusCode: 200),
    );
    registerFallbackValue(SecureStorage());
    registerFallbackValue(LoginRequest(email: '', password: ''));
    registerFallbackValue(
      RegisterRequest(
        email: '',
        password: '',
        passwordConfirm: '',
        firstName: '',
        lastName: '',
        phoneNumber: '',
      ),
    );
    registerFallbackValue(MfaVerifyRequest(challenge: '', otpCode: ''));
  });

  late MockAuthRepository mockAuthRepository;
  late MockTokenRepository mockTokenRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenRepository = MockTokenRepository();

    when(() => mockAuthRepository.refresh(any())).thenAnswer(
      (_) async => const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    when(() => mockTokenRepository.saveTokens(any())).thenAnswer((_) async {});
    when(
      () => mockTokenRepository.loadRefreshToken(),
    ).thenAnswer((_) async => 'r');
  });

  ProviderContainer createContainer({
    AuthRepository? authRepository,
    TokenRepository? tokenRepository,
  }) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? mockAuthRepository,
        ),
        tokenRepositoryProvider.overrideWithValue(
          tokenRepository ?? mockTokenRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthController', () {
    test('initial state is AuthInitial', () {
      final container = createContainer();
      expect(container.read(authControllerProvider), isA<AuthInitial>());
    });

    group('restoreSession', () {
      test('emits AuthUnauthenticated if no refresh token', () async {
        when(
          () => mockTokenRepository.loadRefreshToken(),
        ).thenAnswer((_) async => null);
        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container.read(authControllerProvider.notifier).restoreSession();

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const AuthUnauthenticated()),
        ]);
        expect(
          container.read(authControllerProvider),
          isA<AuthUnauthenticated>(),
        );
        verify(() => mockTokenRepository.loadRefreshToken()).called(1);
        verifyNever(() => mockAuthRepository.refresh(any()));
      });

      test('emits Authenticated if refresh succeeds', () async {
        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container.read(authControllerProvider.notifier).restoreSession();

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const Authenticated(user: null)),
        ]);
        expect(container.read(authControllerProvider), isA<Authenticated>());
        verify(() => mockTokenRepository.loadRefreshToken()).called(1);
        verify(() => mockAuthRepository.refresh('r')).called(1);
        verify(() => mockTokenRepository.saveTokens(any())).called(1);
      });

      test('emits AuthUnauthenticated if refresh fails', () async {
        when(
          () => mockAuthRepository.refresh(any()),
        ).thenThrow(ApiError(code: 'INVALID_REFRESH', message: 'Expired'));
        when(() => mockTokenRepository.clearAll()).thenAnswer((_) async {});

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container.read(authControllerProvider.notifier).restoreSession();

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const AuthUnauthenticated()),
        ]);
        expect(
          container.read(authControllerProvider),
          isA<AuthUnauthenticated>(),
        );
        verify(() => mockTokenRepository.loadRefreshToken()).called(1);
        verify(() => mockAuthRepository.refresh('r')).called(1);
        verify(() => mockTokenRepository.clearAll()).called(1);
        verifyNever(() => mockTokenRepository.saveTokens(any()));
      });
    });

    group('login', () {
      const email = 'test@example.com';
      const password = 'password';

      test('emits Authenticated if login successful (no MFA)', () async {
        when(() => mockAuthRepository.login(any())).thenAnswer(
          (_) async => LoginResponse(
            requiresMfa: false,
            tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
            user: _testUser,
          ),
        );

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container
            .read(authControllerProvider.notifier)
            .login(email, password);

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const Authenticated(user: _testUser)),
        ]);
        expect(container.read(authControllerProvider), isA<Authenticated>());
        verify(() => mockAuthRepository.login(any())).called(1);
        verify(() => mockTokenRepository.saveTokens(any())).called(1);
        verifyNever(() => mockTokenRepository.saveMfaChallenge(any()));
      });

      test(
        'emits AuthMfaRequired if login successful (MFA required)',
        () async {
          when(() => mockAuthRepository.login(any())).thenAnswer(
            (_) async => const LoginResponse(
              requiresMfa: true,
              challenge: 'mfa_challenge',
            ),
          );
          when(
            () => mockTokenRepository.saveMfaChallenge(any()),
          ).thenAnswer((_) async {});

          final container = createContainer();
          final listener = Listener();
          container.listen(authControllerProvider, listener.call);

          await container
              .read(authControllerProvider.notifier)
              .login(email, password);

          expect(listener.events, [
            (const AuthInitial(), const AuthLoading()),
            (
              const AuthLoading(),
              const AuthMfaRequired(challenge: 'mfa_challenge'),
            ),
          ]);
          expect(
            container.read(authControllerProvider),
            isA<AuthMfaRequired>(),
          );
          verify(() => mockAuthRepository.login(any())).called(1);
          verify(
            () => mockTokenRepository.saveMfaChallenge('mfa_challenge'),
          ).called(1);
          verifyNever(() => mockTokenRepository.saveTokens(any()));
        },
      );

      test('emits AuthFailure if login fails', () async {
        when(
          () => mockAuthRepository.login(any()),
        ).thenThrow(ApiError(code: 'INVALID_CREDENTIALS', message: 'Invalid'));

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container
            .read(authControllerProvider.notifier)
            .login(email, password);

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const AuthFailure(message: 'Invalid')),
        ]);
        expect(container.read(authControllerProvider), isA<AuthFailure>());
        verify(() => mockAuthRepository.login(any())).called(1);
        verifyNever(() => mockTokenRepository.saveTokens(any()));
        verifyNever(() => mockTokenRepository.saveMfaChallenge(any()));
      });
    });

    group('register', () {
      test('emits Authenticated if registration successful', () async {
        when(() => mockAuthRepository.register(any())).thenAnswer(
          (_) async => RegisterResponse(
            user: _testUser,
            tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
          ),
        );
        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container
            .read(authControllerProvider.notifier)
            .register(
              const RegisterRequest(
                email: 'a@b.c',
                password: 'pass123',
                passwordConfirm: 'pass123',
                firstName: 'John',
                lastName: 'Doe',
                phoneNumber: '1234567890',
              ),
            );

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const Authenticated(user: _testUser)),
        ]);
        expect(container.read(authControllerProvider), isA<Authenticated>());
        verify(() => mockAuthRepository.register(any())).called(1);
        verify(() => mockTokenRepository.saveTokens(any())).called(1);
      });

      test('emits AuthFailure if registration fails', () async {
        when(
          () => mockAuthRepository.register(any()),
        ).thenThrow(ApiError(code: 'DUPLICATE_EMAIL', message: 'Exists'));

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        await container
            .read(authControllerProvider.notifier)
            .register(
              const RegisterRequest(
                email: 'a@b.c',
                password: 'pass123',
                passwordConfirm: 'pass123',
                firstName: 'John',
                lastName: 'Doe',
                phoneNumber: '1234567890',
              ),
            );

        expect(listener.events, [
          (const AuthInitial(), const AuthLoading()),
          (const AuthLoading(), const AuthFailure(message: 'Exists')),
        ]);
        expect(container.read(authControllerProvider), isA<AuthFailure>());
        verify(() => mockAuthRepository.register(any())).called(1);
        verifyNever(() => mockTokenRepository.saveTokens(any()));
      });
    });

    group('verifyMfa', () {
      const otpCode = '123456';
      const challenge = 'mfa_challenge';

      test('emits Authenticated if MFA verification successful', () async {
        when(() => mockAuthRepository.verifyMfa(any())).thenAnswer(
          (_) async => MfaVerifyResponse(
            user: _testUser,
            tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
          ),
        );
        when(
          () => mockTokenRepository.saveMfaChallenge(any()),
        ).thenAnswer((_) async {});

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        container.read(authControllerProvider.notifier).state =
            const AuthMfaRequired(challenge: challenge);
        await container
            .read(authControllerProvider.notifier)
            .verifyMfa(otpCode);

        expect(listener.events, [
          (const AuthInitial(), const AuthMfaRequired(challenge: challenge)),
          (const AuthMfaRequired(challenge: challenge), const AuthLoading()),
          (const AuthLoading(), const Authenticated(user: _testUser)),
        ]);
        expect(container.read(authControllerProvider), isA<Authenticated>());
        verify(() => mockAuthRepository.verifyMfa(any())).called(1);
        verify(() => mockTokenRepository.saveTokens(any())).called(1);
      });

      test('emits AuthFailure if MFA verification fails', () async {
        when(
          () => mockAuthRepository.verifyMfa(any()),
        ).thenThrow(ApiError(code: 'INVALID_OTP', message: 'Invalid OTP'));

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        container.read(authControllerProvider.notifier).state =
            const AuthMfaRequired(challenge: challenge);
        await container
            .read(authControllerProvider.notifier)
            .verifyMfa(otpCode);

        expect(listener.events, [
          (const AuthInitial(), const AuthMfaRequired(challenge: challenge)),
          (const AuthMfaRequired(challenge: challenge), const AuthLoading()),
          (
            const AuthLoading(),
            const AuthMfaRequired(
              challenge: challenge,
              errorMessage: 'Invalid OTP',
            ),
          ),
        ]);
        expect(container.read(authControllerProvider), isA<AuthMfaRequired>());
        verify(() => mockAuthRepository.verifyMfa(any())).called(1);
        verifyNever(() => mockTokenRepository.saveTokens(any()));
      });
    });

    group('logout', () {
      test('clears session and emits AuthUnauthenticated', () async {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

        final container = createContainer();
        final listener = Listener();
        container.listen(authControllerProvider, listener.call);

        container.read(authControllerProvider.notifier).state =
            const Authenticated(user: null);
        await container.read(authControllerProvider.notifier).logout();

        expect(listener.events, [
          (const AuthInitial(), const Authenticated(user: null)),
          (const Authenticated(user: null), const AuthUnauthenticated()),
        ]);
        expect(
          container.read(authControllerProvider),
          isA<AuthUnauthenticated>(),
        );
        verify(() => mockAuthRepository.logout()).called(1);
      });
    });
  });

  group('AuthRepository', () {
    late AuthRepository authRepository;
    late MockApiClient mockApiClient;
    late MockDio mockDio;

    setUp(() {
      mockApiClient = MockApiClient();
      mockDio = MockDio();
      when(() => mockApiClient.dio).thenReturn(mockDio);
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {'access': 'new_access', 'refresh': 'new_refresh'},
          statusCode: 200,
        ),
      );
      authRepository = AuthRepository(
        apiClient: mockApiClient,
        tokenRepository: mockTokenRepository,
      );
    });

    test('refresh sends correct data and returns TokenPair', () async {
      final result = await authRepository.refresh('old_refresh');

      expect(result.accessToken, 'new_access');
      expect(result.refreshToken, 'new_refresh');
      verify(
        () => mockDio.post(
          '/api/v1/auth/token/refresh/',
          data: {'refresh': 'old_refresh'},
        ),
      ).called(1);
    });
  });

  group('TokenRepository', () {
    late TokenRepository tokenRepository;
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      tokenRepository = TokenRepository(mockSecureStorage);
    });

    test(
      'saveTokens stores refresh token securely and keeps access in memory',
      () async {
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await tokenRepository.saveTokens(
          const TokenPair(accessToken: 'a', refreshToken: 'r'),
        );

        verify(
          () =>
              mockSecureStorage.write(key: SecureKeys.refreshToken, value: 'r'),
        ).called(1);
        expect(tokenRepository.accessToken, 'a');
        expect(tokenRepository.hasRefreshToken, isTrue);
      },
    );

    test('loadRefreshToken loads from secure storage', () async {
      when(
        () => mockSecureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'stored_refresh');

      final token = await tokenRepository.loadRefreshToken();

      expect(token, 'stored_refresh');
      verify(
        () => mockSecureStorage.read(key: SecureKeys.refreshToken),
      ).called(1);
    });

    test('clearAll clears all tokens and challenge', () async {
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenRepository.saveTokens(
        const TokenPair(accessToken: 'a', refreshToken: 'r'),
      );
      await tokenRepository.saveMfaChallenge('challenge');
      await tokenRepository.clearAll();

      expect(tokenRepository.accessToken, '');
      expect(tokenRepository.hasRefreshToken, isFalse);
      expect(tokenRepository.mfaChallenge, isNull);
      verify(
        () => mockSecureStorage.delete(key: SecureKeys.refreshToken),
      ).called(1);
    });

    test('clearTokens clears only tokens', () async {
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenRepository.saveTokens(
        const TokenPair(accessToken: 'a', refreshToken: 'r'),
      );
      await tokenRepository.saveMfaChallenge('challenge');
      await tokenRepository.clearTokens();

      expect(tokenRepository.accessToken, '');
      expect(tokenRepository.hasRefreshToken, isFalse);
      expect(tokenRepository.mfaChallenge, 'challenge');
      verify(
        () => mockSecureStorage.delete(key: SecureKeys.refreshToken),
      ).called(1);
    });
  });

  group('RefreshInterceptor', () {
    late Dio dio;
    late MockHttpClientAdapter adapter;
    late bool failRefresh;
    late bool failRetry;
    late String accessToken;
    late int refreshCount;

    setUp(() {
      adapter = MockHttpClientAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.httpClientAdapter = adapter;
      accessToken = 'old_token';
      failRefresh = false;
      failRetry = false;
      refreshCount = 0;

      dio.interceptors.add(AuthInterceptor(() => accessToken));
      dio.interceptors.add(
        RefreshInterceptor(
          clientDio: dio,
          refreshToken: () async {
            refreshCount++;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            if (failRefresh) {
              return false;
            }
            final response = await dio.post(
              '/api/v1/auth/token/refresh/',
              data: {'refresh': 'old_refresh'},
            );
            accessToken =
                (response.data as Map<String, dynamic>)['access'] as String;
            return true;
          },
        ),
      );

      when(() => adapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        final path = options.path;
        final headers = {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        };
        if (path.contains('/auth/token/refresh/')) {
          return ResponseBody.fromString(
            jsonEncode({'access': 'new_token', 'refresh': 'new_refresh'}),
            200,
            headers: headers,
          );
        }
        final auth = options.headers['Authorization'] as String?;
        if (auth == 'Bearer new_token' && !failRetry) {
          return ResponseBody.fromString(
            jsonEncode({'ok': true}),
            200,
            headers: headers,
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'detail': 'Not authorized.'}),
          401,
          headers: headers,
        );
      });
    });

    test(
      'performs one refresh for concurrent 401s and retries with new token',
      () async {
        final results = await Future.wait([
          dio.get('/api/v1/patients/me/'),
          dio.get('/api/v1/patients/me/'),
          dio.get('/api/v1/patients/me/'),
        ]);

        expect(refreshCount, 1);
        expect(accessToken, 'new_token');
        for (final result in results) {
          expect(result.statusCode, 200);
        }
      },
    );

    test('propagates 401 to all pending requests when refresh fails', () async {
      failRefresh = true;

      await expectLater(
        Future.wait([
          dio.get('/api/v1/patients/me/'),
          dio.get('/api/v1/patients/me/'),
        ]),
        throwsA(isA<DioException>()),
      );
      expect(refreshCount, 1);
      expect(accessToken, 'old_token');
    });

    test('does not refresh for excluded auth endpoints', () async {
      await expectLater(
        dio.post('/api/v1/auth/logout/', data: {'refresh': 'old_token'}),
        throwsA(isA<DioException>()),
      );
      expect(refreshCount, 0);
    });

    test('retries only once per request (no infinite loop)', () async {
      failRetry = true;

      await expectLater(
        dio.get('/api/v1/patients/me/'),
        throwsA(isA<DioException>()),
      );
      expect(refreshCount, 1);
    });
  });
}
