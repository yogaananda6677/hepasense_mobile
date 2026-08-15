import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/errors/status_mapping.dart';
import '../domain/screening.dart';

sealed class LatestScreeningResult {
  const LatestScreeningResult();
}

class LatestAvailable extends LatestScreeningResult {
  const LatestAvailable(this.screening);
  final Screening screening;
}

class NoScreening extends LatestScreeningResult {
  const NoScreening();
}

sealed class ScreeningDetailResult {
  const ScreeningDetailResult();
}

class ScreeningDetailAvailable extends ScreeningDetailResult {
  const ScreeningDetailAvailable(this.screening);
  final Screening screening;
}

class ScreeningDetailNotFound extends ScreeningDetailResult {
  const ScreeningDetailNotFound();
}

class ScreeningRepository {
  ScreeningRepository(this._api);
  final ApiClient _api;

  Future<LatestScreeningResult> latest() async {
    try {
      final response = await _api.dio.get('/api/v1/screenings/latest/');
      return LatestAvailable(
        Screening.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const NoScreening();
      throw ApiError.fromDioException(error);
    }
  }

  Future<ScreeningPage> history({
    required int page,
    ScreenStatus? status,
  }) async {
    try {
      final response = await _api.dio.get(
        '/api/v1/screenings/',
        queryParameters: {
          'page': page,
          if (status != null) 'status': _statusValue(status),
        },
      );
      return ScreeningPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<ScreeningDetailResult> detail(int id) async {
    try {
      final response = await _api.dio.get('/api/v1/screenings/$id/');
      return ScreeningDetailAvailable(
        Screening.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const ScreeningDetailNotFound();
      }
      throw ApiError.fromDioException(error);
    }
  }

  String _statusValue(ScreenStatus status) => switch (status) {
    ScreenStatus.healthy => 'healthy',
    ScreenStatus.warning => 'warning',
    ScreenStatus.highRisk => 'high_risk',
    ScreenStatus.invalid => 'invalid',
  };
}
