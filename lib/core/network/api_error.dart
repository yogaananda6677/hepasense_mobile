import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? requestId;

  @override
  String toString() => 'ApiError($code): $message';

  static ApiError fromDioException(DioException e) {
    final status = e.response?.statusCode;
    if (status == 429) {
      return const ApiError(
        code: 'THROTTLED',
        message: 'Terlalu banyak percobaan. Coba lagi beberapa saat.',
      );
    }
    if (status != null && status >= 500) {
      return const ApiError(
        code: 'SERVER_ERROR',
        message: 'Layanan sedang bermasalah. Coba lagi beberapa saat.',
      );
    }
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final rawError = data['error'];
      final error = rawError is Map<String, dynamic> ? rawError : null;
      final rawErrors = data['errors'];
      return ApiError(
        code: error?['code']?.toString() ?? 'REQUEST_FAILED',
        message:
            error?['message']?.toString() ??
            data['detail']?.toString() ??
            _validationMessage(rawErrors) ??
            'Permintaan tidak dapat diproses.',
        details: error?['details'] is Map<String, dynamic>
            ? error!['details'] as Map<String, dynamic>
            : rawErrors is Map<String, dynamic>
            ? rawErrors
            : null,
        requestId: error?['request_id']?.toString(),
      );
    }
    return ApiError(
      code: 'NETWORK_ERROR',
      message: _networkErrorMessage(e.type),
    );
  }

  static String? _validationMessage(Object? errors) {
    if (errors is! Map || errors.isEmpty) return null;
    final value = errors.values.first;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value?.toString();
  }

  static String _networkErrorMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      case DioExceptionType.badResponse:
        return 'Respons server tidak valid.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }
}
