import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:guardup/data/providers/local/storage_service.dart';

class ApiClient {
  final Dio dio;
  final StorageService storageService;

  ApiClient({required this.dio, required this.storageService}) {
    _setupDio();
  }

  void _setupDio() {
    dio.options = BaseOptions(
      baseUrl: 'https://api.herstay.com/v1', // Placeholder
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            print('--- API REQUEST ---');
            print('URL: ${options.uri}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('--- API RESPONSE ---');
            print('Status: ${response.statusCode}');
            print('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print('--- API ERROR ---');
            print('Status: ${e.response?.statusCode}');
            print('Message: ${e.message}');
            print('Data: ${e.response?.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- API Methods ---

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
