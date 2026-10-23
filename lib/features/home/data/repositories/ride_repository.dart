import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_service.dart';

import '../models/ride_models.dart';
import '../models/saved_address_model.dart';
import '../models/spending_summary_model.dart';
import '../models/favorite_driver_model.dart';
import '../models/referral_model.dart';
import '../models/support_model.dart';
import '../models/promo_model.dart';

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RideRepositoryImpl(apiService: apiService);
});

abstract class RideRepository {
  Future<ApiResponse<List<LocationSuggestionModel>>> searchLocations(SearchLocationRequest request);
  Future<ApiResponse<List<NearbyDriverModel>>> getNearbyDrivers(NearbyDriversRequest request);
  Future<ApiResponse<RouteResponse>> getRoute(RouteRequest request);
  Future<ApiResponse<List<FareEstimateModel>>> calculateFare(CalculateFareRequest request);
  Future<ApiResponse<RideModel>> bookRide(BookRideRequest request);
  Future<ApiResponse<RideModel>> getRideStatus(String rideId);
  Future<ApiResponse<bool>> cancelRide(String rideId);
  Future<ApiResponse<Map<String, dynamic>>> validatePromo(PromoValidateRequest request);
  Future<ApiResponse<RideModel>> advanceBookRide(AdvanceBookRideRequest request);
  Future<ApiResponse<RideModel?>> getActiveRide();
  Future<ApiResponse<CaptainModel>> getDriverProfile(String rideId);
  Future<ApiResponse<bool>> verifyPlatePhoto(String rideId, PlateVerifyRequest request);
  Future<ApiResponse<String>> getRideOtp(String rideId);
  Future<ApiResponse<Map<String, dynamic>>> getCancelPreview(String rideId);
  Future<ApiResponse<bool>> cancelRideWithReason(String rideId, CancelRideRequest request);
  Future<ApiResponse<RideHistoryResponse>> getRideHistory({String type = 'all', int page = 1, int limit = 10});

  // Recent Places APIs
  Future<ApiResponse<List<RecentPlaceModel>>> getRecentPlaces();
  Future<ApiResponse<RecentPlaceModel>> toggleFavoriteRecentPlace(String id, {bool? isFavorite});
  Future<ApiResponse<RecentPlaceModel>> addRecentPlace(RecentPlaceModel place);
  Future<ApiResponse<bool>> deleteRecentPlace(String id);

  // Saved Addresses APIs
  Future<ApiResponse<List<SavedAddressModel>>> getSavedAddresses();
  Future<ApiResponse<SavedAddressModel>> addAddress(SavedAddressModel address);
  Future<ApiResponse<SavedAddressModel>> updateAddress(String id, SavedAddressModel address);
  Future<ApiResponse<bool>> deleteAddress(String id);

  // Saved Passengers APIs
  Future<ApiResponse<List<SavedPassengerModel>>> getSavedPassengers();
  Future<ApiResponse<SavedPassengerModel>> addSavedPassenger(SavedPassengerModel passenger);
  Future<ApiResponse<bool>> deleteSavedPassenger(String id);

  // Spending Summary API
  Future<ApiResponse<SpendingSummaryModel>> getSpendingSummary({int? year, int? month});

  // Favorite Drivers & Rating APIs
  Future<ApiResponse<FavoriteDriversListResponse>> getFavoriteDrivers();
  Future<ApiResponse<FavoriteDriverModel>> addFavoriteDriver(String driverId, {Map<String, dynamic>? details});
  Future<ApiResponse<bool>> removeFavoriteDriver(String driverId);
  Future<ApiResponse<DriverAvailabilityModel>> checkDriverAvailability(String driverId);
  Future<ApiResponse<bool>> rateRide(String rideId, RateRideRequest request);

  // Referral Program APIs
  Future<ApiResponse<ReferralResponseModel>> getReferralDetails();
  Future<ApiResponse<ApplyReferralResponseModel>> applyReferralCode(String code);
  Future<ApiResponse<ApplyReferralResponseModel>> validateReferralCode(String code);

  // Help, Support & AI Chat APIs
  Future<ApiResponse<SupportCategoriesResponse>> getSupportCategories();
  Future<ApiResponse<List<SupportTicketModel>>> getSupportTickets();
  Future<ApiResponse<SupportTicketModel>> getSupportTicketDetail(String ticketId);
  Future<ApiResponse<SupportTicketModel>> createSupportTicket({
    required String categoryId,
    String? rideId,
    required String subject,
    required String description,
  });
  Future<ApiResponse<SupportTicketModel>> replySupportTicket(String ticketId, String message);
  Future<ApiResponse<AiChatResponseModel>> sendAiChatMessage(String message);

  // Promos & Offers APIs
  Future<ApiResponse<PromoCatalogResponse>> getPromosCatalog({double? fare, String? vehicleType});
  Future<ApiResponse<PromoValidateResponse>> validatePromoCode({required String code, required double fareAmount});
}

class RideRepositoryImpl implements RideRepository {
  final ApiService apiService;

  RideRepositoryImpl({required this.apiService});

  @override
  Future<ApiResponse<List<LocationSuggestionModel>>> searchLocations(SearchLocationRequest request) async {
    return await apiService.get<List<LocationSuggestionModel>>(
      ApiEndpoints.searchLocation,
      queryParameters: request.toJson(),
      fromJson: (json) {
        final dataField = json['data'];
        List rawList = [];
        if (dataField is Map && dataField.containsKey('predictions')) {
          rawList = dataField['predictions'] as List? ?? [];
        } else if (dataField is List) {
          rawList = dataField;
        } else if (json is List) {
          rawList = json;
        }
        return rawList.map((e) => LocationSuggestionModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<List<NearbyDriverModel>>> getNearbyDrivers(NearbyDriversRequest request) async {
    return await apiService.get<List<NearbyDriverModel>>(
      ApiEndpoints.nearbyDrivers,
      queryParameters: request.toJson(),
      fromJson: (json) {
        final data = json['data'];
        final driversList = (data is Map<String, dynamic> ? data['drivers'] : null) as List? ?? (json is List ? json : []);
        return driversList.map((e) => NearbyDriverModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<RouteResponse>> getRoute(RouteRequest request) async {
    return await apiService.post<RouteResponse>(
      ApiEndpoints.placesRoute,
      data: request.toJson(),
      fromJson: (json) {
        final root = json['data'] is Map<String, dynamic> ? json['data'] : json;
        return RouteResponse.fromJson(root as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<List<FareEstimateModel>>> calculateFare(CalculateFareRequest request) async {
    return await apiService.post<List<FareEstimateModel>>(
      ApiEndpoints.calculateFare,
      data: request.toJson(),
      fromJson: (json) {
        final data = json['data'];
        final estimatesList = (data is Map<String, dynamic> ? data['estimates'] : null) as List? ?? (json is List ? json : []);
        final tripSummary = data is Map<String, dynamic> ? (data['tripSummary'] as Map<String, dynamic>? ?? {}) : {};
        final distanceKm = (tripSummary['distanceKm'] as num?)?.toDouble() ?? 0.0;
        final durationMinutes = (tripSummary['durationMinutes'] as num?)?.toInt() ?? 0;

        return estimatesList.map((e) {
          final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
          map['distanceKm'] = map['distanceKm'] ?? distanceKm;
          map['durationMinutes'] = map['durationMinutes'] ?? durationMinutes;
          return FareEstimateModel.fromJson(map);
        }).toList();
      },
    );
  }

  @override
  Future<ApiResponse<RideModel>> bookRide(BookRideRequest request) async {
    return await apiService.post<RideModel>(
      ApiEndpoints.bookRide,
      data: request.toJson(),
      fromJson: (json) {
        final root = json['data'] is Map<String, dynamic> ? json['data'] : json;
        return RideModel.fromJson(root as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<RideModel>> getRideStatus(String rideId) async {
    return await apiService.get<RideModel>(
      '${ApiEndpoints.rideStatus}/$rideId',
      fromJson: (json) {
        final root = json['data'] is Map<String, dynamic> ? json['data'] : json;
        return RideModel.fromJson(root as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<bool>> cancelRide(String rideId) async {
    return await apiService.post<bool>('${ApiEndpoints.cancelRide}/$rideId', fromJson: (json) => json['success'] ?? true);
  }

  @override
  Future<ApiResponse<List<SavedAddressModel>>> getSavedAddresses() async {
    return await apiService.get<List<SavedAddressModel>>(
      ApiEndpoints.addresses,
      fromJson: (json) {
        final root = json['data'] is List ? json['data'] : (json is List ? json : []);
        return (root as List).map((e) => SavedAddressModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<SavedAddressModel>> addAddress(SavedAddressModel address) async {
    return await apiService.post<SavedAddressModel>(
      ApiEndpoints.addresses,
      data: address.toJson(),
      fromJson: (json) {
        final root = json['data'] is Map<String, dynamic> ? json['data'] : json;
        return SavedAddressModel.fromJson(root as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<SavedAddressModel>> updateAddress(String id, SavedAddressModel address) async {
    return await apiService.put<SavedAddressModel>(
      ApiEndpoints.addressDetail(id),
      data: address.toJson(),
      fromJson: (json) {
        final root = json['data'] is Map<String, dynamic> ? json['data'] : json;
        return SavedAddressModel.fromJson(root as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<bool>> deleteAddress(String id) async {
    return await apiService.delete<bool>(ApiEndpoints.addressDetail(id), fromJson: (json) => json['success'] ?? true);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> validatePromo(PromoValidateRequest request) async {
    return await apiService.post<Map<String, dynamic>>(
      ApiEndpoints.promoValidate,
      data: request.toJson(),
      fromJson: (json) {
        return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : (json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<RideModel>> advanceBookRide(AdvanceBookRideRequest request) async {
    return await apiService.post<RideModel>(
      ApiEndpoints.riderAdvanceBookRide,
      data: request.toJson(),
      fromJson: (json) {
        final data = json['data'];
        final rideJson = data is Map<String, dynamic> ? (data['ride'] ?? data) : json;
        return RideModel.fromJson(rideJson as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<RideModel?>> getActiveRide() async {
    return await apiService.get<RideModel?>(
      ApiEndpoints.riderActiveRide,
      fromJson: (json) {
        if (json == null) return null;

        dynamic rideData = json;
        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            rideData = json['data'];
          }
          if (rideData is Map<String, dynamic> && rideData.containsKey('ride')) {
            rideData = rideData['ride'];
          }
        }

        if (rideData == null || rideData is! Map<String, dynamic> || rideData.isEmpty) {
          return null;
        }

        final ride = RideModel.fromJson(rideData);
        if (ride.rideId.isEmpty) return null;
        return ride;
      },
    );
  }

  @override
  Future<ApiResponse<CaptainModel>> getDriverProfile(String rideId) async {
    return await apiService.get<CaptainModel>(
      ApiEndpoints.riderDriverProfile(rideId),
      fromJson: (json) {
        final data = json['data'];
        final driverJson = data is Map<String, dynamic> ? (data['driver'] ?? data) : json;
        return CaptainModel.fromJson(driverJson as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<bool>> verifyPlatePhoto(String rideId, PlateVerifyRequest request) async {
    return await apiService.post<bool>(
      ApiEndpoints.riderVerifyPlate(rideId),
      data: request.toJson(),
      fromJson: (json) => json['success'] ?? true,
    );
  }

  @override
  Future<ApiResponse<String>> getRideOtp(String rideId) async {
    return await apiService.get<String>(
      ApiEndpoints.riderGetOtp(rideId),
      fromJson: (json) {
        final data = json['data'];
        if (data is Map) {
          return data['otp']?.toString() ?? data['otp_code']?.toString() ?? '';
        }
        return data?.toString() ?? '';
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getCancelPreview(String rideId) async {
    return await apiService.get<Map<String, dynamic>>(
      ApiEndpoints.riderCancelPreview(rideId),
      fromJson: (json) {
        return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : (json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<bool>> cancelRideWithReason(String rideId, CancelRideRequest request) async {
    print('🚀 [API Call] POST ${ApiEndpoints.riderCancelRide(rideId)} with body: ${request.toJson()}');
    var response = await apiService.post<bool>(
      ApiEndpoints.riderCancelRide(rideId),
      data: request.toJson(),
      fromJson: (json) => json['success'] ?? true,
    );

    // Fallback if primary endpoint fails
    if (!response.isSuccess) {
      print('⚠️ [API Call] Primary cancel endpoint failed (${response.message}). Trying fallback: ${ApiEndpoints.cancelRide}/$rideId');
      response = await apiService.post<bool>(
        '${ApiEndpoints.cancelRide}/$rideId',
        data: request.toJson(),
        fromJson: (json) => json['success'] ?? true,
      );
    }

    print('🚀 [API Call Result] cancelRideWithReason success: ${response.isSuccess}, data: ${response.data}');
    return response;
  }

  @override
  Future<ApiResponse<RideHistoryResponse>> getRideHistory({String type = 'all', int page = 1, int limit = 10}) async {
    return await apiService.get<RideHistoryResponse>(
      ApiEndpoints.riderRidesHistory,
      queryParameters: {'type': type, 'page': page, 'limit': limit},
      fromJson: (json) {
        return RideHistoryResponse.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<List<RecentPlaceModel>>> getRecentPlaces() async {
    return await apiService.get<List<RecentPlaceModel>>(
      ApiEndpoints.recentPlaces,
      fromJson: (json) {
        final data = json['data'];
        final placesList = data is Map ? (data['places'] is List ? data['places'] : []) : (json is List ? json : []);
        return (placesList as List).map((e) => RecentPlaceModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<RecentPlaceModel>> toggleFavoriteRecentPlace(String id, {bool? isFavorite}) async {
    return await apiService.post<RecentPlaceModel>(
      ApiEndpoints.recentPlaceFavorite(id),
      data: isFavorite != null ? {'isFavorite': isFavorite} : null,
      fromJson: (json) {
        final data = json['data'];
        final placeJson = data is Map ? (data['place'] ?? data) : json;
        return RecentPlaceModel.fromJson(placeJson as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<RecentPlaceModel>> addRecentPlace(RecentPlaceModel place) async {
    return await apiService.post<RecentPlaceModel>(
      ApiEndpoints.recentPlaces,
      data: place.toJson(),
      fromJson: (json) {
        final data = json['data'];
        final placeJson = data is Map ? (data['place'] ?? data) : json;
        return RecentPlaceModel.fromJson(placeJson as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<bool>> deleteRecentPlace(String id) async {
    return await apiService.delete<bool>(ApiEndpoints.recentPlaceDetail(id), fromJson: (json) => json['success'] ?? true);
  }

  @override
  Future<ApiResponse<SpendingSummaryModel>> getSpendingSummary({int? year, int? month}) async {
    final Map<String, dynamic> params = {};
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;

    return await apiService.get<SpendingSummaryModel>(
      ApiEndpoints.riderSpendingSummary,
      queryParameters: params.isNotEmpty ? params : null,
      fromJson: (json) {
        final data = json['data'];
        final root = data is Map<String, dynamic> ? data : (json is Map<String, dynamic> ? json : <String, dynamic>{});
        return SpendingSummaryModel.fromJson(root);
      },
    );
  }

  @override
  Future<ApiResponse<FavoriteDriversListResponse>> getFavoriteDrivers() async {
    return await apiService.get<FavoriteDriversListResponse>(
      ApiEndpoints.riderFavoriteDrivers,
      fromJson: (json) {
        return FavoriteDriversListResponse.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<FavoriteDriverModel>> addFavoriteDriver(String driverId, {Map<String, dynamic>? details}) async {
    return await apiService.post<FavoriteDriverModel>(
      ApiEndpoints.riderFavoriteDriver(driverId),
      data: details,
      fromJson: (json) {
        final data = json['data'];
        final favJson = data is Map<String, dynamic> ? (data['favorite'] ?? data) : json;
        return FavoriteDriverModel.fromJson(favJson as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<bool>> removeFavoriteDriver(String driverId) async {
    return await apiService.delete<bool>(
      ApiEndpoints.riderFavoriteDriver(driverId),
      fromJson: (json) {
        final data = json['data'];
        if (data is Map && data.containsKey('isRemoved')) {
          return data['isRemoved'] == true;
        }
        return json['success'] ?? true;
      },
    );
  }

  @override
  Future<ApiResponse<DriverAvailabilityModel>> checkDriverAvailability(String driverId) async {
    return await apiService.get<DriverAvailabilityModel>(
      ApiEndpoints.riderDriverAvailability(driverId),
      fromJson: (json) {
        return DriverAvailabilityModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<bool>> rateRide(String rideId, RateRideRequest request) async {
    return await apiService.post<bool>(ApiEndpoints.riderRateRide(rideId), data: request.toJson(), fromJson: (json) => json['success'] ?? true);
  }

  @override
  Future<ApiResponse<ReferralResponseModel>> getReferralDetails() async {
    return await apiService.get<ReferralResponseModel>(
      ApiEndpoints.riderReferral,
      fromJson: (json) {
        return ReferralResponseModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<ApplyReferralResponseModel>> applyReferralCode(String code) async {
    return await apiService.post<ApplyReferralResponseModel>(
      ApiEndpoints.riderReferralApply,
      data: {'code': code},
      fromJson: (json) {
        return ApplyReferralResponseModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<ApplyReferralResponseModel>> validateReferralCode(String code) async {
    return await apiService.post<ApplyReferralResponseModel>(
      ApiEndpoints.riderReferralValidate,
      data: {'code': code},
      fromJson: (json) {
        return ApplyReferralResponseModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<SupportCategoriesResponse>> getSupportCategories() async {
    return await apiService.get<SupportCategoriesResponse>(
      ApiEndpoints.riderSupportCategories,
      fromJson: (json) {
        return SupportCategoriesResponse.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<List<SupportTicketModel>>> getSupportTickets() async {
    return await apiService.get<List<SupportTicketModel>>(
      ApiEndpoints.riderSupportTickets,
      fromJson: (json) {
        final data = json['data'];
        final list = data is Map ? (data['tickets'] is List ? data['tickets'] as List : []) : (json is List ? json : []);
        return (list as List)
            .where((e) => e != null && e is Map)
            .map((e) => SupportTicketModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  @override
  Future<ApiResponse<SupportTicketModel>> getSupportTicketDetail(String ticketId) async {
    return await apiService.get<SupportTicketModel>(
      ApiEndpoints.riderSupportTicketDetail(ticketId),
      fromJson: (json) {
        return SupportTicketModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<SupportTicketModel>> createSupportTicket({
    required String categoryId,
    String? rideId,
    required String subject,
    required String description,
  }) async {
    return await apiService.post<SupportTicketModel>(
      ApiEndpoints.riderSupportTickets,
      data: {
        'categoryId': categoryId,
        if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
        'subject': subject,
        'description': description,
      },
      fromJson: (json) {
        return SupportTicketModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<SupportTicketModel>> replySupportTicket(String ticketId, String message) async {
    return await apiService.post<SupportTicketModel>(
      ApiEndpoints.riderSupportTicketReply(ticketId),
      data: {'message': message},
      fromJson: (json) {
        return SupportTicketModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<AiChatResponseModel>> sendAiChatMessage(String message) async {
    return await apiService.post<AiChatResponseModel>(
      ApiEndpoints.riderSupportAiChat,
      data: {'message': message},
      fromJson: (json) {
        return AiChatResponseModel.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<PromoCatalogResponse>> getPromosCatalog({double? fare, String? vehicleType}) async {
    final Map<String, dynamic> params = {};
    if (fare != null) params['fare'] = fare;
    if (vehicleType != null && vehicleType.isNotEmpty) params['vehicleType'] = vehicleType;

    return await apiService.get<PromoCatalogResponse>(
      ApiEndpoints.riderPromosCatalog,
      queryParameters: params.isNotEmpty ? params : null,
      fromJson: (json) {
        return PromoCatalogResponse.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<PromoValidateResponse>> validatePromoCode({required String code, required double fareAmount}) async {
    return await apiService.post<PromoValidateResponse>(
      ApiEndpoints.riderPromosValidate,
      data: {'code': code, 'fareAmount': fareAmount},
      fromJson: (json) {
        return PromoValidateResponse.fromJson(json is Map<String, dynamic> ? json : {});
      },
    );
  }

  @override
  Future<ApiResponse<List<SavedPassengerModel>>> getSavedPassengers() async {
    return await apiService.get<List<SavedPassengerModel>>(
      ApiEndpoints.riderPassengers,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['data'] is List) {
          return (json['data'] as List).map((e) => SavedPassengerModel.fromJson(e as Map<String, dynamic>)).toList();
        } else if (json is List) {
          return json.map((e) => SavedPassengerModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<SavedPassengerModel>> addSavedPassenger(SavedPassengerModel passenger) async {
    return await apiService.post<SavedPassengerModel>(
      ApiEndpoints.riderPassengers,
      data: passenger.toJson(),
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          Map<String, dynamic> map = json;
          if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
            final dataMap = map['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('passenger') && dataMap['passenger'] is Map<String, dynamic>) {
              map = dataMap['passenger'] as Map<String, dynamic>;
            } else {
              map = dataMap;
            }
          }
          return SavedPassengerModel.fromJson(map);
        }
        return SavedPassengerModel(id: '', name: '', phone: '');
      },
    );
  }

  @override
  Future<ApiResponse<bool>> deleteSavedPassenger(String id) async {
    return await apiService.delete<bool>(
      ApiEndpoints.riderPassengerDetail(id),
      fromJson: (json) => json is Map ? (json['success'] ?? true) : true,
    );
  }
}
