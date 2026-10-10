import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_service.dart';

import '../models/ride_models.dart';
import '../models/saved_address_model.dart';

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

  // Saved Addresses APIs
  Future<ApiResponse<List<SavedAddressModel>>> getSavedAddresses();
  Future<ApiResponse<SavedAddressModel>> addAddress(SavedAddressModel address);
  Future<ApiResponse<SavedAddressModel>> updateAddress(String id, SavedAddressModel address);
  Future<ApiResponse<bool>> deleteAddress(String id);
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
        final data = json['data'];
        if (data == null) return null;
        final rideJson = data is Map<String, dynamic> ? (data['ride'] ?? data) : data;
        if (rideJson is Map<String, dynamic>) {
          return RideModel.fromJson(rideJson);
        }
        return null;
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
    return await apiService.post<bool>(
      ApiEndpoints.riderCancelRide(rideId),
      data: request.toJson(),
      fromJson: (json) => json['success'] ?? true,
    );
  }
}
