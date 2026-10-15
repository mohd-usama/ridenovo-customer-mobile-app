import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/models/ride_models.dart';
import '../../home/providers/ride_provider.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  const MapViewWidget({super.key});

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Map<String, BitmapDescriptor> _customIcons = {};
  LatLng? _currentCameraTarget;

  // Driver Marker Smooth Animation Variables
  AnimationController? _animController;
  LatLng? _animOldPos;
  LatLng? _animTargetPos;
  double _animOldHeading = 0.0;
  double _animTargetHeading = 0.0;
  LatLng? _animatedDriverPos;
  double _animatedDriverHeading = 0.0;

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090); // New Delhi

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animController!.addListener(_onAnimationTick);
    _loadCustomMarkerIcons();
  }

  void _onAnimationTick() {
    if (_animOldPos != null && _animTargetPos != null && mounted) {
      final t = _animController!.value;
      final lat = lerpDouble(_animOldPos!.latitude, _animTargetPos!.latitude, t) ?? _animTargetPos!.latitude;
      final lng = lerpDouble(_animOldPos!.longitude, _animTargetPos!.longitude, t) ?? _animTargetPos!.longitude;
      final heading = _lerpAngle(_animOldHeading, _animTargetHeading, t);

      setState(() {
        _animatedDriverPos = LatLng(lat, lng);
        _animatedDriverHeading = heading;
      });
    }
  }

  double _lerpAngle(double start, double end, double t) {
    double difference = (end - start) % 360;
    if (difference > 180) {
      difference -= 360;
    } else if (difference < -180) {
      difference += 360;
    }
    return (start + difference * t) % 360;
  }

  void _updateDriverPositionAndAnimate(LatLng newPos, double newHeading) {
    if (_animatedDriverPos == null) {
      _animatedDriverPos = newPos;
      _animatedDriverHeading = newHeading;
      _animOldPos = newPos;
      _animTargetPos = newPos;
      _animOldHeading = newHeading;
      _animTargetHeading = newHeading;
      if (mounted) setState(() {});
      return;
    }

    // Distance threshold check - if too far (e.g. initial set), snap instantly, otherwise smooth animate
    if (_isFar(_animatedDriverPos!, newPos)) {
      _animOldPos = _animatedDriverPos;
      _animTargetPos = newPos;
      _animOldHeading = _animatedDriverHeading;
      _animTargetHeading = newHeading;

      _animController!.forward(from: 0.0);
    }
  }

  Future<BitmapDescriptor> _createPickupMarkerIcon({double scale = 2.5}) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final double pillWidth = 120.0 * scale;
    final double pillHeight = 34.0 * scale;
    final double dotSize = 12.0 * scale;
    final double gap = 4.0 * scale;
    final double totalWidth = 140.0 * scale;
    final double totalHeight = pillHeight + gap + dotSize + 4.0 * scale;

    // 1. Draw Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * scale);
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((totalWidth - pillWidth) / 2, 2 * scale, pillWidth, pillHeight),
      Radius.circular(17 * scale),
    );
    canvas.drawRRect(pillRRect.shift(Offset(0, 2 * scale)), shadowPaint);

    // 2. Draw Green Pill
    final pillPaint = Paint()
      ..color = const Color(0xFF10B981) // Green success color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRRect, pillPaint);

    // 3. Draw Text "Pickup Point" inside the pill
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Pickup Point',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.0 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (totalWidth - textPainter.width) / 2,
        (pillHeight - textPainter.height) / 2 + (2 * scale),
      ),
    );

    // 4. Draw Dot at bottom
    final dotCenter = Offset(totalWidth / 2, pillHeight + gap + (dotSize / 2));
    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, dotSize / 2, dotPaint);

    final whiteBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;
    canvas.drawCircle(dotCenter, dotSize / 2 - (1.0 * scale), whiteBorderPaint);

    final image = await pictureRecorder.endRecording().toImage(
      totalWidth.toInt(),
      totalHeight.toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<void> _loadCustomMarkerIcons() async {
    try {
      final bikeIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(42, 42)), 'assets/arial_images/bike_ariel.png');
      final autoIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(42, 42)), 'assets/arial_images/auto_ariel.png');
      final carIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(42, 42)), 'assets/arial_images/car_ariel.png');
      final pickupIcon = await _createPickupMarkerIcon();

      if (mounted) {
        setState(() {
          _customIcons['bike'] = bikeIcon;
          _customIcons['auto'] = autoIcon;
          _customIcons['car'] = carIcon;
          _customIcons['pickup'] = pickupIcon;
        });
      }
    } catch (_) {}
  }

  void _animateToLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  bool _isFar(LatLng p1, LatLng p2) {
    return (p1.latitude - p2.latitude).abs() > 0.0001 || (p1.longitude - p2.longitude).abs() > 0.0001;
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
    LatLngBounds bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController?.removeListener(_onAnimationTick);
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final activeRide = rideState.currentRide;
    final liveDriverUpdate = rideState.liveDriverLocation;

    ref.listen(rideProvider, (previous, next) {
      if (next.currentRide != null && next.currentRide != previous?.currentRide) {
        if (next.polylinePoints.isNotEmpty) {
          _fitBounds(next.polylinePoints);
        }
      } else if (next.pickupLocation != null && next.pickupLocation != previous?.pickupLocation && next.currentRide == null) {
        if (_currentCameraTarget == null || _isFar(_currentCameraTarget!, next.pickupLocation!)) {
          _animateToLocation(next.pickupLocation!);
        }
      }
    });

    // Check for live driver location stream update to trigger smooth interpolation
    if (liveDriverUpdate != null) {
      final newDriverPos = LatLng(liveDriverUpdate.lat, liveDriverUpdate.lng);
      _updateDriverPositionAndAnimate(newDriverPos, liveDriverUpdate.heading);
    } else if (activeRide?.captain?.currentLat != null && activeRide?.captain?.currentLng != null) {
      final initialDriverPos = LatLng(activeRide!.captain!.currentLat!, activeRide.captain!.currentLng!);
      _updateDriverPositionAndAnimate(initialDriverPos, 0.0);
    }

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    if (activeRide != null) {
      // Active Ride Mode: Show assigned driver aerial icon and pickup/drop (and route)
      final captain = activeRide.captain;
      final driverPos = _animatedDriverPos ?? (captain != null && captain.currentLat != null ? LatLng(captain.currentLat!, captain.currentLng!) : null);

      if (driverPos != null) {
        BitmapDescriptor assignedIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        final vTypeStr = (liveDriverUpdate?.vehicleType ?? activeRide.rideType.name).toLowerCase();
        if (vTypeStr.contains('bike') && _customIcons.containsKey('bike')) {
          assignedIcon = _customIcons['bike']!;
        } else if (vTypeStr.contains('auto') && _customIcons.containsKey('auto')) {
          assignedIcon = _customIcons['auto']!;
        } else if (_customIcons.containsKey('car')) {
          assignedIcon = _customIcons['car']!;
        }

        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: driverPos,
            rotation: _animatedDriverHeading,
            anchor: const Offset(0.5, 0.5),
            icon: assignedIcon,
            infoWindow: InfoWindow(title: captain?.name ?? 'Driver', snippet: captain?.vehicleNumber ?? 'On the way'),
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
            icon: _customIcons['pickup'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: _customIcons.containsKey('pickup') ? const Offset(0.5, 1.0) : const Offset(0.5, 0.5),
            infoWindow: const InfoWindow(title: 'Pickup Location', snippet: 'Your ride pickup'),
          ),
        );
      }

      if (rideState.polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('active_ride_route'),
            points: rideState.polylinePoints,
            color: const Color(0xFF007AFF), // Vibrant blue route
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
            icon: _customIcons['pickup'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: _customIcons.containsKey('pickup') ? const Offset(0.5, 1.0) : const Offset(0.5, 0.5),
            infoWindow: InfoWindow(title: 'Pickup Point 📍', snippet: rideState.pickupAddress ?? 'Your Pickup Location'),
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

      // Add Nearby Drivers Markers with Aerial Custom Icons
      for (final driver in rideState.nearbyDrivers) {
        BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        final vType = driver.vehicleType.toLowerCase();
        if (vType.contains('bike') && _customIcons.containsKey('bike')) {
          markerIcon = _customIcons['bike']!;
        } else if (vType.contains('auto') && _customIcons.containsKey('auto')) {
          markerIcon = _customIcons['auto']!;
        } else if (_customIcons.containsKey('car')) {
          markerIcon = _customIcons['car']!;
        }

        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver.driverId}'),
            position: LatLng(driver.latitude, driver.longitude),
            rotation: driver.heading,
            anchor: const Offset(0.5, 0.5),
            icon: markerIcon,
            infoWindow: InfoWindow(title: '${driver.vehicleType} • ⭐ ${driver.rating}'),
          ),
        );
      }

      if (rideState.polylinePoints.isNotEmpty) {
        polylines.add(Polyline(polylineId: const PolylineId('route'), points: rideState.polylinePoints, color: Colors.black, width: 5));
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
      onCameraMove: (position) {
        _currentCameraTarget = position.target;
      },
      onCameraIdle: () {
        if (activeRide == null && rideState.dropLocation == null && _currentCameraTarget != null) {
          ref.read(rideProvider.notifier).updatePickupFromCoordinates(_currentCameraTarget!);
        }
      },
      onMapCreated: (controller) {
        _mapController = controller;
        if (activeRide != null && rideState.polylinePoints.isNotEmpty) {
          _fitBounds(rideState.polylinePoints);
        }
      },
    );
  }
}
