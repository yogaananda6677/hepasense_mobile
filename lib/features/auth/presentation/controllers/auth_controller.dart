import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/features/auth/data/auth_providers.dart';
import 'package:hepasense_mobile/features/auth/data/auth_repository.dart';
import 'package:hepasense_mobile/features/auth/data/models/login_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/mfa_verify_request.dart';
import 'package:hepasense_mobile/features/auth/data/models/register_request.dart';
import 'package:hepasense_mobile/features/auth/data/token_repository.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';

class AuthController extends Notifier<AuthStatus> {
  int _generation = 0;
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenRepository get _tokenRepo => ref.read(tokenRepositoryProvider);

  @override
  AuthStatus build() {
    ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      if (previous != null && next > previous) {
        _generation++;
        state = const AuthUnauthenticated();
      }
    });
    return const AuthInitial();
  }

  Future<void> restoreSession() async {
    final request = ++_generation;
    state = const AuthLoading();
    final refreshToken = await _tokenRepo.loadRefreshToken();
    if (request != _generation) return;
    if (refreshToken == null) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      final tokens = await _repo.refresh(refreshToken);
      if (request != _generation) return;
      await _tokenRepo.saveTokens(tokens);
      if (request != _generation) return;
      state = const Authenticated(
        user: null, // User will be loaded by Phase 3 patient identity
      );
    } catch (_) {
      if (request != _generation) return;
      await _tokenRepo.clearAll();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    if (state is AuthLoading) return;
    final request = ++_generation;
    state = const AuthLoading();
    try {
      final response = await _repo.login(
        LoginRequest(email: email, password: password),
      );
      if (request != _generation) return;
      if (response.requiresMfa) {
        await _tokenRepo.saveMfaChallenge(response.challenge!);
        if (request != _generation) return;
        state = AuthMfaRequired(challenge: response.challenge!);
      } else {
        await _tokenRepo.saveTokens(response.tokens!);
        if (request != _generation) return;
        state = Authenticated(user: response.user);
      }
    } on ApiError catch (e) {
      if (request != _generation) return;
      state = AuthFailure(message: e.message);
    } catch (_) {
      if (request != _generation) return;
      state = const AuthFailure(
        message: 'Terjadi kesalahan. Periksa jaringan Anda.',
      );
    }
  }

  Future<void> register(RegisterRequest request) async {
    if (state is AuthLoading) return;
    final operation = ++_generation;
    state = const AuthLoading();
    try {
      final response = await _repo.register(request);
      if (operation != _generation) return;
      await _tokenRepo.saveTokens(response.tokens);
      if (operation != _generation) return;
      state = Authenticated(user: response.user);
    } on ApiError catch (e) {
      if (operation != _generation) return;
      state = AuthFailure(message: e.message);
    } catch (_) {
      if (operation != _generation) return;
      state = const AuthFailure(
        message: 'Terjadi kesalahan. Periksa jaringan Anda.',
      );
    }
  }

  Future<void> verifyMfa(String otpCode) async {
    final currentState = state;
    if (currentState is! AuthMfaRequired) return;

    final request = ++_generation;
    state = const AuthLoading();
    try {
      final response = await _repo.verifyMfa(
        MfaVerifyRequest(challenge: currentState.challenge, otpCode: otpCode),
      );
      if (request != _generation) return;
      await _tokenRepo.saveTokens(response.tokens);
      if (request != _generation) return;
      _tokenRepo.clearMfaChallenge();
      state = Authenticated(user: response.user);
    } on ApiError catch (e) {
      if (request != _generation) return;
      state = AuthMfaRequired(
        challenge: currentState.challenge,
        errorMessage: e.message,
      );
    } catch (_) {
      if (request != _generation) return;
      state = AuthMfaRequired(
        challenge: currentState.challenge,
        errorMessage: 'Terjadi kesalahan. Periksa jaringan Anda.',
      );
    }
  }

  Future<void> logout() async {
    ++_generation;
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void resetToUnauthenticated() {
    ++_generation;
    _tokenRepo.clearMfaChallenge();
    state = const AuthUnauthenticated();
  }

  Future<void> invalidateSession() async {
    ++_generation;
    await _tokenRepo.clearAll();
    state = const AuthUnauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);
