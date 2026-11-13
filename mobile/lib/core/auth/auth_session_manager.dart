import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import '../data/app_data_repository.dart';

/// Manages persistent authentication state across the SpendMate app lifecycle.
/// Notifies routers, UI widgets, and background sync services of session status.
class AuthSessionManager extends ChangeNotifier {
  static final AuthSessionManager instance = AuthSessionManager._internal();

  AuthSessionManager._internal();

  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _userName;
  String? _phoneNumber;
  String? _firebaseUid;

  final _authStateController = StreamController<bool>.broadcast();

  /// Stream mirroring Firebase authStateChanges()
  Stream<bool> authStateChanges() => _authStateController.stream;

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get phoneNumber => _phoneNumber;
  String? get firebaseUid => _firebaseUid;

  String get displayName => (_userName != null && _userName!.trim().isNotEmpty)
      ? _userName!.trim()
      : (_phoneNumber != null && _phoneNumber!.isNotEmpty ? _phoneNumber! : 'SpendMate User');

  String get userInitials {
    final name = _userName?.trim();
    if (name == null || name.isEmpty) return 'SM';
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Initializes auth state on app startup by inspecting encrypted local storage.
  /// Preserves existing user session across app restarts without requesting OTP.
  Future<void> initialize() async {
    try {
      final token = await SecureStorageService.getToken();
      final refreshToken = await SecureStorageService.getRefreshToken();
      final userId = await SecureStorageService.getUserId();
      final userName = await SecureStorageService.getUserName();
      final phoneNumber = await SecureStorageService.getPhoneNumber();
      final firebaseUid = await SecureStorageService.getFirebaseUid();

      if (token != null && token.isNotEmpty) {
        _token = token;
        _refreshToken = refreshToken;
        _userId = userId;
        _userName = userName;
        _phoneNumber = phoneNumber;
        _firebaseUid = firebaseUid;
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isInitialized = true;
      _authStateController.add(_isAuthenticated);
      notifyListeners();
    }
  }

  /// Called after successful phone verification or Firebase authentication.
  /// Securely stores credentials and switches app into authenticated state.
  Future<void> loginSuccess({
    required String token,
    required String refreshToken,
    String? userId,
    String? userName,
    String? phoneNumber,
    String? firebaseUid,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _userId = userId;
    _userName = userName;
    _phoneNumber = phoneNumber;
    _firebaseUid = firebaseUid;
    _isAuthenticated = true;

    _authStateController.add(true);
    notifyListeners();

    await SecureStorageService.saveAuthTokens(
      token: token,
      refreshToken: refreshToken,
      userId: userId,
      userName: userName,
      phoneNumber: phoneNumber,
      firebaseUid: firebaseUid,
    );

    try {
      // Reload repository data scoped specifically to this user
      await AppDataRepository.instance.reloadUserData();
    } catch (_) {}
  }

  /// Updates profile metadata in memory and encrypted storage.
  Future<void> updateUserName(String name) async {
    _userName = name;
    await SecureStorageService.updateUserName(name);
    notifyListeners();
  }

  /// Gracefully terminates the user session, wipes encrypted tokens, and routes back to login.
  Future<void> logout() async {
    await SecureStorageService.clearAuth();
    try {
      await AppDataRepository.instance.clearUserData();
    } catch (_) {}
    _token = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _phoneNumber = null;
    _firebaseUid = null;
    _isAuthenticated = false;

    _authStateController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
