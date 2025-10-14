import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class LoggerUtils {
  static const String _prefix = '[NhacLichViet]';

  /// Log debug message
  static void debug(String message, [dynamic error]) {
    if (kDebugMode) {
      print('$_prefix [DEBUG] $message');
      if (error != null) {
        print('$_prefix [DEBUG] Error: $error');
      }
    }
  }

  /// Log info message
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [INFO] $message');
      if (data != null) {
        print('$_prefix [INFO] Data: $data');
      }
    }
  }

  /// Log warning message
  static void warning(String message, [dynamic error]) {
    if (kDebugMode) {
      print('$_prefix [WARNING] $message');
      if (error != null) {
        print('$_prefix [WARNING] Error: $error');
      }
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('$_prefix [ERROR] $message');
    if (error != null) {
      print('$_prefix [ERROR] Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('$_prefix [ERROR] StackTrace: $stackTrace');
    }
  }

  /// Log success message
  static void success(String message) {
    if (kDebugMode) {
      print('$_prefix [SUCCESS] $message');
    }
  }
}
