import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

class PushDeviceRegistration {
  const PushDeviceRegistration({required this.id, required this.fidHint});
  final int id;
  final String fidHint;

  factory PushDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      PushDeviceRegistration(
        id: json['id'] as int,
        fidHint: json['fid_hint'] as String,
      );
}

class PushDeviceRepository {
  PushDeviceRepository(this._api);
  final ApiClient _api;

  Future<PushDeviceRegistration> register(String fid) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/notifications/push-devices/',
        data: {'fid': fid, 'platform': 'android'},
      );
      return PushDeviceRegistration.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<void> revoke(int id) async {
    try {
      await _api.dio.delete('/api/v1/notifications/push-devices/$id/');
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
