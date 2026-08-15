import 'package:dio/dio.dart';

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio clientDio,
    required Future<bool> Function() refreshToken,
  }) : _dio = clientDio,
       _onTokenRefresh = refreshToken;

  static const String _retryHeader = 'x-hepasense-retry';

  static const List<String> _excludedPathFragments = [
    '/auth/login/',
    '/auth/register/',
    '/auth/2fa/',
    '/auth/token/refresh/',
    '/auth/logout/',
  ];

  final Dio _dio;
  final Future<bool> Function() _onTokenRefresh;

  Future<bool>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final canRefresh =
        err.response?.statusCode == 401 &&
        !_isExcluded(options) &&
        _retryCount(options) == 0;
    if (!canRefresh) {
      handler.next(err);
      return;
    }

    final refreshed = await _singleFlightRefresh();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    options.headers[_retryHeader] = 1;
    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _singleFlightRefresh() {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _onTokenRefresh().whenComplete(() => _refreshFuture = null);
    _refreshFuture = future;
    return future;
  }

  bool _isExcluded(RequestOptions options) {
    return _excludedPathFragments.any(options.path.contains);
  }

  int _retryCount(RequestOptions options) =>
      (options.headers[_retryHeader] as int?) ?? 0;
}
