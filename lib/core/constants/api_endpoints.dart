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
  static const String deleteAccount = '/api/rider/account';

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

  // 6. Cancellation & History Endpoints
  static String riderCancelPreview(String rideId) => '/api/rider/rides/$rideId/cancel-preview';
  static String riderCancelRide(String rideId) => '/api/rider/rides/$rideId/cancel';
  static const String riderRidesHistory = '/api/rider/rides';

  // 7. Spending Summary Endpoint
  static const String riderSpendingSummary = '/api/rider/spending-summary';

  // 8. Favorite Drivers & Rating Endpoints
  static const String riderFavoriteDrivers = '/api/rider/drivers/favorites';
  static String riderFavoriteDriver(String driverId) => '/api/rider/drivers/$driverId/favorite';
  static String riderDriverAvailability(String driverId) => '/api/rider/drivers/$driverId/availability';
  static String riderRateRide(String rideId) => '/api/rider/rides/$rideId/rate';

  // 9. Customer Referral Program Endpoints
  static const String riderReferral = '/api/rider/referral';
  static const String riderReferralApply = '/api/rider/referral/apply';
  static const String riderReferralValidate = '/api/rider/referral/validate';

  // 10. Help, Support & AI Chat Endpoints
  static const String riderSupportCategories = '/api/rider/support/categories';
  static const String riderSupportTickets = '/api/rider/support/tickets';
  static String riderSupportTicketDetail(String id) => '/api/rider/support/tickets/$id';
  static String riderSupportTicketReply(String id) => '/api/rider/support/tickets/$id/reply';
  static const String riderSupportAiChat = '/api/rider/support/ai-chat';

  // 11. Promos & Offers Endpoints
  static const String riderPromosCatalog = '/api/rider/promos';
  static const String riderPromosValidate = '/api/rider/promos/validate';

  // 12. Razorpay Payment Endpoints
  static const String razorpayCreateOrder = '/api/rider/payment/razorpay/create-order';
  static const String razorpayVerify = '/api/rider/payment/razorpay/verify';

  // 13. Saved Passengers Endpoints
  static const String riderPassengers = '/api/rider/passengers';
  static String riderPassengerDetail(String id) => '/api/rider/passengers/$id';

  // Recent Places Endpoints
  static const String recentPlaces = '/api/places/recent';
  static String recentPlaceFavorite(String id) => '/api/places/recent/$id/favorite';
  static String recentPlaceDetail(String id) => '/api/places/recent/$id';

  // Legacy compatibility aliases
  static const String searchLocation = placesAutocomplete;
  static const String calculateFare = riderFareEstimate;
  static const String bookRide = riderBookRide;
  static const String rideStatus = '/api/rides/status';
  static const String cancelRide = '/api/rider/rides/cancel';
  static const String rideHistory = '/api/rides/history';
}
