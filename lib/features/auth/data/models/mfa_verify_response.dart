import 'auth_user.dart';
import 'token_pair.dart';

class MfaVerifyResponse {
  const MfaVerifyResponse({required this.user, required this.tokens});

  final AuthUser user;
  final TokenPair tokens;

  factory MfaVerifyResponse.fromJson(Map<String, dynamic> json) {
    return MfaVerifyResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}
