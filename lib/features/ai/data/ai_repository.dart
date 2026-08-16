import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'package:hepasense_mobile/features/ai/domain/ai_models.dart';

class AiRepository {
  AiRepository(this._api);

  final ApiClient _api;
  static const _base = '/api/v1/assistant/conversations/';

  Future<AiConversationPage> list({required int page}) async {
    try {
      final response = await _api.dio.get(
        _base,
        queryParameters: {'page': page},
      );
      return AiConversationPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<AiConversation> create() async {
    try {
      final response = await _api.dio.post(
        _base,
        data: const <String, dynamic>{},
      );
      return AiConversation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<AiConversation> detail(int id) async {
    try {
      final response = await _api.dio.get('$_base$id/');
      return AiConversation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> send({required int id, required String message}) async {
    try {
      await _api.dio.post(
        '$_base$id/messages/',
        data: {'message': message.trim()},
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('$_base$id/');
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  AiFeatureException _map(DioException error) {
    return switch (error.response?.statusCode) {
      503 => const AiFeatureException(
        AiFailureKind.providerUnavailable,
        'Tanya AI sedang belum tersedia. Silakan coba lagi beberapa saat lagi.',
      ),
      429 => const AiFeatureException(
        AiFailureKind.rateLimited,
        'Batas penggunaan sementara tercapai. Silakan coba lagi nanti.',
      ),
      404 => const AiFeatureException(
        AiFailureKind.notFound,
        'Percakapan ini sudah tidak tersedia.',
      ),
      _ when _isNetwork(error.type) => const AiFeatureException(
        AiFailureKind.network,
        'Tidak dapat terhubung ke layanan. Periksa koneksi Anda dan coba lagi.',
      ),
      _ => const AiFeatureException(
        AiFailureKind.other,
        'Permintaan Tanya AI belum dapat diproses. Coba lagi.',
      ),
    };
  }

  bool _isNetwork(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}
