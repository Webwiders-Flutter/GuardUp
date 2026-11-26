import 'dart:convert';

import '/core/error/api_exception.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

String getAuthMessage(AuthException exception) {
  switch (exception.code) {
    case 'invalid_credentials':
      return 'Invalid email or password.';

    case 'email_not_confirmed':
      return 'Please verify your email address before signing in.';

    case 'user_already_exists':
      return 'An account with this email already exists.';

    case 'email_exists':
      return 'An account with this email already exists.';

    case 'user_not_found':
      return 'No account was found with these credentials.';

    case 'weak_password':
      return 'Please choose a stronger password.';

    case 'same_password':
      return 'The new password must be different from your current password.';

    case 'over_request_rate_limit':
      return 'Too many requests. Please try again later.';

    case 'over_email_send_rate_limit':
      return 'Too many emails have been requested. Please try again later.';

    case 'over_sms_send_rate_limit':
      return 'Too many SMS requests. Please try again later.';

    case 'session_not_found':
      return 'Your session has expired. Please sign in again.';

    case 'refresh_token_not_found':
      return 'Your session has expired. Please sign in again.';

    case 'refresh_token_already_used':
      return 'Your session has expired. Please sign in again.';

    case 'otp_expired':
      return 'The verification code has expired. Please request a new one.';

    case 'otp_disabled':
      return 'OTP authentication is currently unavailable.';

    case 'captcha_failed':
      return 'Verification failed. Please try again.';

    case 'signup_disabled':
      return 'New account registration is currently disabled.';

    case 'email_provider_disabled':
      return 'Email authentication is currently unavailable.';

    case 'phone_provider_disabled':
      return 'Phone authentication is currently unavailable.';

    case 'provider_disabled':
      return 'This sign-in method is currently unavailable.';

    case 'user_banned':
      return 'This account is currently unavailable.';

    case 'validation_failed':
      return 'Please check the information you entered.';

    default:
      return exception.message;
  }
}

ApiErrorType getAuthErrorType(AuthException exception) {
  switch (exception.code) {
    case 'invalid_credentials':
    case 'email_not_confirmed':
    case 'user_not_found':
    case 'weak_password':
    case 'same_password':
    case 'validation_failed':
    case 'otp_expired':
      return ApiErrorType.validation;

    case 'session_not_found':
    case 'refresh_token_not_found':
    case 'refresh_token_already_used':
      return ApiErrorType.unauthorized;

    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
    case 'over_sms_send_rate_limit':
      return ApiErrorType.rateLimit;

    default:
      return ApiErrorType.server;
  }
}

String getPostgrestMessage(PostgrestException exception) {
  final code = _parseAndGetCode(exception);

  switch (code) {
    // unique_violation
    case '23505':
      return 'This record already exists.';

    // foreign_key_violation
    case '23503':
      return 'This operation references invalid or existing related data.';

    // not_null_violation
    case '23502':
      return 'A required value is missing.';

    // check_violation
    case '23514':
      return 'The provided data is invalid.';

    // insufficient_privilege
    case '42501':
      return 'You do not have permission to perform this action.';

    // undefined_table
    case '42P01':
      return 'The requested resource is unavailable.';

    // undefined_column
    case '42703':
      return 'The requested data is unavailable.';

    default:
      return exception.message;
  }
}

ApiErrorType getPostgrestErrorType(PostgrestException exception) {
  final code = _parseAndGetCode(exception);

  switch (code) {
    case '23505':
      return ApiErrorType.conflict;

    case '23503':
    case '23502':
    case '23514':
      return ApiErrorType.validation;

    case '42501':
      return ApiErrorType.forbidden;

    case '42P01':
    case '42703':
      return ApiErrorType.server;

    default:
      return ApiErrorType.server;
  }
}

String _parseAndGetCode(PostgrestException exception) {
  final message = exception.message;

  try {
    final decoded = jsonDecode(message);

    if (decoded is Map<String, dynamic>) {
      return decoded['code'];
    }

    return exception.code ?? '';
  } catch (_) {
    return exception.code ?? '';
  }
}
