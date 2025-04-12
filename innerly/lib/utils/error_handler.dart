import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => '[${code ?? 'Error'}] $message';
}

class ErrorHandler {
  static String handleError(dynamic error) {
    if (error is AppException) return error.message;
    if (error is PostgrestException) return error.message;
    return 'An unexpected error occurred';
  }

  static void logError(dynamic error, StackTrace stackTrace) {
    print('Error: $error');
    print('StackTrace: $stackTrace');
  }
}