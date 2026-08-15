import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';

class ApiClient {
  ApiClient({
    required AppConfig appConfig,
    required String Function() getAccessToken,
    required Future<bool> Function() onTokenRefresh,
    List<Interceptor>? additionalInterceptors,
    Dio? dio,
  }) : _config = appConfig {
    _dio =
        dio ??
        Dio(
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

    _dio.interceptors.addAll([
      AuthInterceptor(getAccessToken),
      RefreshInterceptor(clientDio: _dio, refreshToken: onTokenRefresh),
      ...?additionalInterceptors,
    ]);
  }

  late final Dio _dio;
  final AppConfig _config;

  Dio get dio => _dio;
  AppConfig get config => _config;
}
