import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores only session credentials. Never replace with SharedPreferences.
class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'firebase_session_token';
  Future<void> saveSessionToken(String token) => _storage.write(key: _sessionKey, value: token);
  Future<String?> readSessionToken() => _storage.read(key: _sessionKey);
  Future<void> clearSessionToken() => _storage.delete(key: _sessionKey);
}
