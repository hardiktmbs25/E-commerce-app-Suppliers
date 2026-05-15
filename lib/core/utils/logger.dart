// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[DEBUG] $message${error != null ? '\n$error' : ''}');
  }

  static void i(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void w(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[WARN] $message${error != null ? '\n$error' : ''}');
  }

  static void e(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? '\nError: $error' : ''}${stack != null ? '\n$stack' : ''}');
    }
  }
}

final appLog = AppLogger();