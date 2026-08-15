import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_repository.dart';
import 'models/token_pair.dart';
import 'token_repository.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final tokenRepositoryProvider = Provider<TokenRepository>((ref) {
  return TokenRepository(ref.watch(secureStorageProvider));
});

/// Monotonic signal used by the network layer to invalidate UI auth state.
final sessionInvalidationProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenRepo = ref.watch(tokenRepositoryProvider);
  final appConfig = ref.watch(appConfigProvider);
  final client = ApiClient(
    appConfig: appConfig,
    getAccessToken: () => tokenRepo.accessToken,
    onTokenRefresh: () async {
      try {
        final dio = Dio(
          BaseOptions(
            baseUrl: appConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
        final refreshToken = await tokenRepo.loadRefreshToken();
        if (refreshToken == null) {
          return false;
        }
        final response = await dio.post(
          '/api/v1/auth/token/refresh/',
          data: {'refresh': refreshToken},
        );
        final tokens = TokenPair.fromJson(
          response.data as Map<String, dynamic>,
        );
        await tokenRepo.saveTokens(tokens);
        return true;
      } catch (_) {
        await tokenRepo.clearAll();
        ref.read(sessionInvalidationProvider.notifier).state++;
        return false;
      }
    },
  );
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenRepository: ref.watch(tokenRepositoryProvider),
  );
});

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be provided via AppConfigScope');
});
