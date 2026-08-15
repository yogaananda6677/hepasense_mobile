import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._getAccessToken);

  final String Function() _getAccessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getAccessToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
