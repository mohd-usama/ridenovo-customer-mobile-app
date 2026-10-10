import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: false,
            intervalDuration: const Duration(seconds: 10),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return await Geolocator.getLastKnownPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return await Geolocator.getLastKnownPosition();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10));
  }
}
