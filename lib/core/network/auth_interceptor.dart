import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor that attaches the Bearer Auth Token to outgoing HTTP requests
/// and handles authentication errors (e.g., clearing expired token on 401 Unauthorized).
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  static const String tokenKey = 'auth_token';

  AuthInterceptor({FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(key: tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear saved token if server rejects authentication (expired session)
      await _secureStorage.delete(key: tokenKey);
    }
    return handler.next(err);
  }
}
