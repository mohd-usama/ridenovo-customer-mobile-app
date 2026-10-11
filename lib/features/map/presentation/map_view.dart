import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/models/ride_models.dart';
import '../../home/providers/ride_provider.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  const MapViewWidget({super.key});

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  GoogleMapController? _mapController;

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090); // New Delhi

  void _animateToLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final activeRide = rideState.currentRide;

    ref.listen(rideProvider, (previous, next) {
      if (next.currentRide != null && next.currentRide != previous?.currentRide) {
        if (next.polylinePoints.isNotEmpty) {
          _fitBounds(next.polylinePoints);
        }
      } else if (next.pickupLocation != null && next.pickupLocation != previous?.pickupLocation && next.currentRide == null) {
        _animateToLocation(next.pickupLocation!);
      }
    });

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    if (activeRide != null) {
      // Active Ride Mode: Show assigned driver and pickup/drop (and route)
      final captain = activeRide.captain;
      if (captain != null && captain.currentLat != null && captain.currentLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: LatLng(captain.currentLat!, captain.currentLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: captain.name, snippet: captain.vehicleNumber),
          ),
        );
      }

      final isInProgress = activeRide.status == RideStatus.inProgress;
      if (isInProgress) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop_location'),
            position: LatLng(activeRide.dropLat, activeRide.dropLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Destination', snippet: 'Trip destination'),
          ),
        );
      } else {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup_location'),
            position: LatLng(activeRide.pickupLat, activeRide.pickupLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pickup Location', snippet: 'Your ride pickup'),
          ),
        );
      }

      if (rideState.polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('active_ride_route'),
            points: rideState.polylinePoints,
            color: const Color(0xFF007AFF), // Vibrant blue route like driver screen
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    } else {
      // Initial Search / Booking Mode
      if (rideState.pickupLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: rideState.pickupLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        );
      }

      if (rideState.dropLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop'),
            position: rideState.dropLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Drop Location'),
          ),
        );
      }

      // Add Nearby Drivers Markers
      for (final driver in rideState.nearbyDrivers) {
        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver.driverId}'),
            position: LatLng(driver.latitude, driver.longitude),
            rotation: driver.heading,
            anchor: const Offset(0.5, 0.5),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: '${driver.vehicleType} • ⭐ ${driver.rating}'),
          ),
        );
      }

      if (rideState.polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: rideState.polylinePoints,
            color: Colors.black,
            width: 5,
          ),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: activeRide != null ? LatLng(activeRide.pickupLat, activeRide.pickupLng) : (rideState.pickupLocation ?? _defaultLocation),
        zoom: 14.5,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        if (activeRide != null && rideState.polylinePoints.isNotEmpty) {
          _fitBounds(rideState.polylinePoints);
        }
      },
    );
  }
}
