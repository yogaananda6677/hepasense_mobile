import 'auth_user.dart';
import 'token_pair.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.user,
    required this.tokens,
    this.message,
  });

  final AuthUser user;
  final TokenPair tokens;
  final String? message;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
