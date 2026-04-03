// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken   = 'jwt_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUserId  = 'user_id';

  // ── JWT ───────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefresh, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefresh);
  }

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
  }

  // ── Nettoyage ─────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}