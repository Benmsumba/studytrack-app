import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studytrack/core/services/supabase_service.dart';
import 'package:studytrack/features/auth/controllers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Manual mock
// ---------------------------------------------------------------------------

class _FakeSupabaseService extends SupabaseService {
  _FakeSupabaseService() : super.forTesting();

  User? _signUpResult;
  User? _signInResult;
  Map<String, dynamic>? _profileResult;
  bool _signOutCalled = false;
  String? _fakeLastAuthError;

  bool shouldThrowOnSignIn = false;
  bool shouldThrowOnSignUp = false;
  bool shouldThrowOnSignOut = false;

  bool get signOutCalled => _signOutCalled;

  void setSignUpResult(User? user) => _signUpResult = user;
  void setSignInResult(User? user) => _signInResult = user;
  void setProfileResult(Map<String, dynamic>? profile) =>
      _profileResult = profile;
  void setLastAuthError(String? error) => _fakeLastAuthError = error;

  @override
  String? get lastAuthError => _fakeLastAuthError;

  @override
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
    String course,
    int yearLevel,
    String primeStudyTime,
    int studyHoursPerDay,
    String studyPreference,
  ) async {
    if (shouldThrowOnSignUp) throw Exception('signup network error');
    return _signUpResult;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    if (shouldThrowOnSignIn) throw Exception('signin network error');
    return _signInResult;
  }

  @override
  Future<bool?> signOut() async {
    if (shouldThrowOnSignOut) throw Exception('signout error');
    _signOutCalled = true;
    return true;
  }

  @override
  User? getCurrentUser() => _signInResult;

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async =>
      _profileResult;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late _FakeSupabaseService fake;
  late AuthProvider provider;

  setUp(() {
    fake = _FakeSupabaseService();
    provider = AuthProvider(supabaseService: fake);
  });

  group('AuthProvider — initial state', () {
    test('starts with no user, no loading, no error', () {
      expect(provider.currentUser, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('AuthProvider — register', () {
    test(
      'sets errorMessage from lastAuthError when signUp returns null',
      () async {
        fake.setSignUpResult(null);
        fake.setLastAuthError('Email already in use.');

        await provider.register(
          fullName: 'Alice',
          email: 'alice@test.com',
          password: 'Password1!',
        );

        expect(provider.currentUser, isNull);
        expect(provider.errorMessage, 'Email already in use.');
        expect(provider.isLoading, isFalse);
      },
    );

    test('falls back to generic message when lastAuthError is null', () async {
      fake.setSignUpResult(null);
      fake.setLastAuthError(null);

      await provider.register(
        fullName: 'Bob',
        email: 'bob@test.com',
        password: 'Pass123!',
      );

      expect(provider.errorMessage, 'Unable to create account.');
      expect(provider.isLoading, isFalse);
    });

    test('sets errorMessage on thrown exception', () async {
      fake.shouldThrowOnSignUp = true;

      await provider.register(
        fullName: 'Carol',
        email: 'carol@test.com',
        password: 'Pass123!',
      );

      expect(provider.errorMessage, contains('Registration failed'));
      expect(provider.isLoading, isFalse);
    });

    test('clears loading flag in all cases', () async {
      fake.setSignUpResult(null);

      await provider.register(
        fullName: 'Dave',
        email: 'dave@test.com',
        password: 'Pass123!',
      );

      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — login', () {
    test(
      'sets errorMessage from lastAuthError when signIn returns null',
      () async {
        fake.setSignInResult(null);
        fake.setLastAuthError('Invalid credentials.');

        await provider.login(email: 'x@x.com', password: 'wrong');

        expect(provider.currentUser, isNull);
        expect(provider.errorMessage, 'Invalid credentials.');
        expect(provider.isLoading, isFalse);
      },
    );

    test('falls back to generic message when lastAuthError is null', () async {
      fake.setSignInResult(null);
      fake.setLastAuthError(null);

      await provider.login(email: 'x@x.com', password: 'wrong');

      expect(provider.errorMessage, 'Login failed.');
    });

    test('sets errorMessage on thrown exception', () async {
      fake.shouldThrowOnSignIn = true;

      await provider.login(email: 'x@x.com', password: 'bad');

      expect(provider.errorMessage, contains('Login failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — logout', () {
    test('clears currentUser and invokes signOut on service', () async {
      await provider.logout();

      expect(fake.signOutCalled, isTrue);
      expect(provider.currentUser, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('sets errorMessage when signOut throws', () async {
      fake.shouldThrowOnSignOut = true;

      await provider.logout();

      expect(provider.errorMessage, contains('Logout failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — refreshCurrentUser', () {
    test('clears currentUser when getCurrentUser returns null', () async {
      fake.setSignInResult(null);

      await provider.refreshCurrentUser();

      expect(provider.currentUser, isNull);
    });
  });
}
