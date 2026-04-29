import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/utils/app_exception.dart';
import 'package:studytrack/core/utils/result.dart';

void main() {
  group('Result Type System Tests', () {
    group('Success type', () {
      test('constructor and equality', () {
        const result1 = Success<String>('value');
        const result2 = Success<String>('value');

        expect(result1.data, equals('value'));
        expect(result1.isSuccess, isTrue);
        expect(result1.isFailure, isFalse);
      });

      test('toString representation', () {
        const result = Success<String>('test data');
        expect(result.toString(), contains('Success'));
      });
    });

    group('Failure type', () {
      test('constructor and equality', () {
        final exception = AppGenericException(message: 'error');
        final result = Failure<String>(exception);

        expect(result.error.message, equals('error'));
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('toString representation', () {
        final exception = AppGenericException(message: 'error');
        final result = Failure<String>(exception);
        expect(result.toString(), contains('Failure'));
      });
    });

    group('map transformation', () {
      test('Success.map applies transformation', () {
        final result = const Success<int>(5).map((x) => x * 2);

        expect(result.isSuccess, isTrue);
        expect((result as Success<int>).data, equals(10));
      });

      test('Failure.map preserves error', () {
        final error = DataException(message: 'DB error');
        final result = Failure<int>(error).map((x) => x * 2);

        expect(result.isFailure, isTrue);
        expect((result as Failure<int>).error, equals(error));
      });

      test('map chain works correctly', () {
        final result = const Success<int>(
          2,
        ).map((x) => x + 3).map((x) => x * 2).map((x) => x - 1);

        expect((result as Success<int>).data, equals(9)); // (2+3)*2-1 = 9
      });
    });

    group('flatMap (monadic bind)', () {
      test('flatMap chains operations', () {
        final result = const Success<int>(5).flatMap((x) => Success(x * 2));

        expect(result.isSuccess, isTrue);
        expect((result as Success<int>).data, equals(10));
      });

      test('flatMap stops on first failure', () {
        final error = ValidationException(message: 'Invalid input');
        final result = const Success<int>(
          5,
        ).flatMap((_) => Failure<int>(error));

        expect(result.isFailure, isTrue);
        expect((result as Failure<int>).error.message, contains('Invalid'));
      });

      test('flatMap chain with conditional logic', () {
        Result<int> validate(int value) {
          if (value < 0) {
            return Failure(ValidationException(message: 'Negative'));
          }
          return Success(value * 2);
        }

        final successResult = const Success<int>(5).flatMap(validate);
        final failureResult = const Success<int>(-5).flatMap(validate);

        expect(successResult.isSuccess, isTrue);
        expect(failureResult.isFailure, isTrue);
      });
    });

    group('fold pattern matching', () {
      test('fold for Success calls success branch', () {
        const result = Success<String>('hello');

        final value = result.fold(
          (error) => 'Error: ${error.message}',
          (data) => 'Success: $data',
        );

        expect(value, equals('Success: hello'));
      });

      test('fold for Failure calls failure branch', () {
        final error = DataException(message: 'Database error');
        final result = Failure<String>(error);

        final value = result.fold(
          (error) => 'Error: ${error.message}',
          (data) => 'Success: $data',
        );

        expect(value, contains('Error'));
      });

      test('fold converts result to different type', () {
        const result = Success<int>(42);

        final httpStatus = result.fold((error) => 500, (data) => 200);

        expect(httpStatus, equals(200));
      });
    });

    group('onSuccess and onFailure side effects', () {
      test('onSuccess calls callback on Success', () {
        var called = false;
        var value = 0;

        const Success<int>(42).onSuccess((data) {
          called = true;
          value = data;
        });

        expect(called, isTrue);
        expect(value, equals(42));
      });

      test('onSuccess does not call on Failure', () {
        var called = false;

        Failure<int>(AppGenericException(message: 'error')).onSuccess((data) {
          called = true;
        });

        expect(called, isFalse);
      });

      test('onFailure calls callback on Failure', () {
        var called = false;
        late AppException caughtError;

        Failure<int>(DataException(message: 'DB error')).onFailure((error) {
          called = true;
          caughtError = error;
        });

        expect(called, isTrue);
        expect(caughtError.message, contains('DB'));
      });

      test('onFailure does not call on Success', () {
        var called = false;

        const Success<int>(42).onFailure((error) {
          called = true;
        });

        expect(called, isFalse);
      });

      test('method chaining with side effects', () {
        var successCalled = false;
        var failureCalled = false;

        final result = const Success<int>(42)
            .onSuccess((_) => successCalled = true)
            .onFailure((_) => failureCalled = true);

        expect(successCalled, isTrue);
        expect(failureCalled, isFalse);
        expect(result.isSuccess, isTrue);
      });
    });

    group('Exception types', () {
      test('AuthException has correct code', () {
        final exc = AuthException(message: 'Auth failed');
        expect(exc.code, equals('AUTH_ERROR'));
      });

      test('DataException has correct code', () {
        final exc = DataException(message: 'Data error');
        expect(exc.code, equals('DATA_ERROR'));
      });

      test('OfflineException has correct code', () {
        final exc = OfflineException(message: 'Offline');
        expect(exc.code, equals('OFFLINE_ERROR'));
      });

      test('ValidationException has correct code', () {
        final exc = ValidationException(message: 'Invalid');
        expect(exc.code, equals('VALIDATION_ERROR'));
      });

      test('Custom exception message preserved', () {
        const message = 'Custom error message';
        final exc = AppGenericException(message: message);
        expect(exc.toString(), equals(message));
      });

      test('Exception preserves stack trace', () {
        try {
          throw AppGenericException(message: 'Test');
        } catch (e, stack) {
          final exc = AuthException(message: 'Wrapped', stackTrace: stack);
          expect(exc.stackTrace, isNotNull);
        }
      });
    });

    group('Result error handling patterns', () {
      test('getOrThrow on Success returns value', () {
        const result = Success<String>('data');
        expect(result.getOrThrow(), equals('data'));
      });

      test('getOrThrow on Failure throws exception', () {
        final result = Failure<String>(AppGenericException(message: 'error'));
        expect(result.getOrThrow, throwsException);
      });

      test('Safe extraction with fold', () {
        final results = <Result<int>>[
          const Success<int>(1),
          const Success<int>(2),
          Failure<int>(AppGenericException(message: 'error')),
          const Success<int>(3),
        ];

        final values = <int>[];
        final errors = <Exception>[];

        for (final result in results) {
          result.fold((error) => errors.add(error as Exception), values.add);
        }

        expect(values, equals([1, 2, 3]));
        expect(errors.length, equals(1));
      });

      test('Combined operations with error propagation', () {
        final result = const Success<int>(5).map((x) => x + 3).flatMap((x) {
          if (x > 10) {
            return Failure(ValidationException(message: 'Too large'));
          }
          return Success(x * 2);
        });

        expect(result.isSuccess, isTrue);
        expect((result as Success<int>).data, equals(16));
      });
    });
  });
}
