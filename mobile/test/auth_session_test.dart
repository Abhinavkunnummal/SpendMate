import 'package:flutter_test/flutter_test.dart';
import 'package:spendmate/core/auth/auth_session_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Persistent Authentication Session Tests', () {
    test('Initializes with unauthenticated state when storage is empty', () async {
      final auth = AuthSessionManager.instance;
      await auth.initialize();

      expect(auth.isInitialized, isTrue);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.token, isNull);
    });

    test('Login stores session tokens and emits authStateChanges true', () async {
      final auth = AuthSessionManager.instance;
      final authStates = <bool>[];
      final subscription = auth.authStateChanges().listen(authStates.add);

      await auth.loginSuccess(
        token: 'test_token_abc_123',
        refreshToken: 'test_refresh_xyz_456',
        userId: 'user_123',
        userName: 'Test User',
        phoneNumber: '+91 9876543210',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.token, equals('test_token_abc_123'));
      expect(auth.userId, equals('user_123'));
      expect(auth.userName, equals('Test User'));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(authStates.last, isTrue);

      await subscription.cancel();
    });

    test('Preserves session on app restart / re-initialization', () async {
      final auth = AuthSessionManager.instance;
      // Re-running initialize() simulates closing and reopening app
      await auth.initialize();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.token, equals('test_token_abc_123'));
      expect(auth.userId, equals('user_123'));
    });

    test('Logout clears session data, storage, and emits authStateChanges false', () async {
      final auth = AuthSessionManager.instance;
      final authStates = <bool>[];
      final subscription = auth.authStateChanges().listen(authStates.add);

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.token, isNull);
      expect(auth.userId, isNull);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(authStates.last, isFalse);

      // Re-initialize to verify persistent storage was completely wiped
      await auth.initialize();
      expect(auth.isAuthenticated, isFalse);

      await subscription.cancel();
    });
  });
}
