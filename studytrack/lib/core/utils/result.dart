import 'app_exception.dart';

/// Sealed result type for type-safe error handling
sealed class Result<T> {
  const Result();

  /// Convert result to value or throw
  T getOrThrow() => switch (this) {
    Success(data: final data) => data,
    Failure(error: final error) => throw error,
  };

  /// Map success value, leaving failure unchanged
  Result<R> map<R>(R Function(T) transform) => switch (this) {
    Success(data: final data) => Success(transform(data)),
    Failure(error: final error) => Failure(error),
  };

  /// FlatMap (monadic bind) for chaining operations
  Result<R> flatMap<R>(Result<R> Function(T) transform) => switch (this) {
    Success(data: final data) => transform(data),
    Failure(error: final error) => Failure(error),
  };

  /// Execute side effect on success
  Result<T> onSuccess(void Function(T) fn) {
    if (this is Success<T>) {
      fn((this as Success<T>).data);
    }
    return this;
  }

  /// Execute side effect on failure
  Result<T> onFailure(void Function(AppException) fn) {
    if (this is Failure<T>) {
      fn((this as Failure<T>).error);
    }
    return this;
  }

  /// Fold result into single value
  R fold<R>(R Function(AppException) onFailure, R Function(T) onSuccess) =>
      switch (this) {
        Success(data: final data) => onSuccess(data),
        Failure(error: final error) => onFailure(error),
      };

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
}

/// Success variant of Result
class Success<T> extends Result<T> {

  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success($data)';
}

/// Failure variant of Result
class Failure<T> extends Result<T> {

  const Failure(this.error);
  final AppException error;

  @override
  String toString() => 'Failure(${error.message})';
}
