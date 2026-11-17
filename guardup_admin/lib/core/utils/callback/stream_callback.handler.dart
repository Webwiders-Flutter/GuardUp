import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/error/api_exception.dart';
import '/core/error/error_code_parser.dart';
import '/core/logger/app_logger.dart';
import '/gen/app_localizations_en.dart';

Stream<T> streamHandler<T>(Stream<T> Function() action) async* {
  try {
    yield* action();
  } on ApiException catch (e, stackTrace) {
    AppLogger.e(
      e.message,
      stackTrace: stackTrace,
      tag: e.type.toString(),
      error: e,
    );

    rethrow;
  }
  // Supabase Auth
  on AuthException catch (e, stackTrace) {
    final message = getAuthMessage(e);
    final type = getAuthErrorType(e);

    AppLogger.e(
      e.message,
      error: e,
      stackTrace: stackTrace,
      tag: type.toString(),
    );

    throw ApiException(message, type: type, raw: e, stackTrace: stackTrace);
  }
  // Supabase Database
  on PostgrestException catch (e, stackTrace) {
    final type = getPostgrestErrorType(e);
    final message = getPostgrestMessage(e);

    AppLogger.e(
      message,
      error: e,
      stackTrace: stackTrace,
      tag: type.toString(),
    );

    throw ApiException(message, type: type, raw: e, stackTrace: stackTrace);
  }
  // Supabase Storage
  on StorageException catch (e, stackTrace) {
    AppLogger.e(
      e.message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.server.toString(),
    );

    throw ApiException(
      e.message,
      type: ApiErrorType.server,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Supabase Edge Functions
  on FunctionException catch (e, stackTrace) {
    final message = e.reasonPhrase ?? AppLocalizationsEn().somethingWentWrong;

    AppLogger.e(
      message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.server.toString(),
    );

    throw ApiException(
      message,
      type: ApiErrorType.server,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Network
  on SocketException catch (e, stackTrace) {
    AppLogger.e(
      e.message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.network.toString(),
    );

    throw ApiException(
      AppLocalizationsEn().noInternetConnection,
      type: ApiErrorType.network,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Timeout
  on TimeoutException catch (e, stackTrace) {
    final message = e.message ?? 'Request timeout';

    AppLogger.e(
      message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.timeout.toString(),
    );

    throw ApiException(
      AppLocalizationsEn().requestTimeout,
      type: ApiErrorType.timeout,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Parsing / Invalid response
  on FormatException catch (e, stackTrace) {
    AppLogger.e(
      e.message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.validation.toString(),
    );

    throw ApiException(
      AppLocalizationsEn().invalidDataFormat,
      type: ApiErrorType.validation,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Invalid argument
  on ArgumentError catch (e, stackTrace) {
    final message =
        e.message?.toString() ?? AppLocalizationsEn().invalidDataFormat;

    AppLogger.e(
      message,
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.validation.toString(),
    );

    throw ApiException(
      message,
      type: ApiErrorType.validation,
      raw: e,
      stackTrace: stackTrace,
    );
  }
  // Unknown
  catch (e, stackTrace) {
    AppLogger.e(
      e.toString(),
      error: e,
      stackTrace: stackTrace,
      tag: ApiErrorType.unknown.toString(),
    );

    throw ApiException(
      AppLocalizationsEn().somethingWentWrong,
      type: ApiErrorType.unknown,
      raw: e,
      stackTrace: stackTrace,
    );
  }
}
