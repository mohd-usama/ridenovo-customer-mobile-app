/// Centralized class for managing API Base URLs and Endpoints.
///
/// To switch to production live server, set [isProduction] to `true`.
class ApiEndpoints {
  /// Toggle this boolean flag to switch between local development server and live server.
  static const bool isProduction = true;

  /// Local development backend URL (10.0.2.2 points to host machine localhost from Android emulator).
  static const String localBaseUrl = 'http://10.0.2.2:5000';

  /// Production live server URL.
  static const String liveBaseUrl = 'http://103.160.107.238:5000';

  /// Active Base URL resolved dynamically based on environment setting.
  static String get baseUrl => isProduction ? liveBaseUrl : localBaseUrl;

  // Auth Endpoints
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String logout = '/api/auth/logout';

  // User & Profile Endpoints
  static const String profile = '/api/users/me';
  static const String updateProfile = '/api/users/me';
  static const String updateFcmToken = '/api/users/me/fcm-token';

  // Saved Addresses Endpoints
  static const String addresses = '/api/rider/addresses';
  static String addressDetail(String id) => '/api/rider/addresses/$id';

  // 1. Places & Route Endpoints
  static const String placesAutocomplete = '/api/places/autocomplete';
  static const String placesRoute = '/api/places/route';
  static const String nearbyDrivers = '/api/places/nearby-drivers';

  // 2. Fare & Promo Endpoints
  static const String riderFareEstimate = '/api/rider/fareestimate';
  static const String promoValidate = '/api/promo/validate';

  // 3. Booking Endpoints
  static const String riderBookRide = '/api/rider/rides/book';
  static const String riderAdvanceBookRide = '/api/rider/rides/book/advance';

  // 4. Post-Booking & Driver Details
  static const String riderActiveRide = '/api/rider/rides/active';
  static String riderDriverProfile(String rideId) => '/api/rider/rides/$rideId/driver';

  // 5. Plate Verify & OTP
  static String riderVerifyPlate(String rideId) => '/api/rider/rides/$rideId/plate-verify';
  static String riderGetOtp(String rideId) => '/api/rider/rides/$rideId/otp';

  // 6. Cancellation Endpoints
  static String riderCancelPreview(String rideId) => '/api/rider/rides/$rideId/cancel-preview';
  static String riderCancelRide(String rideId) => '/api/rider/rides/$rideId/cancel';

  // Legacy compatibility aliases
  static const String searchLocation = placesAutocomplete;
  static const String calculateFare = riderFareEstimate;
  static const String bookRide = riderBookRide;
  static const String rideStatus = '/api/rides/status';
  static const String cancelRide = '/api/rider/rides/cancel';
  static const String rideHistory = '/api/rides/history';
}
