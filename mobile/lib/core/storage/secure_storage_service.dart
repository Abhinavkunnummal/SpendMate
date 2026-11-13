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
  static const String _phoneKey = 'spendmate_phone_number';
  static const String _firebaseUidKey = 'spendmate_firebase_uid';

  static Future<void> saveAuthTokens({
    required String token,
    required String refreshToken,
    String? userId,
    String? userName,
    String? phoneNumber,
    String? firebaseUid,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId);
    if (userName != null) await _storage.write(key: _userNameKey, value: userName);
    if (phoneNumber != null) await _storage.write(key: _phoneKey, value: phoneNumber);
    if (firebaseUid != null) await _storage.write(key: _firebaseUidKey, value: firebaseUid);
  }

  static Future<void> updateUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
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

  static Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneKey);
  }

  static Future<String?> getFirebaseUid() async {
    return await _storage.read(key: _firebaseUidKey);
  }

  static Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}
