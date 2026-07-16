import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://passport-api-seven.vercel.app/api',
);

/// Single Dio instance for all API calls — CONVENTIONS.md §1.
/// All API calls go through ApiClient. Never use Dio or http directly in a
/// repository, and never call ApiClient from a widget or screen.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.addAll([
      _AuthInterceptor(_storage),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 → clear token (router will redirect to login via Riverpod auth state)
    if (err.response?.statusCode == 401) {
      _storage.delete(key: 'accessToken');
    }
    handler.next(err);
  }
}
