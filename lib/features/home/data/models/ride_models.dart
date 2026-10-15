import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/ride_provider.dart';

/// Request model for location autocomplete/search API
class SearchLocationRequest {
  final String query;
  final double? latitude;
  final double? longitude;

  SearchLocationRequest({required this.query, this.latitude, this.longitude});

  Map<String, dynamic> toJson() => {
    'input': query,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

/// Model for location autocomplete suggestions
class LocationSuggestionModel {
  final String placeId;
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;

  LocationSuggestionModel({required this.placeId, required this.title, required this.subtitle, this.latitude, this.longitude});

  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    return LocationSuggestionModel(
      placeId: json['placeId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['mainText']?.toString() ?? json['title']?.toString() ?? json['description']?.toString() ?? '',
      subtitle: json['secondaryText']?.toString() ?? json['subtitle']?.toString() ?? json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'placeId': placeId, 'title': title, 'subtitle': subtitle, 'latitude': latitude, 'longitude': longitude};
}

/// Request payload for calculating fare estimation
class CalculateFareRequest {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  CalculateFareRequest({required this.pickupLat, required this.pickupLng, required this.dropLat, required this.dropLng});

  Map<String, dynamic> toJson() => {
    'origin': {'lat': pickupLat, 'lng': pickupLng},
    'destination': {'lat': dropLat, 'lng': dropLng},
  };
}

/// Model representing dynamic fare estimate for various ride options
class FareEstimateModel {
  final String? vehicleTypeId;
  final String vehicleTypeName;
  final RideType rideType;
  final double fare;
  final double distanceKm;
  final int durationMinutes;
  final int etaMinutes;
  final int availableDrivers;

  FareEstimateModel({
    this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.rideType,
    required this.fare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.etaMinutes,
    required this.availableDrivers,
  });

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['vehicleTypeName'] ?? json['rideType'])?.toString().toLowerCase() ?? 'bike';
    RideType parsedType = RideType.bike;
    if (typeStr.contains('auto')) {
      parsedType = RideType.auto;
    } else if (typeStr.contains('cab') ||
        typeStr.contains('car') ||
        typeStr.contains('mini') ||
        typeStr.contains('sedan') ||
        typeStr.contains('suv')) {
      parsedType = RideType.cab;
    }

    return FareEstimateModel(
      vehicleTypeId: json['vehicleTypeId']?.toString(),
      vehicleTypeName: json['vehicleTypeName']?.toString() ?? 'Ride',
      rideType: parsedType,
      fare: (json['totalFare'] ?? json['fare'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 3,
      availableDrivers: (json['availableDrivers'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicleTypeId': vehicleTypeId,
    'vehicleTypeName': vehicleTypeName,
    'rideType': rideType.name,
    'fare': fare,
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
    'etaMinutes': etaMinutes,
    'availableDrivers': availableDrivers,
  };
}

/// Request payload for booking a ride
class BookRideRequest {
  final String vehicleTypeId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final String paymentMethod;
  final String? promoCode;

  BookRideRequest({
    required this.vehicleTypeId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    this.paymentMethod = 'cash',
    this.promoCode,
  });

  Map<String, dynamic> toJson() => {
    'vehicleTypeId': vehicleTypeId,
    'pickup': {'lat': pickupLat, 'lng': pickupLng, 'address': pickupAddress},
    'drop': {'lat': dropLat, 'lng': dropLng, 'address': dropAddress},
    'paymentMethod': paymentMethod,
    if (promoCode != null && promoCode!.trim().isNotEmpty) 'promoCode': promoCode!.trim(),
  };
}

/// Captain / Driver model details attached to accepted ride
class CaptainModel {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final String vehicleNumber;
  final String vehicleModel;
  final double? currentLat;
  final double? currentLng;

  CaptainModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.vehicleNumber,
    required this.vehicleModel,
    this.currentLat,
    this.currentLng,
  });

  factory CaptainModel.fromJson(Map<String, dynamic> json) {
    return CaptainModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['fullName']?.toString() ?? json['name']?.toString() ?? 'Captain',
      phone: json['phone']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'rating': rating,
    'vehicleNumber': vehicleNumber,
    'vehicleModel': vehicleModel,
    'currentLat': currentLat,
    'currentLng': currentLng,
  };
}

/// Status enum for ride lifecycle
enum RideStatus { searching, accepted, arrived, inProgress, completed, cancelled }

/// Comprehensive Ride details model returned from API
class RideModel {
  final String rideId;
  final RideStatus status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final RideType rideType;
  final double fare;
  final String? otp;
  final CaptainModel? captain;
  final List<LatLng> routePoints;
  final String? createdAt;

  RideModel({
    required this.rideId,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.rideType,
    required this.fare,
    this.otp,
    this.captain,
    this.routePoints = const [],
    this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final map = json['ride'] is Map<String, dynamic> ? json['ride'] as Map<String, dynamic> : json;

    final statusStr = map['status']?.toString().toLowerCase() ?? '';
    RideStatus parsedStatus = RideStatus.searching;
    if (statusStr.contains('accept')) {
      parsedStatus = RideStatus.accepted;
    } else if (statusStr.contains('arrive')) {
      parsedStatus = RideStatus.arrived;
    } else if (statusStr.contains('progress') || statusStr.contains('ongoing') || statusStr.contains('start')) {
      parsedStatus = RideStatus.inProgress;
    } else if (statusStr.contains('complete') ||
        statusStr.contains('finish') ||
        statusStr.contains('end') ||
        statusStr.contains('success') ||
        statusStr.contains('close')) {
      parsedStatus = RideStatus.completed;
    } else if (statusStr.contains('cancel')) {
      parsedStatus = RideStatus.cancelled;
    } else if (statusStr.isEmpty) {
      parsedStatus = RideStatus.completed;
    }

    final typeStr = (map['vehicle_type'] ?? map['rideType'])?.toString().toLowerCase() ?? 'bike';
    RideType parsedType = RideType.bike;
    if (typeStr.contains('auto')) {
      parsedType = RideType.auto;
    } else if (typeStr.contains('cab') ||
        typeStr.contains('car') ||
        typeStr.contains('sedan') ||
        typeStr.contains('suv') ||
        typeStr.contains('mini')) {
      parsedType = RideType.cab;
    }

    final pickupObj = map['pickup_address'] ?? map['pickup'];
    final pickupAddressStr = pickupObj is Map ? (pickupObj['address']?.toString() ?? '') : (map['pickupAddress']?.toString() ?? '');
    final pickupLatVal = pickupObj is Map ? (pickupObj['lat'] as num?)?.toDouble() : (map['pickupLat'] as num?)?.toDouble();
    final pickupLngVal = pickupObj is Map ? (pickupObj['lng'] as num?)?.toDouble() : (map['pickupLng'] as num?)?.toDouble();

    final dropObj = map['drop_address'] ?? map['drop'];
    final dropAddressStr = dropObj is Map ? (dropObj['address']?.toString() ?? '') : (map['dropAddress']?.toString() ?? '');
    final dropLatVal = dropObj is Map ? (dropObj['lat'] as num?)?.toDouble() : (map['dropLat'] as num?)?.toDouble();
    final dropLngVal = dropObj is Map ? (dropObj['lng'] as num?)?.toDouble() : (map['dropLng'] as num?)?.toDouble();

    final driverJson = map['driver'] ?? map['captain'];
    CaptainModel? parsedCaptain = driverJson != null && driverJson is Map<String, dynamic> ? CaptainModel.fromJson(driverJson) : null;

    final driverLocJson = map['driverLocation'] ?? (driverJson is Map ? driverJson['location'] : null);
    if (driverLocJson is Map && parsedCaptain != null) {
      parsedCaptain = CaptainModel(
        id: parsedCaptain.id,
        name: parsedCaptain.name,
        phone: parsedCaptain.phone,
        rating: parsedCaptain.rating,
        vehicleNumber: parsedCaptain.vehicleNumber,
        vehicleModel: parsedCaptain.vehicleModel,
        currentLat: (driverLocJson['lat'] as num?)?.toDouble(),
        currentLng: (driverLocJson['lng'] as num?)?.toDouble(),
      );
    }

    List<LatLng> rPoints = [];
    final routeJson = map['route'];
    if (routeJson is Map && routeJson['points'] is List) {
      rPoints = (routeJson['points'] as List).map((p) {
        final lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
        return LatLng(lat, lng);
      }).toList();
    }

    return RideModel(
      rideId: map['id']?.toString() ?? map['rideId']?.toString() ?? map['_id']?.toString() ?? '',
      status: parsedStatus,
      pickupAddress: pickupAddressStr,
      pickupLat: pickupLatVal ?? 0.0,
      pickupLng: pickupLngVal ?? 0.0,
      dropAddress: dropAddressStr,
      dropLat: dropLatVal ?? 0.0,
      dropLng: dropLngVal ?? 0.0,
      rideType: parsedType,
      fare: (map['estimated_fare'] ?? map['fare'] as num?)?.toDouble() ?? 0.0,
      otp: map['otp_code']?.toString() ?? map['otp']?.toString(),
      captain: parsedCaptain,
      routePoints: rPoints,
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'status': status.name,
    'pickupAddress': pickupAddress,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'dropAddress': dropAddress,
    'dropLat': dropLat,
    'dropLng': dropLng,
    'rideType': rideType.name,
    'fare': fare,
    'otp': otp,
    'captain': captain?.toJson(),
    'createdAt': createdAt,
  };
}

/// Model for route and distance calculation between origin and destination
class RoutePoint {
  final double lat;
  final double lng;

  RoutePoint({required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(lat: (json['lat'] as num?)?.toDouble() ?? 0.0, lng: (json['lng'] as num?)?.toDouble() ?? 0.0);
  }
}

class RouteRequest {
  final RoutePoint origin;
  final RoutePoint destination;

  RouteRequest({required this.origin, required this.destination});

  Map<String, dynamic> toJson() => {'origin': origin.toJson(), 'destination': destination.toJson()};
}

class RouteResponse {
  final double distanceKm;
  final int durationMinutes;
  final String polyline;

  RouteResponse({required this.distanceKm, required this.durationMinutes, required this.polyline});

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      polyline: json['polyline']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'distanceKm': distanceKm, 'durationMinutes': durationMinutes, 'polyline': polyline};
}

/// Request payload for validating a promo code
class PromoValidateRequest {
  final String code;
  final String vehicleTypeId;
  final double fare;

  PromoValidateRequest({required this.code, required this.vehicleTypeId, required this.fare});

  Map<String, dynamic> toJson() => {'code': code, 'vehicleTypeId': vehicleTypeId, 'fare': fare};
}

/// Request payload for advance/scheduled ride booking
class AdvanceBookRideRequest {
  final String vehicleTypeId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final String scheduledAt;

  AdvanceBookRideRequest({
    required this.vehicleTypeId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.scheduledAt,
  });

  Map<String, dynamic> toJson() => {
    'vehicleTypeId': vehicleTypeId,
    'pickup': {'lat': pickupLat, 'lng': pickupLng, 'address': pickupAddress},
    'drop': {'lat': dropLat, 'lng': dropLng, 'address': dropAddress},
    'scheduledAt': scheduledAt,
  };
}

/// Request payload for verifying vehicle plate photo
class PlateVerifyRequest {
  final String photoUrl;

  PlateVerifyRequest({required this.photoUrl});

  Map<String, dynamic> toJson() => {'photoUrl': photoUrl};
}

/// Request payload for cancelling a ride with reason
class CancelRideRequest {
  final String reason;

  CancelRideRequest({required this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};
}

class NearbyDriverModel {
  final String driverId;
  final double latitude;
  final double longitude;
  final double heading;
  final double distanceKm;
  final String vehicleType;
  final String vehicleTypeId;
  final double rating;

  NearbyDriverModel({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.distanceKm,
    required this.vehicleType,
    required this.vehicleTypeId,
    required this.rating,
  });

  factory NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    return NearbyDriverModel(
      driverId: json['driverId']?.toString() ?? json['id']?.toString() ?? '',
      latitude: (json['latitude'] ?? json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] ?? json['lng'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleTypeId: json['vehicleTypeId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'distanceKm': distanceKm,
    'vehicleType': vehicleType,
    'vehicleTypeId': vehicleTypeId,
    'rating': rating,
  };
}

class NearbyDriversRequest {
  final double lat;
  final double lng;
  final String? vehicleTypeId;
  final double? radiusKm;
  final int? limit;

  NearbyDriversRequest({required this.lat, required this.lng, this.vehicleTypeId, this.radiusKm, this.limit});

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    if (vehicleTypeId != null && vehicleTypeId!.isNotEmpty) 'vehicleTypeId': vehicleTypeId,
    if (radiusKm != null) 'radiusKm': radiusKm,
    if (limit != null) 'limit': limit,
  };
}

class RideHistoryItemModel {
  final String id;
  final String tripId;
  final String status;
  final String createdAt;
  final String pickupAddress;
  final String dropAddress;
  final double distance;
  final String duration;
  final String paymentMethod;
  final double fare;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String vehicleType;
  final double rating;

  RideHistoryItemModel({
    required this.id,
    required this.tripId,
    required this.status,
    required this.createdAt,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distance,
    required this.duration,
    required this.paymentMethod,
    required this.fare,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.rating,
  });

  factory RideHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'];
    final pickupAddr = pickup is Map ? (pickup['address']?.toString() ?? '') : (json['pickupAddress']?.toString() ?? '');

    final drop = json['drop'];
    final dropAddr = drop is Map ? (drop['address']?.toString() ?? '') : (json['dropAddress']?.toString() ?? '');

    final driver = json['driver'];
    final driverName = driver is Map ? (driver['fullName']?.toString() ?? driver['name']?.toString() ?? 'Driver') : 'Driver';
    final driverPhone = driver is Map ? (driver['phone']?.toString() ?? '') : '';
    final vehicleNumber = driver is Map ? (driver['vehicleNumber']?.toString() ?? '') : '';
    final vehicleType = driver is Map ? (driver['vehicleType']?.toString() ?? 'Bike') : 'Bike';
    final rating = driver is Map ? (driver['rating'] as num?)?.toDouble() ?? 4.8 : 4.8;

    return RideHistoryItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['createdAt']?.toString() ?? '',
      pickupAddress: pickupAddr,
      dropAddress: dropAddr,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration']?.toString() ?? '0 mins',
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      rating: rating,
    );
  }
}

class RideHistoryResponse {
  final List<RideHistoryItemModel> rides;
  final int totalRides;
  final int currentPage;
  final int totalPages;
  final int limit;

  RideHistoryResponse({
    required this.rides,
    required this.totalRides,
    required this.currentPage,
    required this.totalPages,
    required this.limit,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] : json;
    final ridesList = data['rides'] is List
        ? (data['rides'] as List).map((e) => RideHistoryItemModel.fromJson(e as Map<String, dynamic>)).toList()
        : <RideHistoryItemModel>[];
    final pagination = data['pagination'] is Map ? data['pagination'] as Map<String, dynamic> : {};

    return RideHistoryResponse(
      rides: ridesList,
      totalRides: (pagination['totalRides'] as num?)?.toInt() ?? ridesList.length,
      currentPage: (pagination['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 10,
    );
  }
}

class RecentPlaceModel {
  final String id;
  final String placeId;
  final String title;
  final String subtitle;
  final double lat;
  final double lng;
  final bool isFavorite;
  final String? visitedAt;

  RecentPlaceModel({
    required this.id,
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
    required this.isFavorite,
    this.visitedAt,
  });

  factory RecentPlaceModel.fromJson(Map<String, dynamic> json) {
    return RecentPlaceModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      placeId: json['placeId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? json['address']?.toString() ?? '',
      lat: (json['lat'] ?? json['latitude'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] ?? json['longitude'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] == true,
      visitedAt: json['visitedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'lat': lat,
    'lng': lng,
    'isFavorite': isFavorite,
  };
}

/// Model for live driver location stream emitted via Socket.IO (`driver:location_updated`)
class DriverLocationUpdate {
  final String rideId;
  final String driverId;
  final String? driverName;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final double? accuracy;
  final String vehicleType;
  final String? plateNumber;
  final String? timestamp;

  DriverLocationUpdate({
    required this.rideId,
    required this.driverId,
    this.driverName,
    required this.lat,
    required this.lng,
    this.heading = 0.0,
    this.speed = 0.0,
    this.accuracy,
    this.vehicleType = 'bike',
    this.plateNumber,
    this.timestamp,
  });

  factory DriverLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DriverLocationUpdate(
      rideId: json['rideId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? json['id']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? json['name']?.toString(),
      lat: (json['lat'] ?? json['latitude'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] ?? json['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      vehicleType: json['vehicleType']?.toString() ?? 'bike',
      plateNumber: json['plateNumber']?.toString() ?? json['vehicleNumber']?.toString(),
      timestamp: json['timestamp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'driverId': driverId,
    'driverName': driverName,
    'lat': lat,
    'lng': lng,
    'heading': heading,
    'speed': speed,
    'accuracy': accuracy,
    'vehicleType': vehicleType,
    'plateNumber': plateNumber,
    'timestamp': timestamp,
  };
}
