import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/auth_models.dart';
import '../data/repositories/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? phoneNumber;
  final String countryCode;
  final int retryAfter;
  final UserModel? user;
  final String? successMessage;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.phoneNumber,
    this.countryCode = '+91',
    this.retryAfter = 30,
    this.user,
    this.successMessage,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? phoneNumber,
    String? countryCode,
    int? retryAfter,
    UserModel? user,
    String? successMessage,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      retryAfter: retryAfter ?? this.retryAfter,
      user: user ?? this.user,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    checkAuthStatus();
  }

  /// Check if rider user has an existing saved auth token locally on app launch (No network delay)
  Future<void> checkAuthStatus() async {
    final token = await _authRepository.getSavedToken();
    final isNewUser = await _authRepository.getSavedIsNewUser();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        user: UserModel(id: '', phone: '', isNewUser: isNewUser),
      );
    }
  }

  /// Fetch user profile from API in background (called on Home / Dashboard screen)
  Future<void> fetchUserProfile() async {
    final profileRes = await _authRepository.getUserProfile();
    if (profileRes.isSuccess && profileRes.data != null) {
      state = state.copyWith(user: profileRes.data);
    }
  }

  /// Request Rider OTP from backend API (`/api/auth/send-otp`)
  Future<bool> sendOtp(String phone, {String countryCode = '+91'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final body = {'phone': phone, 'countryCode': countryCode, 'role': 'rider'};
    final response = await _authRepository.sendOtp(body);

    if (response.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phone,
        countryCode: countryCode,
        retryAfter: response.data?.retryAfter ?? 30,
        successMessage: response.data?.message ?? response.message,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message ?? 'Failed to send OTP');
      return false;
    }
  }

  /// Resend Rider OTP (`/api/auth/resend-otp`)
  Future<bool> resendOtp() async {
    if (state.phoneNumber == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final body = {'phone': state.phoneNumber!, 'countryCode': state.countryCode};

    final response = await _authRepository.resendOtp(body);

    if (response.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        retryAfter: response.data?.retryAfter ?? 30,
        successMessage: response.data?.message ?? response.message,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message ?? 'Failed to resend OTP');
      return false;
    }
  }

  /// Verify Rider OTP with backend API (`/api/auth/verify-otp`)
  Future<bool> verifyOtp(String otp, {String? fcmToken}) async {
    if (state.phoneNumber == null) {
      state = state.copyWith(errorMessage: 'Phone number not found. Please resend OTP.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'mobile');

    final body = {
      'phone': state.phoneNumber!,
      'otp': otp,
      'role': 'rider',
      'deviceId': 'rider_device_${state.phoneNumber}',
      'deviceName': Platform.operatingSystem,
      'devicePlatform': platform,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };

    final response = await _authRepository.verifyOtp(body);

    if (response.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.data?.user,
        successMessage: response.data?.message ?? response.message,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message ?? 'Invalid OTP code');
      return false;
    }
  }

  /// Update user profile details (`PUT /api/users/me`)
  Future<bool> updateProfile(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final response = await _authRepository.updateProfile(body);

    if (response.isSuccess && response.data != null) {
      final updatedUser = UserModel(
        id: response.data!.id,
        phone: response.data!.phone,
        fullName: response.data!.fullName,
        email: response.data!.email,
        role: response.data!.role,
        gender: response.data!.gender,
        dateOfBirth: response.data!.dateOfBirth,
        profilePhoto: response.data!.profilePhoto,
        isNewUser: false, // Mark profile setup as completed
        totalRides: response.data!.totalRides,
        averageRating: response.data!.averageRating,
        referralCode: response.data!.referralCode,
      );

      state = state.copyWith(isLoading: false, user: updatedUser, successMessage: 'Profile updated successfully!');
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message ?? 'Failed to update profile');
      return false;
    }
  }

  /// Logout rider user and clear credentials
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
