/// Generic wrapper class for all API responses
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({required this.isSuccess, this.data, this.message, this.statusCode});

  /// Factory for successful responses
  factory ApiResponse.success(T? data, {int? statusCode, String? message}) {
    return ApiResponse<T>(isSuccess: true, data: data, statusCode: statusCode, message: message);
  }

  /// Factory for failed responses
  factory ApiResponse.failure(String message, {int? statusCode}) {
    return ApiResponse<T>(isSuccess: false, message: message, statusCode: statusCode);
  }
}
