import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dedicated, structured logger for all Supabase API operations (Auth, DB, Storage).
///
/// Features:
/// - Visual color emojis for instant scanning in console / VS Code debug logs
/// - Detailed formatting for [AuthException], [PostgrestException], and [StorageException]
/// - Safe payload sanitization (hides passwords and sensitive tokens)
final class SupabaseLogger {
  SupabaseLogger._();

  static const String _tag = 'SUPABASE';

  /// Logs an outgoing Supabase API request.
  static void request(
    String operation, {
    Map<String, dynamic>? payload,
    String? details,
  }) {
    if (kReleaseMode) return;

    final sanitized = payload != null ? _sanitizePayload(payload) : null;
    final buffer = StringBuffer('🚀 [$operation]');
    if (details != null && details.isNotEmpty) {
      buffer.write(' - $details');
    }
    if (sanitized != null && sanitized.isNotEmpty) {
      buffer.write('\n   Payload: $sanitized');
    }

    developer.log(
      buffer.toString(),
      name: '$_tag::REQ',
      level: 700,
    );
  }

  /// Logs a successful Supabase API response.
  static void success(
    String operation, {
    dynamic result,
    String? message,
  }) {
    if (kReleaseMode) return;

    final buffer = StringBuffer('✅ [$operation]');
    if (message != null && message.isNotEmpty) {
      buffer.write(' - $message');
    }
    if (result != null) {
      buffer.write('\n   Result: $result');
    }

    developer.log(
      buffer.toString(),
      name: '$_tag::SUCCESS',
      level: 800,
    );
  }

  /// Logs an informational notice or session event.
  static void info(String message, {String? operation, dynamic data}) {
    final buffer = StringBuffer('ℹ️ ');
    if (operation != null) {
      buffer.write('[$operation] ');
    }
    buffer.write(message);
    if (data != null) {
      buffer.write('\n   Data: $data');
    }

    developer.log(
      buffer.toString(),
      name: '$_tag::INFO',
      level: 800,
    );
  }

  /// Logs a warning (e.g., missing optional fields, retries, slow responses).
  static void warning(
    String message, {
    String? operation,
    dynamic data,
  }) {
    final buffer = StringBuffer('⚠️ ');
    if (operation != null) {
      buffer.write('[$operation] ');
    }
    buffer.write(message);
    if (data != null) {
      buffer.write('\n   Warning Data: $data');
    }

    developer.log(
      buffer.toString(),
      name: '$_tag::WARN',
      level: 900,
    );
  }

  /// Logs an error with detailed inspection for Supabase-specific exception types.
  static void error(
    String operation,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    final buffer = StringBuffer('❌ [$operation] FAILED\n');

    if (error is AuthException) {
      buffer.writeln('   Type: AuthException');
      buffer.writeln('   Message: ${error.message}');
      buffer.writeln('   Status Code: ${error.statusCode}');
      if (error.code != null) {
        buffer.writeln('   Error Code: ${error.code}');
      }
    } else if (error is PostgrestException) {
      buffer.writeln('   Type: PostgrestException');
      buffer.writeln('   Message: ${error.message}');
      buffer.writeln('   Code: ${error.code}');
      if (error.details != null) {
        buffer.writeln('   Details: ${error.details}');
      }
      if (error.hint != null) {
        buffer.writeln('   Hint: ${error.hint}');
      }
    } else if (error is StorageException) {
      buffer.writeln('   Type: StorageException');
      buffer.writeln('   Message: ${error.message}');
      buffer.writeln('   Status Code: ${error.statusCode}');
      if (error.error != null) {
        buffer.writeln('   Underlying Error: ${error.error}');
      }
    } else {
      buffer.writeln('   Error: $error');
    }

    developer.log(
      buffer.toString(),
      name: '$_tag::ERROR',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Sanitizes sensitive fields like passwords, access tokens, and secrets from logs.
  static Map<String, dynamic> _sanitizePayload(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload);
    const sensitiveKeys = {
      'password',
      'confirmPassword',
      'newPassword',
      'oldPassword',
      'token',
      'accessToken',
      'refreshToken',
      'secret',
    };

    for (final key in copy.keys) {
      if (sensitiveKeys.any((s) => key.toLowerCase().contains(s.toLowerCase()))) {
        copy[key] = '••••••••';
      }
    }
    return copy;
  }
}

