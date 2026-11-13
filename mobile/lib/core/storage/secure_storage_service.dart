import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _tokenKey = 'spendmate_auth_token';
  static const String _refreshTokenKey = 'spendmate_refresh_token';
  static const String _userIdKey = 'spendmate_user_id';
  static const String _userNameKey = 'spendmate_user_name';

  static Future<void> saveAuthTokens({
    required String token,
    required String refreshToken,
    String? userId,
    String? userName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId);
    if (userName != null) await _storage.write(key: _userNameKey, value: userName);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  static Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}
