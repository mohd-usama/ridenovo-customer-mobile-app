/// Model representing Rider User details returned from Backend API
class UserModel {
  final String id;
  final String phone;
  final String? fullName;
  final String? email;
  final String role;
  final String? gender;
  final String? dateOfBirth;
  final String? profilePhoto;
  final bool isNewUser;
  final int totalRides;
  final String averageRating;
  final String? referralCode;

  UserModel({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
    this.role = 'rider',
    this.gender,
    this.dateOfBirth,
    this.profilePhoto,
    this.isNewUser = false,
    this.totalRides = 0,
    this.averageRating = '5.0',
    this.referralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested response format: { success: true, data: { profile: {...}, roleDetails: {...}, user: {...} } }
    final rootData = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final profile = rootData['profile'] is Map<String, dynamic>
        ? rootData['profile'] as Map<String, dynamic>
        : (rootData['user'] is Map<String, dynamic>
              ? rootData['user'] as Map<String, dynamic>
              : (json['profile'] is Map<String, dynamic>
                    ? json['profile'] as Map<String, dynamic>
                    : (json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : rootData)));

    final roleDetails = rootData['roleDetails'] is Map<String, dynamic>
        ? rootData['roleDetails'] as Map<String, dynamic>
        : (json['roleDetails'] is Map<String, dynamic> ? json['roleDetails'] as Map<String, dynamic> : null);

    return UserModel(
      id: profile['id']?.toString() ?? profile['_id']?.toString() ?? '',
      phone: profile['phone']?.toString() ?? profile['phoneNumber']?.toString() ?? '',
      fullName: profile['full_name']?.toString() ?? profile['fullName']?.toString() ?? profile['name']?.toString(),
      email: profile['email']?.toString(),
      role: profile['role']?.toString() ?? 'rider',
      gender: profile['gender']?.toString(),
      dateOfBirth: profile['date_of_birth']?.toString() ?? profile['dateOfBirth']?.toString(),
      profilePhoto: profile['profile_photo_url']?.toString() ?? profile['profilePhotoUrl']?.toString() ?? profile['profilePhoto']?.toString(),
      isNewUser: profile['isNewUser'] == true,
      totalRides: (roleDetails?['total_rides'] as num?)?.toInt() ?? 0,
      averageRating: roleDetails?['average_rating']?.toString() ?? '4.90',
      referralCode: roleDetails?['referral_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'email': email,
      'role': role,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'profilePhoto': profilePhoto,
      'isNewUser': isNewUser,
    };
  }
}

/// Session information returned upon successful rider login
class SessionModel {
  final String id;
  final String? expiresAt;
  final String? deviceName;

  SessionModel({required this.id, this.expiresAt, this.deviceName});

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(id: json['id']?.toString() ?? '', expiresAt: json['expiresAt']?.toString(), deviceName: json['deviceName']?.toString());
  }

  Map<String, dynamic> toJson() => {'id': id, 'expiresAt': expiresAt, 'deviceName': deviceName};
}

/// Response payload received after requesting OTP
class LoginResponse {
  final bool success;
  final String message;
  final int retryAfter;

  LoginResponse({required this.success, required this.message, this.retryAfter = 30});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    return LoginResponse(
      success: json['success'] ?? true,
      message: json['message']?.toString() ?? 'OTP sent successfully',
      retryAfter: (data?['retryAfter'] as num?)?.toInt() ?? (json['retryAfter'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Response payload -> Verify OTP
class VerifyOtpResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final SessionModel? session;

  VerifyOtpResponse({required this.success, required this.message, this.token, this.user, this.session});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final rootData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['result'] is Map<String, dynamic> ? json['result'] as Map<String, dynamic> : json);

    return VerifyOtpResponse(
      success: json['success'] ?? (json['status'] == 'success') ?? true,
      message: json['message']?.toString() ?? 'Login successful!',
      token: rootData['token']?.toString() ?? json['token']?.toString(),
      user: rootData['user'] != null && rootData['user'] is Map<String, dynamic>
          ? UserModel.fromJson(rootData['user'])
          : (json['user'] != null && json['user'] is Map<String, dynamic> ? UserModel.fromJson(json['user']) : null),
      session: rootData['session'] != null && rootData['session'] is Map<String, dynamic> ? SessionModel.fromJson(rootData['session']) : null,
    );
  }
}
