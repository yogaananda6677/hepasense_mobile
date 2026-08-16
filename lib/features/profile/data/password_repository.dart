import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

class PasswordRepository {
  PasswordRepository(this._api);
  final ApiClient _api;

  Future<String> change({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/accounts/change-password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      return data?['message']?.toString() ??
          'Password berhasil diubah. Silakan login ulang.';
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
