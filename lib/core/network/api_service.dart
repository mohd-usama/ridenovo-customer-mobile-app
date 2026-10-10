import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_response.dart';
import 'dio_client.dart';

/// Enum defining available HTTP methods
enum ApiMethod { get, post, put, patch, delete }

/// Riverpod provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

/// Universal API Service handling GET, POST, PUT, PATCH, and DELETE requests
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Main reusable request method
  Future<ApiResponse<T>> request<T>({
    required String path,
    required ApiMethod method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      Response response;

      switch (method) {
        case ApiMethod.get:
          response = await _dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
          break;
        case ApiMethod.post:
          response = await _dio.post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
          break;
        case ApiMethod.put:
          response = await _dio.put(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
          break;
        case ApiMethod.patch:
          response = await _dio.patch(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
          break;
        case ApiMethod.delete:
          response = await _dio.delete(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
          break;
      }

      final responseData = response.data;
      final parsedData = (fromJson != null && responseData != null) ? fromJson(responseData) : responseData as T?;

      return ApiResponse.success(parsedData, statusCode: response.statusCode, message: response.statusMessage);
    } on DioException catch (e) {
      return ApiResponse.failure(_handleDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return ApiResponse.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Shortcut for GET request
  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: ApiMethod.get, queryParameters: queryParameters, options: options, fromJson: fromJson);
  }

  /// Shortcut for POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(path: path, method: ApiMethod.post, data: data, queryParameters: queryParameters, options: options, fromJson: fromJson);
  }

  /// Shortcut for PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(path: path, method: ApiMethod.put, data: data, queryParameters: queryParameters, options: options, fromJson: fromJson);
  }

  /// Shortcut for PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(path: path, method: ApiMethod.patch, data: data, queryParameters: queryParameters, options: options, fromJson: fromJson);
  }

  /// Shortcut for DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(path: path, method: ApiMethod.delete, data: data, queryParameters: queryParameters, options: options, fromJson: fromJson);
  }

  /// Custom error handler for Dio exceptions
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'].toString();
        }
        return 'Server error ($statusCode). Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
