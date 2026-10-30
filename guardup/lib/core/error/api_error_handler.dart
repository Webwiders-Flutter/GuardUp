import 'package:dio/dio.dart';

import 'failures.dart';

import 'package:guardup/core/error/error_keys.dart';

class ApiErrorHandler {
  static Failure handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkFailure(ErrorKeys.connectionTimedOut);
        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);
        case DioExceptionType.cancel:
          return const ServerFailure(ErrorKeys.requestCancelled);
        case DioExceptionType.connectionError:
          return const NetworkFailure(ErrorKeys.connectionTimedOut);
        default:
          return const ServerFailure(ErrorKeys.server);
      }
    }
    return ServerFailure(ErrorKeys.server);
  }

  static Failure _handleBadResponse(Response? response) {
    if (response == null) return const ServerFailure(ErrorKeys.server);

    final statusCode = response.statusCode;
    final data = response.data;
    final message = (data is Map && data.containsKey('message'))
        ? data['message'].toString()
        : ErrorKeys.server;

    switch (statusCode) {
      case 400:
        return ServerFailure(message);
      case 401:
      case 403:
        return AuthFailure(ErrorKeys.userNotAuthenticated);
      case 404:
        return ServerFailure(ErrorKeys.resourceNotFound);
      case 500:
        return const ServerFailure(ErrorKeys.server);
      default:
        return ServerFailure(message);
    }
  }
}
