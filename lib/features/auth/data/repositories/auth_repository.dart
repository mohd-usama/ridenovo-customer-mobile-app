import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_service.dart';

import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepositoryImpl(apiService: apiService);
});

abstract class AuthRepository {
  Future<ApiResponse<LoginResponse>> sendOtp(Map<String, dynamic> body);
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(Map<String, dynamic> body);
  Future<ApiResponse<LoginResponse>> resendOtp(Map<String, dynamic> body);
  Future<ApiResponse<UserModel>> getUserProfile();
  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> body);
  Future<ApiResponse<bool>> updateFcmToken(String fcmToken);
  Future<void> logout();
  Future<String?> getSavedToken();
  Future<void> saveToken(String token);
  Future<bool> getSavedIsNewUser();
  Future<void> saveIsNewUser(bool isNewUser);
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  static const String _isNewUserKey = 'is_new_user';

  AuthRepositoryImpl({required this.apiService, FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<ApiResponse<LoginResponse>> sendOtp(Map<String, dynamic> body) async {
    return await apiService.post<LoginResponse>(
      ApiEndpoints.sendOtp,
      data: body,
      fromJson: (json) =>
          json is Map<String, dynamic> ? LoginResponse.fromJson(json) : LoginResponse(success: false, message: 'Invalid response'),
    );
  }

  @override
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(Map<String, dynamic> body) async {
    final response = await apiService.post<VerifyOtpResponse>(
      ApiEndpoints.verifyOtp,
      data: body,
      fromJson: (json) =>
          json is Map<String, dynamic> ? VerifyOtpResponse.fromJson(json) : VerifyOtpResponse(success: false, message: 'Invalid response'),
    );

    if (response.isSuccess && response.data?.token != null) {
      await saveToken(response.data!.token!);
      if (response.data?.user != null) {
        await saveIsNewUser(response.data!.user!.isNewUser);
      }
    }

    return response;
  }

  @override
  Future<ApiResponse<LoginResponse>> resendOtp(Map<String, dynamic> body) async {
    return await apiService.post<LoginResponse>(
      ApiEndpoints.resendOtp,
      data: body,
      fromJson: (json) =>
          json is Map<String, dynamic> ? LoginResponse.fromJson(json) : LoginResponse(success: false, message: 'Invalid response'),
    );
  }

  @override
  Future<ApiResponse<UserModel>> getUserProfile() async {
    return await apiService.get<UserModel>(
      ApiEndpoints.profile,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
          return UserModel.fromJson(data);
        }
        return UserModel(id: '', phone: '', role: 'rider');
      },
    );
  }

  @override
  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> body) async {
    final response = await apiService.put<UserModel>(
      ApiEndpoints.updateProfile,
      data: body,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
          return UserModel.fromJson(data);
        }
        return UserModel(id: '', phone: '', role: 'rider', isNewUser: false);
      },
    );

    if (response.isSuccess) {
      await saveIsNewUser(false);
    }

    return response;
  }

  @override
  Future<ApiResponse<bool>> updateFcmToken(String fcmToken) async {
    final response = await apiService.post<bool>(
      ApiEndpoints.updateFcmToken,
      data: {'fcmToken': fcmToken},
      fromJson: (json) => json['success'] ?? true,
    );
    return response;
  }

  @override
  Future<void> logout() async {
    try {
      await apiService.post(ApiEndpoints.logout);
    } catch (_) {}
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _isNewUserKey);
  }

  @override
  Future<String?> getSavedToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<bool> getSavedIsNewUser() async {
    final val = await _secureStorage.read(key: _isNewUserKey);
    return val == 'true';
  }

  @override
  Future<void> saveIsNewUser(bool isNewUser) async {
    await _secureStorage.write(key: _isNewUserKey, value: isNewUser ? 'true' : 'false');
  }
}
