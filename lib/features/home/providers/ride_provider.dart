import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_response.dart';
import '../data/models/ride_models.dart';
import '../data/repositories/ride_repository.dart';

enum RideType { bike, auto, cab }

class RideState {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final String? pickupAddress;
  final String? dropAddress;
  final RideType selectedRideType;
  final String? selectedVehicleTypeId;
  final String? promoCode;
  final double estimatedFare;
  final List<FareEstimateModel> fareEstimates;
  final List<LocationSuggestionModel> locationSuggestions;
  final List<LatLng> polylinePoints;
  final List<NearbyDriverModel> nearbyDrivers;
  final RideModel? currentRide;
  final bool isSearchingLocation;
  final bool isCalculatingFare;
  final bool isBooking;
  final String? errorMessage;

  const RideState({
    this.pickupLocation,
    this.dropLocation,
    this.pickupAddress,
    this.dropAddress,
    this.selectedRideType = RideType.bike,
    this.selectedVehicleTypeId,
    this.promoCode,
    this.estimatedFare = 0.0,
    this.fareEstimates = const [],
    this.locationSuggestions = const [],
    this.polylinePoints = const [],
    this.nearbyDrivers = const [],
    this.currentRide,
    this.isSearchingLocation = false,
    this.isCalculatingFare = false,
    this.isBooking = false,
    this.errorMessage,
  });

  RideState copyWith({
    LatLng? pickupLocation,
    LatLng? dropLocation,
    bool clearDropLocation = false,
    String? pickupAddress,
    String? dropAddress,
    RideType? selectedRideType,
    String? selectedVehicleTypeId,
    String? promoCode,
    bool clearPromo = false,
    double? estimatedFare,
    List<FareEstimateModel>? fareEstimates,
    List<LocationSuggestionModel>? locationSuggestions,
    List<LatLng>? polylinePoints,
    List<NearbyDriverModel>? nearbyDrivers,
    RideModel? currentRide,
    bool clearCurrentRide = false,
    bool? isSearchingLocation,
    bool? isCalculatingFare,
    bool? isBooking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RideState(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: clearDropLocation ? null : (dropLocation ?? this.dropLocation),
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: clearDropLocation ? null : (dropAddress ?? this.dropAddress),
      selectedRideType: selectedRideType ?? this.selectedRideType,
      selectedVehicleTypeId: clearCurrentRide ? null : (selectedVehicleTypeId ?? this.selectedVehicleTypeId),
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      estimatedFare: estimatedFare ?? this.estimatedFare,
      fareEstimates: fareEstimates ?? this.fareEstimates,
      locationSuggestions: locationSuggestions ?? this.locationSuggestions,
      polylinePoints: clearDropLocation ? [] : (polylinePoints ?? this.polylinePoints),
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      currentRide: clearCurrentRide ? null : (currentRide ?? this.currentRide),
      isSearchingLocation: isSearchingLocation ?? this.isSearchingLocation,
      isCalculatingFare: isCalculatingFare ?? this.isCalculatingFare,
      isBooking: isBooking ?? this.isBooking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  final RideRepository _rideRepository;

  RideNotifier(this._rideRepository) : super(const RideState()) {
    checkActiveRideOnStartup();
  }

  Future<void> checkActiveRideOnStartup() async {
    print('🚀 [Startup Check] Checking if active ride exists...');
    final response = await _rideRepository.getActiveRide();
    if (response.isSuccess && response.data != null) {
      final ride = response.data!;
      print('🚀 [Startup Check] Found active ride: #${ride.rideId}, status: ${ride.status}');
      if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled) {
        state = state.copyWith(
          clearCurrentRide: true,
          clearDropLocation: true,
          clearPromo: true,
          fareEstimates: [],
          nearbyDrivers: [],
          polylinePoints: [],
        );
      } else {
        state = state.copyWith(currentRide: ride, polylinePoints: ride.routePoints);
        startActiveRidePolling();
      }
    } else {
      print('🚀 [Startup Check] No active ride found on startup.');
      state = state.copyWith(
        clearCurrentRide: true,
        clearDropLocation: true,
        clearPromo: true,
        fareEstimates: [],
        nearbyDrivers: [],
        polylinePoints: [],
      );
    }
  }

  void setPickupLocation(LatLng location, String address) {
    state = state.copyWith(pickupLocation: location, pickupAddress: address);
    calculateFare();
  }

  /// Reverse geocodes coordinates and updates pickup location & detailed address
  Future<void> updatePickupFromCoordinates(LatLng location) async {
    state = state.copyWith(pickupLocation: location);
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressComponents = [];

        // Street / Building / Landmark
        if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
          addressComponents.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          addressComponents.add(place.name!);
        }

        // SubLocality / Area
        if (place.subLocality != null && place.subLocality!.isNotEmpty && !addressComponents.contains(place.subLocality)) {
          addressComponents.add(place.subLocality!);
        }

        // Locality / City
        if (place.locality != null && place.locality!.isNotEmpty && !addressComponents.contains(place.locality)) {
          addressComponents.add(place.locality!);
        }

        // District (subAdministrativeArea)
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            !addressComponents.contains(place.subAdministrativeArea)) {
          addressComponents.add(place.subAdministrativeArea!);
        }

        // State (administrativeArea)
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty &&
            !addressComponents.contains(place.administrativeArea)) {
          addressComponents.add(place.administrativeArea!);
        }

        // Pincode (postalCode)
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressComponents.add(place.postalCode!);
        }

        // Country
        if (place.country != null && place.country!.isNotEmpty && !addressComponents.contains(place.country)) {
          addressComponents.add(place.country!);
        }

        final fullAddress = addressComponents.isNotEmpty
            ? addressComponents.join(', ')
            : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

        state = state.copyWith(pickupAddress: fullAddress);
      } else {
        state = state.copyWith(pickupAddress: '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
      }
    } catch (_) {
      state = state.copyWith(pickupAddress: '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
    }
  }

  void setDropLocation(LatLng location, String address) {
    state = state.copyWith(dropLocation: location, dropAddress: address);
    calculateFare();
  }

  void clearDropLocation() {
    state = state.copyWith(clearDropLocation: true, fareEstimates: [], selectedVehicleTypeId: null);
  }

  void selectRideType(RideType type) {
    double fare = state.estimatedFare;
    final match = state.fareEstimates.where((e) => e.rideType == type).firstOrNull;
    if (match != null) {
      fare = match.fare;
      state = state.copyWith(selectedRideType: type, selectedVehicleTypeId: match.vehicleTypeId, estimatedFare: fare);
    } else {
      state = state.copyWith(selectedRideType: type, estimatedFare: fare);
    }
  }

  void selectVehicle(String vehicleTypeId, RideType type, double fare) {
    state = state.copyWith(selectedVehicleTypeId: vehicleTypeId, selectedRideType: type, estimatedFare: fare);
  }

  void setPromoCode(String? code) {
    state = state.copyWith(promoCode: code);
  }

  /// Search locations for autocomplete
  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(locationSuggestions: []);
      return;
    }

    state = state.copyWith(isSearchingLocation: true);

    final request = SearchLocationRequest(
      query: query,
      latitude: state.pickupLocation?.latitude,
      longitude: state.pickupLocation?.longitude,
    );

    final response = await _rideRepository.searchLocations(request);

    if (response.isSuccess && response.data != null) {
      state = state.copyWith(isSearchingLocation: false, locationSuggestions: response.data!);
    } else {
      state = state.copyWith(isSearchingLocation: false, errorMessage: response.message);
    }
  }

  /// Calculate dynamic fare, route polyline, and nearby drivers for selected pickup and drop points
  Future<void> calculateFare() async {
    if (state.pickupLocation == null || state.dropLocation == null) return;

    state = state.copyWith(isCalculatingFare: true);

    final request = CalculateFareRequest(
      pickupLat: state.pickupLocation!.latitude,
      pickupLng: state.pickupLocation!.longitude,
      dropLat: state.dropLocation!.latitude,
      dropLng: state.dropLocation!.longitude,
    );

    final routeRequest = RouteRequest(
      origin: RoutePoint(lat: state.pickupLocation!.latitude, lng: state.pickupLocation!.longitude),
      destination: RoutePoint(lat: state.dropLocation!.latitude, lng: state.dropLocation!.longitude),
    );

    final nearbyDriversRequest = NearbyDriversRequest(
      lat: state.pickupLocation!.latitude,
      lng: state.pickupLocation!.longitude,
      vehicleTypeId: state.selectedVehicleTypeId,
    );

    final results = await Future.wait([
      _rideRepository.calculateFare(request),
      _rideRepository.getRoute(routeRequest),
      _rideRepository.getNearbyDrivers(nearbyDriversRequest),
    ]);

    final fareResponse = results[0] as ApiResponse<List<FareEstimateModel>>;
    final routeResponse = results[1] as ApiResponse<RouteResponse>;
    final driversResponse = results[2] as ApiResponse<List<NearbyDriverModel>>;

    List<LatLng> decodedPoints = [];
    if (routeResponse.isSuccess && routeResponse.data != null) {
      final polylineStr = routeResponse.data!.polyline;
      if (polylineStr.isNotEmpty) {
        try {
          final polylinePointsPlugin = PolylinePoints();
          final result = polylinePointsPlugin.decodePolyline(polylineStr);
          decodedPoints = result.map((p) => LatLng(p.latitude, p.longitude)).toList();
        } catch (_) {}
      }
    }

    List<NearbyDriverModel> nearbyDrivers = [];
    if (driversResponse.isSuccess && driversResponse.data != null) {
      nearbyDrivers = driversResponse.data!;
    }

    if (fareResponse.isSuccess && fareResponse.data != null) {
      final estimates = fareResponse.data!;
      final firstEstimate = estimates.isNotEmpty ? estimates.first : null;
      final selectedId = state.selectedVehicleTypeId ?? firstEstimate?.vehicleTypeId;
      final match = estimates.where((e) => e.vehicleTypeId == selectedId).firstOrNull ?? firstEstimate;
      final selectedFare = match?.fare ?? 45.0;
      final selectedType = match?.rideType ?? RideType.bike;
      final selectedVehicleId = match?.vehicleTypeId;

      state = state.copyWith(
        isCalculatingFare: false,
        fareEstimates: estimates,
        estimatedFare: selectedFare,
        selectedRideType: selectedType,
        selectedVehicleTypeId: selectedVehicleId,
        polylinePoints: decodedPoints,
        nearbyDrivers: nearbyDrivers,
      );
    } else {
      state = state.copyWith(isCalculatingFare: false, polylinePoints: decodedPoints, nearbyDrivers: nearbyDrivers);
    }
  }

  /// Send ride booking request to API
  Future<bool> bookRide() async {
    if (state.pickupLocation == null || state.dropLocation == null) {
      state = state.copyWith(errorMessage: 'Please select both pickup and drop location.');
      return false;
    }

    state = state.copyWith(isBooking: true, errorMessage: null);

    final match =
        state.fareEstimates.where((e) => e.vehicleTypeId == state.selectedVehicleTypeId).firstOrNull ?? state.fareEstimates.firstOrNull;
    final vehicleTypeId = match?.vehicleTypeId ?? 'c3fbfe46-b6b8-43d7-bb25-ab77582b1897';

    final request = BookRideRequest(
      vehicleTypeId: vehicleTypeId,
      pickupAddress: state.pickupAddress ?? 'Pickup Location',
      pickupLat: state.pickupLocation!.latitude,
      pickupLng: state.pickupLocation!.longitude,
      dropAddress: state.dropAddress ?? 'Drop Location',
      dropLat: state.dropLocation!.latitude,
      dropLng: state.dropLocation!.longitude,
      paymentMethod: 'cash',
      promoCode: state.promoCode,
    );

    final response = await _rideRepository.bookRide(request);

    if (response.isSuccess && response.data != null) {
      state = state.copyWith(isBooking: false, currentRide: response.data);
      startActiveRidePolling();
      return true;
    } else {
      state = state.copyWith(isBooking: false, errorMessage: response.message ?? 'Failed to book ride. Please try again.');
      return false;
    }
  }

  Timer? _pollingTimer;

  void startActiveRidePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      print('🚀 [Polling] Checking active ride status...');
      final response = await _rideRepository.getActiveRide();
      print('🚀 [Polling Response] success: ${response.isSuccess}, data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final ride = response.data!;
        print('🚀 [Polling Ride] status: ${ride.status}');

        if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled) {
          print('🚀 [Polling] Ride completed or cancelled. Clearing state.');
          stopActiveRidePolling();
          state = state.copyWith(
            clearCurrentRide: true,
            clearDropLocation: true,
            clearPromo: true,
            fareEstimates: [],
            nearbyDrivers: [],
            polylinePoints: [],
          );
        } else {
          List<LatLng> points = state.polylinePoints;
          if (ride.routePoints.isNotEmpty) {
            points = ride.routePoints;
          }
          state = state.copyWith(currentRide: ride, polylinePoints: points);
        }
      } else {
        print('🚀 [Polling] No active ride found or error. Clearing state.');
        stopActiveRidePolling();
        state = state.copyWith(
          clearCurrentRide: true,
          clearDropLocation: true,
          clearPromo: true,
          fareEstimates: [],
          nearbyDrivers: [],
          polylinePoints: [],
        );
      }
    });
  }

  void stopActiveRidePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> cancelActiveRide(String rideId) async {
    print('🚀 [API Request] Cancelling ride: $rideId');
    final response = await _rideRepository.cancelRideWithReason(rideId, CancelRideRequest(reason: 'Changed my mind'));
    print('🚀 [API Response] Cancel ride success: ${response.isSuccess}, message: ${response.message}');

    stopActiveRidePolling();
    state = state.copyWith(clearCurrentRide: true, clearDropLocation: true, clearPromo: true, fareEstimates: [], nearbyDrivers: []);
    return true;
  }

  @override
  void dispose() {
    stopActiveRidePolling();
    super.dispose();
  }

  void resetRide() {
    state = const RideState();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return RideNotifier(repository);
});

final recentPlacesProvider = FutureProvider<List<RecentPlaceModel>>((ref) async {
  final repo = ref.watch(rideRepositoryProvider);
  final response = await repo.getRecentPlaces();
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  return [];
});
