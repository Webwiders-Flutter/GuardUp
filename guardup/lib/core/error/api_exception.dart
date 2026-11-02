enum ApiErrorType {
  network,
  timeout,
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimit,
  server,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;
  final dynamic raw;
  final StackTrace? stackTrace;

  ApiException(
    this.message, {
    this.statusCode,
    this.type = ApiErrorType.unknown,
    this.raw,
    this.stackTrace,
  });

  @override
  String toString() {
    return '''
ApiException:
  statusCode: $statusCode
  type: $type
  message: $message
  raw: $raw
  stackTrace: $stackTrace
''';
  }
}
