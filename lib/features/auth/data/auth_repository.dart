import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import 'models/mfa_verify_request.dart';
import 'models/mfa_verify_response.dart';
import 'models/register_request.dart';
import 'models/register_response.dart';
import 'models/token_pair.dart';
import 'token_repository.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenRepository tokenRepository,
  }) : _api = apiClient,
       _tokenRepo = tokenRepository;

  final ApiClient _api;
  final TokenRepository _tokenRepo;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/login/',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/register/',
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<MfaVerifyResponse> verifyMfa(MfaVerifyRequest request) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/2fa/login/',
        data: request.toJson(),
      );
      return MfaVerifyResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<TokenPair> refresh(String refreshToken) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      return TokenPair.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenRepo.loadRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.dio.post(
          '/api/v1/auth/logout/',
          data: {'refresh': refreshToken},
        );
      }
    } on DioException {
      // Local cleanup even if backend fails
    } finally {
      await _tokenRepo.clearAll();
    }
  }
}
