import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studytrack/core/repositories/auth_repository.dart';
import 'package:studytrack/core/repositories/impl/auth_repository_impl.dart';
import 'package:studytrack/core/services/supabase_service.dart';
import 'package:studytrack/core/utils/result.dart';
import 'package:studytrack/models/user_model.dart';

// Mock Supabase service
class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  group('AuthRepository Integration Tests', () {
    late MockSupabaseService mockSupabaseService;
    late AuthRepository authRepository;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      authRepository = AuthRepositoryImpl(mockSupabaseService);
    });

    tearDown(() {
      reset(mockSupabaseService);
    });

    group('signUpWithEmail', () {
      test('returns Success with ProfileModel on successful signup', () async {
        // Arrange
        final expectedUser = ProfileModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'Test User',
          course: 'Computer Science',
          yearLevel: 2,
        );

        when(
          () => mockSupabaseService.signUpWithEmail(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => expectedUser);

        // Act
        final result = await authRepository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
          course: 'Computer Science',
          yearLevel: 2,
          studyStyle: 'active',
          sessionsPerWeek: 5,
          preferredStudyMethod: 'group',
        );

        // Assert
        expect(result, isA<Success<ProfileModel>>());
        expect((result as Success<ProfileModel>).data, equals(expectedUser));
        verify(
          () => mockSupabaseService.signUpWithEmail(
            'test@example.com',
            'password123',
            'Test User',
            'Computer Science',
            2,
            'active',
            5,
            'group',
          ),
        ).called(1);
      });

      test('returns Failure on signup error', () async {
        // Arrange
        when(
          () => mockSupabaseService.signUpWithEmail(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await authRepository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
          course: 'Computer Science',
          yearLevel: 2,
          studyStyle: 'active',
          sessionsPerWeek: 5,
          preferredStudyMethod: 'group',
        );

        // Assert
        expect(result, isA<Failure<ProfileModel>>());
        expect(result.isFailure, isTrue);
      });

      test('returns Failure when service returns null', () async {
        // Arrange
        when(
          () => mockSupabaseService.signUpWithEmail(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => null);

        when(
          () => mockSupabaseService.lastAuthError,
        ).thenReturn('Account creation failed');

        // Act
        final result = await authRepository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
          course: 'Computer Science',
          yearLevel: 2,
          studyStyle: 'active',
          sessionsPerWeek: 5,
          preferredStudyMethod: 'group',
        );

        // Assert
        expect(result, isA<Failure<ProfileModel>>());
        expect(result.isFailure, isTrue);
      });
    });

    group('signInWithEmail', () {
      test('returns Success with ProfileModel on successful signin', () async {
        // Arrange
        final expectedUser = ProfileModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'Test User',
          course: 'Computer Science',
          yearLevel: 2,
        );

        when(
          () => mockSupabaseService.signInWithEmail(any(), any()),
        ).thenAnswer((_) async => expectedUser);

        // Act
        final result = await authRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<Success<ProfileModel>>());
        expect((result as Success<ProfileModel>).data, equals(expectedUser));
      });

      test('returns Failure on signin error', () async {
        // Arrange
        when(
          () => mockSupabaseService.signInWithEmail(any(), any()),
        ).thenThrow(Exception('Invalid credentials'));

        // Act
        final result = await authRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result, isA<Failure<ProfileModel>>());
        expect(result.isFailure, isTrue);
      });
    });

    group('signOut', () {
      test('returns Success on successful signout', () async {
        // Arrange
        when(() => mockSupabaseService.signOut()).thenAnswer((_) async => {});

        // Act
        final result = await authRepository.signOut();

        // Assert
        expect(result, isA<Success<void>>());
        expect(result.isSuccess, isTrue);
        verify(() => mockSupabaseService.signOut()).called(1);
      });

      test('returns Failure on signout error', () async {
        // Arrange
        when(
          () => mockSupabaseService.signOut(),
        ).thenThrow(Exception('Signout failed'));

        // Act
        final result = await authRepository.signOut();

        // Assert
        expect(result, isA<Failure<void>>());
        expect(result.isFailure, isTrue);
      });
    });

    group('Result pattern functionality', () {
      test('Success.getOrThrow returns data', () {
        // Arrange
        final result = Success<String>('test data');

        // Act
        final data = result.getOrThrow();

        // Assert
        expect(data, equals('test data'));
      });

      test('Failure.getOrThrow throws exception', () {
        // Arrange
        final exception = Exception('Test error');
        final result = Failure<String>(Exception('Test error'));

        // Act & Assert
        expect(() => result.getOrThrow(), throwsException);
      });

      test('Success.map transforms data', () {
        // Arrange
        final result = Success<int>(5);

        // Act
        final mapped = result.map((value) => value * 2);

        // Assert
        expect(mapped, isA<Success<int>>());
        expect((mapped as Success<int>).data, equals(10));
      });

      test('Failure.map preserves error', () {
        // Arrange
        final error = Exception('Test error');
        final result = Failure<int>(error);

        // Act
        final mapped = result.map((value) => value * 2);

        // Assert
        expect(mapped, isA<Failure<int>>());
      });

      test('fold works correctly for Success', () {
        // Arrange
        final result = Success<String>('success');

        // Act
        final value = result.fold(
          (error) => 'error: $error',
          (data) => 'success: $data',
        );

        // Assert
        expect(value, equals('success: success'));
      });

      test('fold works correctly for Failure', () {
        // Arrange
        final result = Failure<String>(Exception('test error'));

        // Act
        final value = result.fold(
          (error) => 'error: $error',
          (data) => 'success: $data',
        );

        // Assert
        expect(value.contains('error:'), isTrue);
      });
    });
  });
}
