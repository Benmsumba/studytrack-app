/// Base exception class for the app
abstract class AppException implements Exception {

  AppException({required this.message, this.code, this.stackTrace});
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Auth-related exceptions
class AuthException extends AppException {
  AuthException({required super.message, String? code, super.stackTrace})
    : super(
        code: code ?? 'AUTH_ERROR',
      );
}

/// Database/network-related exceptions
class DataException extends AppException {
  DataException({required super.message, String? code, super.stackTrace})
    : super(
        code: code ?? 'DATA_ERROR',
      );
}

/// Offline/connectivity exceptions
class OfflineException extends AppException {
  OfflineException({
    required super.message,
    String? code,
    super.stackTrace,
  }) : super(
         code: code ?? 'OFFLINE_ERROR',
       );
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    String? code,
    super.stackTrace,
  }) : super(
         code: code ?? 'VALIDATION_ERROR',
       );
}

/// Generic app exceptions
class AppGenericException extends AppException {
  AppGenericException({
    required super.message,
    String? code,
    super.stackTrace,
  }) : super(
         code: code ?? 'GENERIC_ERROR',
       );
}
