import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Secure-storage availability must not crash an otherwise valid session.
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // In-memory credentials are still cleared by TokenRepository.
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Treat an unavailable platform keystore as an already-cleared store.
    }
  }
}
