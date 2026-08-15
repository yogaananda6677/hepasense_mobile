import 'auth_user.dart';
import 'token_pair.dart';

class LoginResponse {
  const LoginResponse({
    required this.requiresMfa,
    this.tokens,
    this.user,
    this.challenge,
    this.message,
  });

  final bool requiresMfa;
  final TokenPair? tokens;
  final AuthUser? user;
  final String? challenge;
  final String? message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final requiresMfa = json['requires_2fa'] as bool? ?? false;
    final tokensJson = json['tokens'] as Map<String, dynamic>?;
    final userJson = json['user'] as Map<String, dynamic>?;

    return LoginResponse(
      requiresMfa: requiresMfa,
      tokens: tokensJson != null ? TokenPair.fromJson(tokensJson) : null,
      user: userJson != null ? AuthUser.fromJson(userJson) : null,
      challenge: json['challenge'] as String?,
      message: json['message'] as String?,
    );
  }
}
