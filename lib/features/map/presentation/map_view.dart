import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);

    ref.listen(rideProvider, (previous, next) {
      if (next.pickupLocation != null && next.pickupLocation != previous?.pickupLocation) {
        _animateToLocation(next.pickupLocation!);
      }
    });

    final Set<Marker> markers = {};
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

    // Add Nearby Drivers Markers with Heading Rotation
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

    final Set<Polyline> polylines = {};
    if (rideState.polylinePoints.isNotEmpty) {
      polylines.add(Polyline(polylineId: const PolylineId('route'), points: rideState.polylinePoints, color: Colors.black, width: 5));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: rideState.pickupLocation ?? _defaultLocation, zoom: 14.5),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }
}
