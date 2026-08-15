import '../../../core/storage/secure_keys.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/token_pair.dart';

class TokenRepository {
  TokenRepository(this._storage);

  final SecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;
  String? _mfaChallenge;

  String get accessToken => _accessToken ?? '';
  bool get hasRefreshToken => _refreshToken != null;

  Future<void> saveTokens(TokenPair tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _storage.write(
      key: SecureKeys.refreshToken,
      value: tokens.refreshToken,
    );
  }

  Future<String?> loadRefreshToken() async {
    _refreshToken = await _storage.read(key: SecureKeys.refreshToken);
    return _refreshToken;
  }

  Future<void> saveMfaChallenge(String challenge) async {
    _mfaChallenge = challenge;
  }

  String? get mfaChallenge => _mfaChallenge;

  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
    _mfaChallenge = null;
    await _storage.delete(key: SecureKeys.refreshToken);
  }

  void clearMfaChallenge() => _mfaChallenge = null;

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: SecureKeys.refreshToken);
  }
}
