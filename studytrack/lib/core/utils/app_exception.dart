/// Base exception class for the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  AppException({required this.message, this.code, this.stackTrace});

  @override
  String toString() => message;
}

/// Auth-related exceptions
class AuthException extends AppException {
  AuthException({required String message, String? code, StackTrace? stackTrace})
    : super(
        message: message,
        code: code ?? 'AUTH_ERROR',
        stackTrace: stackTrace,
      );
}

/// Database/network-related exceptions
class DataException extends AppException {
  DataException({required String message, String? code, StackTrace? stackTrace})
    : super(
        message: message,
        code: code ?? 'DATA_ERROR',
        stackTrace: stackTrace,
      );
}

/// Offline/connectivity exceptions
class OfflineException extends AppException {
  OfflineException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code ?? 'OFFLINE_ERROR',
         stackTrace: stackTrace,
       );
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code ?? 'VALIDATION_ERROR',
         stackTrace: stackTrace,
       );
}

/// Generic app exceptions
class AppGenericException extends AppException {
  AppGenericException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code ?? 'GENERIC_ERROR',
         stackTrace: stackTrace,
       );
}
