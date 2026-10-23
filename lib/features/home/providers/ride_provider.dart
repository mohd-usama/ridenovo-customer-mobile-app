import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_response.dart';
import '../../../core/services/socket_service.dart';
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
  final double appliedDiscount;
  final double estimatedFare;
  final List<FareEstimateModel> fareEstimates;
  final List<LocationSuggestionModel> locationSuggestions;
  final List<LatLng> polylinePoints;
  final List<NearbyDriverModel> nearbyDrivers;
  final RideModel? currentRide;
  final RideModel? completedRide;
  final DriverLocationUpdate? liveDriverLocation;
  final String selectedPaymentMethod;
  final bool isBookingForSomeoneElse;
  final String? passengerName;
  final String? passengerPhone;
  final String? passengerRelation;
  final List<SavedPassengerModel> savedPassengers;
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
    this.appliedDiscount = 0.0,
    this.estimatedFare = 0.0,
    this.fareEstimates = const [],
    this.locationSuggestions = const [],
    this.polylinePoints = const [],
    this.nearbyDrivers = const [],
    this.currentRide,
    this.completedRide,
    this.liveDriverLocation,
    this.selectedPaymentMethod = 'cash',
    this.isBookingForSomeoneElse = false,
    this.passengerName,
    this.passengerPhone,
    this.passengerRelation = 'Friend',
    this.savedPassengers = const [],
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
    double? appliedDiscount,
    double? estimatedFare,
    List<FareEstimateModel>? fareEstimates,
    List<LocationSuggestionModel>? locationSuggestions,
    List<LatLng>? polylinePoints,
    List<NearbyDriverModel>? nearbyDrivers,
    RideModel? currentRide,
    bool clearCurrentRide = false,
    RideModel? completedRide,
    bool clearCompletedRide = false,
    DriverLocationUpdate? liveDriverLocation,
    bool clearLiveDriverLocation = false,
    String? selectedPaymentMethod,
    bool? isBookingForSomeoneElse,
    String? passengerName,
    String? passengerPhone,
    String? passengerRelation,
    bool clearPassenger = false,
    List<SavedPassengerModel>? savedPassengers,
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
      appliedDiscount: clearPromo ? 0.0 : (appliedDiscount ?? this.appliedDiscount),
      estimatedFare: estimatedFare ?? this.estimatedFare,
      fareEstimates: fareEstimates ?? this.fareEstimates,
      locationSuggestions: locationSuggestions ?? this.locationSuggestions,
      polylinePoints: clearDropLocation ? [] : (polylinePoints ?? this.polylinePoints),
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      currentRide: clearCurrentRide ? null : (currentRide ?? this.currentRide),
      completedRide: clearCompletedRide ? null : (completedRide ?? this.completedRide),
      liveDriverLocation: clearLiveDriverLocation ? null : (liveDriverLocation ?? this.liveDriverLocation),
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isBookingForSomeoneElse: isBookingForSomeoneElse ?? this.isBookingForSomeoneElse,
      passengerName: clearPassenger ? null : (passengerName ?? this.passengerName),
      passengerPhone: clearPassenger ? null : (passengerPhone ?? this.passengerPhone),
      passengerRelation: clearPassenger ? 'Friend' : (passengerRelation ?? this.passengerRelation),
      savedPassengers: savedPassengers ?? this.savedPassengers,
      isSearchingLocation: isSearchingLocation ?? this.isSearchingLocation,
      isCalculatingFare: isCalculatingFare ?? this.isCalculatingFare,
      isBooking: isBooking ?? this.isBooking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final rideHistoryProvider = FutureProvider.family<RideHistoryResponse, String>((ref, type) async {
  final repo = ref.watch(rideRepositoryProvider);
  final response = await repo.getRideHistory(type: type);
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  return RideHistoryResponse(rides: [], totalRides: 0, currentPage: 1, totalPages: 1, limit: 10);
});

class RideNotifier extends StateNotifier<RideState> {
  final RideRepository _rideRepository;
  final SocketService _socketService;
  final Ref _ref;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _statusSubscription;
  final Set<String> _handledCompletedRideIds = {};

  RideNotifier(this._rideRepository, this._socketService, this._ref) : super(const RideState()) {
    _initSocketListeners();
    checkActiveRideOnStartup();
  }

  void _invalidateRideHistory() {
    _ref.invalidate(rideHistoryProvider('complete'));
    _ref.invalidate(rideHistoryProvider('cancel'));
    _ref.invalidate(rideHistoryProvider('all'));
  }

  void _initSocketListeners() {
    _locationSubscription = _socketService.locationUpdates.listen((data) {
      print('📍 [RideNotifier] Live driver location update: $data');
      final locationUpdate = DriverLocationUpdate.fromJson(data);

      CaptainModel? updatedCaptain = state.currentRide?.captain;
      if (updatedCaptain != null) {
        updatedCaptain = CaptainModel(
          id: updatedCaptain.id.isNotEmpty ? updatedCaptain.id : locationUpdate.driverId,
          name: updatedCaptain.name != 'Captain' ? updatedCaptain.name : (locationUpdate.driverName ?? 'Captain'),
          phone: updatedCaptain.phone,
          rating: updatedCaptain.rating,
          vehicleNumber: locationUpdate.plateNumber ?? updatedCaptain.vehicleNumber,
          vehicleModel: updatedCaptain.vehicleModel,
          currentLat: locationUpdate.lat,
          currentLng: locationUpdate.lng,
        );
      } else {
        updatedCaptain = CaptainModel(
          id: locationUpdate.driverId,
          name: locationUpdate.driverName ?? 'Captain',
          phone: '',
          rating: 4.8,
          vehicleNumber: locationUpdate.plateNumber ?? '',
          vehicleModel: locationUpdate.vehicleType,
          currentLat: locationUpdate.lat,
          currentLng: locationUpdate.lng,
        );
      }

      RideModel? updatedRide = state.currentRide;
      if (updatedRide != null) {
        updatedRide = RideModel(
          rideId: updatedRide.rideId,
          status: updatedRide.status,
          pickupAddress: updatedRide.pickupAddress,
          pickupLat: updatedRide.pickupLat,
          pickupLng: updatedRide.pickupLng,
          dropAddress: updatedRide.dropAddress,
          dropLat: updatedRide.dropLat,
          dropLng: updatedRide.dropLng,
          rideType: updatedRide.rideType,
          fare: updatedRide.fare,
          otp: updatedRide.otp,
          captain: updatedCaptain,
          routePoints: updatedRide.routePoints,
          createdAt: updatedRide.createdAt,
        );
      }

      state = state.copyWith(liveDriverLocation: locationUpdate, currentRide: updatedRide);
    });

    _statusSubscription = _socketService.rideStatusUpdates.listen((data) {
      print('🔄 [RideNotifier] Ride status update: $data');
      final rideId = data['rideId']?.toString() ?? data['id']?.toString() ?? state.currentRide?.rideId ?? '';

      final rideData = data['ride'] is Map<String, dynamic>
          ? data['ride'] as Map<String, dynamic>
          : (data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data);

      final rawStatus =
          rideData['status']?.toString() ??
          rideData['step']?.toString() ??
          rideData['state']?.toString() ??
          rideData['ride_status']?.toString() ??
          data['status']?.toString() ??
          data['step']?.toString() ??
          data['state']?.toString() ??
          data['event']?.toString() ??
          data['type']?.toString();
      final otpCode = rideData['otp']?.toString() ?? rideData['otp_code']?.toString() ?? data['otp']?.toString() ?? data['otp_code']?.toString();

      final parsedStatus = parseRideStatus(rawStatus);

      // Guard: ignore events meant for a different ride
      if (state.currentRide != null && rideId.isNotEmpty && state.currentRide!.rideId.isNotEmpty && rideId != state.currentRide!.rideId) {
        print("⚠️ [RideNotifier] Status update for $rideId ignored because active ride is ${state.currentRide!.rideId}");
        return;
      }

      if (parsedStatus == RideStatus.completed) {
        _socketService.leaveRide(rideId);
        stopActiveRidePolling();
        _invalidateRideHistory();
        if (_handledCompletedRideIds.contains(rideId)) {
          print('⚠️ [Socket] Completion for $rideId already handled. Ignoring repeat trigger.');
          state = state.copyWith(clearCurrentRide: true);
          return;
        }
        _handledCompletedRideIds.add(rideId);
        print('🎉 [Socket] Ride completed! Setting completedRide & clearing currentRide.');
        final completedModel =
            state.currentRide ??
            RideModel(
              rideId: rideId,
              status: RideStatus.completed,
              pickupAddress: state.pickupAddress ?? '',
              pickupLat: state.pickupLocation?.latitude ?? 0,
              pickupLng: state.pickupLocation?.longitude ?? 0,
              dropAddress: state.dropAddress ?? '',
              dropLat: state.dropLocation?.latitude ?? 0,
              dropLng: state.dropLocation?.longitude ?? 0,
              rideType: state.selectedRideType,
              fare: state.estimatedFare,
            );
        state = state.copyWith(
          clearCurrentRide: true,
          completedRide: completedModel,
          clearDropLocation: true,
          clearPromo: true,
          clearLiveDriverLocation: true,
          fareEstimates: [],
          nearbyDrivers: [],
          polylinePoints: [],
        );
      } else if (parsedStatus == RideStatus.cancelled) {
        print('❌ [Socket] Ride cancelled! Clearing state.');
        _socketService.leaveRide(rideId);
        stopActiveRidePolling();
        _invalidateRideHistory();
        state = state.copyWith(
          clearCurrentRide: true,
          clearDropLocation: true,
          clearPromo: true,
          clearLiveDriverLocation: true,
          fareEstimates: [],
          nearbyDrivers: [],
          polylinePoints: [],
        );
      } else {
        if (state.currentRide != null) {
          final existing = state.currentRide!;
          final updatedRide = RideModel(
            rideId: existing.rideId,
            status: parsedStatus,
            pickupAddress: existing.pickupAddress,
            pickupLat: existing.pickupLat,
            pickupLng: existing.pickupLng,
            dropAddress: existing.dropAddress,
            dropLat: existing.dropLat,
            dropLng: existing.dropLng,
            rideType: existing.rideType,
            fare: existing.fare,
            otp: otpCode ?? existing.otp,
            captain: existing.captain,
            routePoints: existing.routePoints,
            createdAt: existing.createdAt,
          );
          state = state.copyWith(currentRide: updatedRide);
        }
      }
    });
  }

  Future<void> checkActiveRideOnStartup() async {
    print('🚀 [Startup Check] Checking if active ride exists...');
    final response = await _rideRepository.getActiveRide();
    if (response.isSuccess && response.data != null) {
      final ride = response.data!;
      print('🚀 [Startup Check] Found active ride: #${ride.rideId}, status: ${ride.status}');
      if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled) {
        if (ride.status == RideStatus.completed) {
          _handledCompletedRideIds.add(ride.rideId);
        }
        state = state.copyWith(
          clearCurrentRide: true,
          clearDropLocation: true,
          clearPromo: true,
          clearLiveDriverLocation: true,
          fareEstimates: [],
          nearbyDrivers: [],
          polylinePoints: [],
        );
      } else {
        state = state.copyWith(currentRide: ride, polylinePoints: ride.routePoints);
        _socketService.joinRide(ride.rideId);
        startActiveRidePolling();
      }
    } else {
      print('🚀 [Startup Check] No active ride found on startup.');
      state = state.copyWith(
        clearCurrentRide: true,
        clearDropLocation: true,
        clearPromo: true,
        clearLiveDriverLocation: true,
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

        if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
          addressComponents.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          addressComponents.add(place.name!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty && !addressComponents.contains(place.subLocality)) {
          addressComponents.add(place.subLocality!);
        }

        if (place.locality != null && place.locality!.isNotEmpty && !addressComponents.contains(place.locality)) {
          addressComponents.add(place.locality!);
        }

        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            !addressComponents.contains(place.subAdministrativeArea)) {
          addressComponents.add(place.subAdministrativeArea!);
        }

        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty && !addressComponents.contains(place.administrativeArea)) {
          addressComponents.add(place.administrativeArea!);
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressComponents.add(place.postalCode!);
        }

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

  void setPromoCode(String? code, {double discount = 0.0}) {
    if (code == null || code.trim().isEmpty) {
      state = state.copyWith(clearPromo: true, appliedDiscount: 0.0);
    } else {
      state = state.copyWith(promoCode: code, appliedDiscount: discount);
    }
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void setBookingForSomeoneElse({
    required bool isForSomeoneElse,
    String? name,
    String? phone,
    String? relation,
  }) {
    if (!isForSomeoneElse) {
      state = state.copyWith(
        isBookingForSomeoneElse: false,
        clearPassenger: true,
      );
    } else {
      state = state.copyWith(
        isBookingForSomeoneElse: true,
        passengerName: name,
        passengerPhone: phone,
        passengerRelation: relation ?? 'Friend',
      );
    }
  }

  Future<void> fetchSavedPassengers() async {
    final response = await _rideRepository.getSavedPassengers();
    if (response.isSuccess && response.data != null) {
      state = state.copyWith(savedPassengers: response.data);
    }
  }

  Future<bool> addSavedPassenger(SavedPassengerModel passenger) async {
    final response = await _rideRepository.addSavedPassenger(passenger);
    if (response.isSuccess && response.data != null) {
      final updatedList = [...state.savedPassengers, response.data!];
      state = state.copyWith(savedPassengers: updatedList);
      return true;
    }
    return false;
  }

  Future<bool> deleteSavedPassenger(String id) async {
    final response = await _rideRepository.deleteSavedPassenger(id);
    if (response.isSuccess) {
      final updatedList = state.savedPassengers.where((p) => p.id != id).toList();
      state = state.copyWith(savedPassengers: updatedList);
      return true;
    }
    return false;
  }

  /// Search locations for autocomplete
  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(locationSuggestions: []);
      return;
    }

    state = state.copyWith(isSearchingLocation: true);

    final request = SearchLocationRequest(query: query, latitude: state.pickupLocation?.latitude, longitude: state.pickupLocation?.longitude);

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
  Future<bool> bookRide({String? favoriteDriverId}) async {
    if (state.pickupLocation == null || state.dropLocation == null) {
      state = state.copyWith(errorMessage: 'Please select both pickup and drop location.');
      return false;
    }

    state = state.copyWith(isBooking: true, errorMessage: null);

    final match =
        state.fareEstimates.where((e) => e.vehicleTypeId == state.selectedVehicleTypeId).firstOrNull ?? state.fareEstimates.firstOrNull;
    final vehicleTypeId = match?.vehicleTypeId ?? 'c3fbfe46-b6b8-43d7-bb25-ab77582b1897';

    final netFare = (state.estimatedFare - state.appliedDiscount).clamp(0.0, 999999.0);

    final request = BookRideRequest(
      vehicleTypeId: vehicleTypeId,
      pickupAddress: state.pickupAddress ?? 'Pickup Location',
      pickupLat: state.pickupLocation!.latitude,
      pickupLng: state.pickupLocation!.longitude,
      dropAddress: state.dropAddress ?? 'Drop Location',
      dropLat: state.dropLocation!.latitude,
      dropLng: state.dropLocation!.longitude,
      paymentMethod: state.selectedPaymentMethod,
      promoCode: state.promoCode,
      favoriteDriverId: favoriteDriverId,
      fare: netFare,
      finalFare: netFare,
      originalFare: state.estimatedFare,
      isForSomeoneElse: state.isBookingForSomeoneElse,
      passengerName: state.passengerName,
      passengerPhone: state.passengerPhone,
      passengerRelation: state.passengerRelation,
      sendSmsToPassenger: true,
    );

    final response = await _rideRepository.bookRide(request);

    if (response.isSuccess && response.data != null) {
      state = state.copyWith(isBooking: false, currentRide: response.data);
      _socketService.joinRide(response.data!.rideId);
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

      if (response.isSuccess) {
        if (response.data != null) {
          final ride = response.data!;

          // Guard: ignore if polled ride ID does not match current active ride
          if (state.currentRide != null &&
              ride.rideId.isNotEmpty &&
              state.currentRide!.rideId.isNotEmpty &&
              ride.rideId != state.currentRide!.rideId) {
            print('⚠️ [Polling] Stale ride ID (${ride.rideId}) != active ride (${state.currentRide!.rideId}). Ignoring.');
            return;
          }

          if (ride.status == RideStatus.completed) {
            _socketService.leaveRide(ride.rideId);
            stopActiveRidePolling();
            _invalidateRideHistory();
            if (_handledCompletedRideIds.contains(ride.rideId)) {
              print('⚠️ [Polling] Completion for ${ride.rideId} already handled. Ignoring repeat trigger.');
              state = state.copyWith(clearCurrentRide: true);
              return;
            }
            _handledCompletedRideIds.add(ride.rideId);
            print('🎉 [Polling] Ride completed. Setting completedRide & clearing state.');
            state = state.copyWith(
              clearCurrentRide: true,
              completedRide: ride,
              clearDropLocation: true,
              clearPromo: true,
              clearLiveDriverLocation: true,
              fareEstimates: [],
              nearbyDrivers: [],
              polylinePoints: [],
            );
          } else if (ride.status == RideStatus.cancelled) {
            print('❌ [Polling] Ride cancelled (${ride.status}). Clearing state.');
            _socketService.leaveRide(ride.rideId);
            stopActiveRidePolling();
            _invalidateRideHistory();
            state = state.copyWith(
              clearCurrentRide: true,
              clearDropLocation: true,
              clearPromo: true,
              clearLiveDriverLocation: true,
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
          // If backend returns no active ride (null) and we currently have a ride in state
          if (state.currentRide != null) {
            final active = state.currentRide!;
            _socketService.leaveRide(active.rideId);
            stopActiveRidePolling();
            _invalidateRideHistory();

            if (active.status == RideStatus.inProgress || active.status == RideStatus.arrived) {
              print('🎉 [Polling] In-progress ride concluded on backend. Setting completedRide.');
              state = state.copyWith(
                clearCurrentRide: true,
                completedRide: active,
                clearDropLocation: true,
                clearPromo: true,
                clearLiveDriverLocation: true,
                fareEstimates: [],
                nearbyDrivers: [],
                polylinePoints: [],
              );
            } else {
              print('🚀 [Polling] Active ride cancelled/removed on backend. Clearing state.');
              state = state.copyWith(
                clearCurrentRide: true,
                clearDropLocation: true,
                clearPromo: true,
                clearLiveDriverLocation: true,
                fareEstimates: [],
                nearbyDrivers: [],
                polylinePoints: [],
              );
            }
          }
        }
      } else {
        print('⚠️ [Polling] Active ride check transient error (${response.message}). Retrying in next cycle...');
      }
    });
  }

  void stopActiveRidePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> cancelActiveRide(String rideId, {String reason = 'Changed my mind'}) async {
    print('🚀 [API Request] Cancelling ride: $rideId');

    // 1. Immediately stop polling timer to prevent race conditions & stale state overwrites
    stopActiveRidePolling();

    // 2. Emit socket cancel event & leave socket room
    _socketService.cancelRide(rideId, reason: reason);
    _socketService.leaveRide(rideId);

    // Invalidate cached ride history
    _invalidateRideHistory();

    // 3. Optimistically clear active ride state immediately so UI updates with 0ms delay
    state = state.copyWith(
      clearCurrentRide: true,
      clearDropLocation: true,
      clearPromo: true,
      clearLiveDriverLocation: true,
      fareEstimates: [],
      nearbyDrivers: [],
      polylinePoints: [],
    );

    // 4. Send cancellation request to backend
    try {
      final response = await _rideRepository.cancelRideWithReason(rideId, CancelRideRequest(reason: reason));
      print('🚀 [API Call Result] cancelActiveRide success: ${response.isSuccess}');
      return response.isSuccess;
    } catch (e) {
      print('❌ [API Call Error] Error cancelling ride: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    stopActiveRidePolling();
    super.dispose();
  }

  void clearCompletedRide() {
    state = state.copyWith(clearCompletedRide: true);
  }

  void resetRide() {
    state = const RideState();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return RideNotifier(repository, socketService, ref);
});

final recentPlacesProvider = FutureProvider<List<RecentPlaceModel>>((ref) async {
  final repo = ref.watch(rideRepositoryProvider);
  final response = await repo.getRecentPlaces();
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  return [];
});
