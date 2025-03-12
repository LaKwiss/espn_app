import 'dart:developer' as dev;

class ErrorHandlerService {
  T handleError<T>(
    Object error,
    StackTrace stackTrace,
    String operation, {
    T? defaultValue,
  }) {
    dev.log('Error in $operation: $error');
    dev.log('Stack trace: $stackTrace');

    if (defaultValue != null) {
      return defaultValue;
    }

    throw Exception('Failed in $operation: $error');
  }
}
