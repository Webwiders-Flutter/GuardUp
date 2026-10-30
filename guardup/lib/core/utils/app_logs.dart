import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogs {
  static const String _tag = 'GuardUp';

  /// Log a message with an optional name/tag
  static void log(String message, {String? name, Object? error}) {
    if (kDebugMode) {
      final tag = name ?? _tag;
      // ignore: avoid_print
      print('[$tag] $message${error != null ? ' | Error: $error' : ''}');
      developer.log(message, name: tag, error: error, time: DateTime.now());
    }
  }

  /// Print a message to the console only in debug mode
  static void debugPrint(Object? message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$_tag] $message');
    }
  }

  /// Log an error message
  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final tag = name ?? _tag;
      // ignore: avoid_print
      print(
        '[$tag] ❌ ERROR: $message${error != null ? ' | Details: $error' : ''}',
      );
      developer.log(
        '❌ ERROR: $message',
        name: tag,
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
        level: 1000, // High level for errors
      );
    }
  }

  /// Log an info message
  static void info(String message, {String? name}) {
    if (kDebugMode) {
      final tag = name ?? _tag;
      // ignore: avoid_print
      print('[$tag] ℹ️ INFO: $message');
      developer.log(
        'ℹ️ INFO: $message',
        name: tag,
        time: DateTime.now(),
        level: 500,
      );
    }
  }

  /// Log a success message
  static void success(String message, {String? name}) {
    if (kDebugMode) {
      final tag = name ?? _tag;
      // ignore: avoid_print
      print('[$tag] ✅ SUCCESS: $message');
      developer.log(
        '✅ SUCCESS: $message',
        name: tag,
        time: DateTime.now(),
        level: 200,
      );
    }
  }

  static void warning(String message, {String? name}) {
    if (kDebugMode) {
      final tag = name ?? _tag;
      // ignore: avoid_print
      print('[$tag] ⚠️ WARNING: $message');
      developer.log(
        '⚠️ WARNING: $message',
        name: tag,
        time: DateTime.now(),
        level: 700,
      );
    }
  }
}
