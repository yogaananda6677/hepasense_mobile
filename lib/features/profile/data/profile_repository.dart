import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/account_profile.dart';

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<AccountProfile> getProfile() async {
    try {
      final response = await _api.dio.get('/api/v1/accounts/profile/');
      return AccountProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<AccountProfile> updateProfile(AccountProfileUpdate update) async {
    try {
      final response = await _api.dio.patch(
        '/api/v1/accounts/profile/',
        data: update.toJson(),
      );
      return AccountProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
