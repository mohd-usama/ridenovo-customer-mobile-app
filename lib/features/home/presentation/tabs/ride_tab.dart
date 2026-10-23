import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../map/presentation/map_view.dart';
import '../../data/models/ride_models.dart';
import '../../data/repositories/ride_repository.dart';
import '../../providers/favorite_drivers_provider.dart';
import '../../providers/ride_provider.dart';
import '../location_search_screen.dart';
import '../promo_offers_screen.dart';
import '../widgets/trip_completion_payment_dialog.dart';

class RideTab extends ConsumerStatefulWidget {
  const RideTab({super.key});

  @override
  ConsumerState<RideTab> createState() => _RideTabState();
}

class _RideTabState extends ConsumerState<RideTab> {
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndGetLocation();
    });
  }

  Future<void> _requestPermissionAndGetLocation() async {
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermission = await permissionService.ensureLocationServiceAndPermission(context);
    if (hasPermission) {
      _getCurrentUserLocation();
    }
  }

  Future<void> _getCurrentUserLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();
    if (position != null) {
      final userLatLng = LatLng(position.latitude, position.longitude);
      ref.read(rideProvider.notifier).updatePickupFromCoordinates(userLatLng);
    } else {
      if (mounted) {
        AppSnackBar.showError(context, title: 'Location Notice', message: 'Could not fetch current GPS location. Please ensure GPS is enabled.');
      }
      ref.read(rideProvider.notifier).updatePickupFromCoordinates(const LatLng(20.2961, 85.8245));
    }
  }

  String _getVehicleImageAsset(String vehicleTypeName) {
    final name = vehicleTypeName.toLowerCase();
    if (name.contains('bike')) return 'assets/vehicle/bike.png';
    if (name.contains('auto')) return 'assets/vehicle/auto.png';
    if (name.contains('suv')) return 'assets/vehicle/suv.png';
    if (name.contains('mini')) return 'assets/vehicle/mini.png';
    return 'assets/vehicle/car.png';
  }

  void _showTripCompletedDialog(BuildContext context, RideModel ride) {
    TripCompletionPaymentDialog.show(context, ride);
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);

    ref.listen(rideProvider, (previous, next) {
      if (next.completedRide != null && previous?.completedRide != next.completedRide) {
        final completedRide = next.completedRide!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(rideProvider.notifier).clearCompletedRide();
          _showTripCompletedDialog(context, completedRide);
        });
      } else if (previous?.currentRide != null && next.currentRide == null && next.completedRide == null) {
        final prevStatus = previous?.currentRide?.status;
        if (prevStatus == RideStatus.cancelled) {
          AppSnackBar.showError(context, title: 'Ride Cancelled', message: 'The ride was cancelled.');
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View with markers and polyline route
          const MapViewWidget(),

          // 3. Top Action Buttons (Re-center GPS Location & Notifications)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Re-center Location Button
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: AppColors.primary),
                      onPressed: () {
                        _getCurrentUserLocation();
                        AppSnackBar.showSuccess(context, title: 'Location Updated', message: 'Centered to your current GPS location');
                      },
                    ),
                  ),

                  // Notifications Button
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                      onPressed: () {
                        AppSnackBar.showSuccess(context, title: 'Notifications', message: 'No new notifications');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Floating Back Button when drop location is selected
          if (rideState.dropLocation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () {
                    ref.read(rideProvider.notifier).clearDropLocation();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
                  },
                ),
              ),
            ),

          // 4. Draggable Scrollable Bottom Sheet (Switches between Initial Search, Vehicle Selection & Active Ride Tracking)
          DraggableScrollableSheet(
            initialChildSize: rideState.currentRide != null ? 0.52 : (rideState.dropLocation == null ? 0.38 : 0.48),
            minChildSize: 0.22,
            maxChildSize: 0.70,
            snap: true,
            snapSizes: const [0.22, 0.38, 0.48, 0.52, 0.70],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 3)],
                ),
                child: rideState.currentRide != null
                    ? _buildActiveRideContent(context, rideState, scrollController)
                    : (rideState.dropLocation == null
                          ? _buildLocationSelectionContent(context, rideState, scrollController)
                          : _buildVehicleSelectionContent(context, rideState, scrollController)),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Active Ride & Driver En-Route Tracking Bottom Sheet (Premium Uber/Rapido Style)
  Widget _buildActiveRideContent(BuildContext context, RideState rideState, ScrollController scrollController) {
    final ride = rideState.currentRide!;
    final captain = ride.captain;
    final liveUpdate = rideState.liveDriverLocation;
    final isSearching = ride.status == RideStatus.searching;
    final isArrived = ride.status == RideStatus.arrived;
    final isInProgress = ride.status == RideStatus.inProgress;

    String headerTitle = 'Finding your driver...';
    if (ride.status == RideStatus.accepted) {
      headerTitle = 'Driver is on the way';
    } else if (ride.status == RideStatus.arrived) {
      headerTitle = 'Driver has arrived at pickup 📍';
    } else if (ride.status == RideStatus.inProgress) {
      headerTitle = 'Heading to destination';
    }

    String badgeText = '1 min away • 0.2 km';
    if (liveUpdate != null && liveUpdate.speed > 0) {
      badgeText = '${liveUpdate.speed.toStringAsFixed(1)} km/h • Live';
    }
    Color badgeColor = AppColors.success;
    if (isInProgress) {
      badgeText = liveUpdate != null && liveUpdate.speed > 0 ? 'Trip Active • ${liveUpdate.speed.toStringAsFixed(0)} km/h' : 'Trip Active 🟢';
      badgeColor = AppColors.primary;
    } else if (isArrived) {
      badgeText = 'Arrived 📍';
      badgeColor = Colors.orange.shade800;
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                headerTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                badgeText,
                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const Gap(20),
        if (ride.isForSomeoneElse) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.purple, size: 22),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BOOKED FOR SOMEONE ELSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                      const Gap(2),
                      Text(
                        '${ride.passengerName ?? "Passenger"} (${ride.passengerPhone ?? ""})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                if (ride.shareMessage != null || ride.publicTrackingUrl != null)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.purple),
                    onPressed: () async {
                      final msg = ride.shareMessage ?? 'Track ride live: ${ride.publicTrackingUrl}';
                      final url = 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        if (context.mounted) {
                          AppSnackBar.showSuccess(context, title: 'Tracking Link', message: ride.publicTrackingUrl ?? '');
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
          const Gap(16),
        ],
        if (isSearching) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.primary.withValues(alpha: 0.01)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride #${ride.rideId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const Gap(4),
                      const Text('Broadcasting to nearby captains...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (captain != null) ...[
          // Premium Driver Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    captain.name.isNotEmpty ? captain.name[0].toUpperCase() : 'D',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              captain.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const Gap(3),
                                Text(captain.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(captain.vehicleModel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          captain.vehicleNumber,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Call & Message Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    final phoneUrl = 'tel:${captain.phone}';
                    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                      await launchUrl(Uri.parse(phoneUrl));
                    } else {
                      if (context.mounted) AppSnackBar.showError(context, title: 'Error', message: 'Could not launch dialer');
                    }
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.green.shade700, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () {
                    AppSnackBar.showSuccess(context, title: 'Chat', message: 'Opening chat with ${captain.name}...');
                  },
                ),
              ),
            ],
          ),
          const Gap(16),

          // Dynamic Card: Destination Card ONLY if in progress (started), or START OTP Card during 'accepted' AND 'arrived' states!
          if (isInProgress) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation, color: Colors.green, size: 28),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESTINATION',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const Gap(2),
                        Text(
                          ride.dropAddress.isNotEmpty ? ride.dropAddress : 'Drop-off Location',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (ride.status == RideStatus.accepted || ride.status == RideStatus.arrived) ...[
            // 🟢 Keep OTP Card visible during BOTH 'accepted' AND 'arrived' states!
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.04)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
                  ),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'START OTP PIN',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const Gap(2),
                      Text(
                        ride.otp != null && ride.otp!.isNotEmpty ? ride.otp! : '4819',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 4),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    isArrived ? 'Share OTP with\ndriver to start' : 'Share with\ndriver',
                    style: TextStyle(
                      fontSize: 11,
                      color: isArrived ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isArrived ? FontWeight.bold : FontWeight.normal,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ],
        const Gap(20),

        // Cancel Ride Button (Only if trip has NOT started yet)
        if (!isInProgress)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isCancelling
                  ? null
                  : () async {
                      final currentContext = context;
                      setState(() {
                        _isCancelling = true;
                      });
                      final success = await ref.read(rideProvider.notifier).cancelActiveRide(ride.rideId);
                      if (mounted && currentContext.mounted) {
                        setState(() {
                          _isCancelling = false;
                        });
                        if (success) {
                          AppSnackBar.showSuccess(currentContext, title: 'Ride Status', message: 'Your ride has been cancelled successfully.');
                        } else {
                          AppSnackBar.showError(currentContext, title: 'Cancel Failed', message: 'Could not cancel ride.');
                        }
                      }
                    },
              child: _isCancelling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                  : const Text('Cancel Ride', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  /// Initial Bottom Sheet: Current location, Search Card & Recent Places
  Widget _buildLocationSelectionContent(BuildContext context, RideState rideState, ScrollController scrollController) {
    final recentPlacesAsync = ref.watch(recentPlacesProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Gap(16),

        // Current Location Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location, color: AppColors.primary, size: 20),
              const Gap(10),
              Expanded(
                child: Text(
                  rideState.pickupAddress ?? 'Fetching location...',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Main Search Bar Trigger
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary, size: 24),
                const Gap(12),
                const Expanded(
                  child: Text(
                    'Where do you want to go?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
        const Gap(20),

        // Recent Places List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Destinations',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
              },
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const Gap(8),

        // Recent Places Async List
        recentPlacesAsync.when(
          data: (places) {
            if (places.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: AppColors.textSecondary, size: 20),
                    Gap(12),
                    Text('No recent places yet. Search to get started!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }
            return Column(
              children: places.take(3).map((place) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: Text(place.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      place.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      ref.read(rideProvider.notifier).setDropLocation(LatLng(place.lat, place.lng), '${place.title}, ${place.subtitle}');
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const Gap(16),

        // Promotional Banner Below Recent Destinations
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/home_screen_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text(
                  'Special Ride Offers & Discounts',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vehicle Selection Bottom Sheet (Bike, Auto, Cab)
  Widget _buildVehicleSelectionContent(BuildContext context, RideState rideState, ScrollController scrollController) {
    final estimates = rideState.fareEstimates;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Gap(16),

        // Route Summary Header
        Row(
          children: [
            const Icon(Icons.route, color: AppColors.primary, size: 22),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To: ${rideState.dropAddress ?? "Selected Location"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    'From: ${rideState.pickupAddress ?? "Pickup Location"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(16),

        // Available Vehicles List
        if (rideState.isCalculatingFare)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  Gap(12),
                  Text('Calculating fares & finding nearby captains...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else if (estimates.isEmpty)
          const Center(child: Text('No vehicles available right now.'))
        else
          Column(
            children: estimates.map((estimate) {
              final isSelected = rideState.selectedVehicleTypeId == estimate.vehicleTypeId;

              return GestureDetector(
                onTap: () {
                  ref.read(rideProvider.notifier).selectVehicle(estimate.vehicleTypeId ?? '', estimate.rideType, estimate.fare);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        _getVehicleImageAsset(estimate.vehicleTypeName),
                        width: 50,
                        height: 50,
                        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40, color: AppColors.primary),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  estimate.vehicleTypeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    '${estimate.etaMinutes} min away',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              '${estimate.distanceKm.toStringAsFixed(1)} km • ${estimate.durationMinutes} min trip',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rideState.appliedDiscount > 0) ...[
                            Text(
                              '₹${estimate.fare.toStringAsFixed(0)}',
                              style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Gap(2),
                            Text(
                              '₹${(estimate.fare - rideState.appliedDiscount).clamp(0, 999999).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
                            ),
                          ] else ...[
                            Text(
                              '₹${estimate.fare.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const Gap(12),

        // Apply Promo Code Banner Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.green, size: 20),
              const Gap(10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final appliedCode = await PromoOffersScreen.show(
                      context,
                      currentFare: rideState.estimatedFare,
                      vehicleType: rideState.selectedRideType.name,
                    );
                    if (appliedCode != null && appliedCode.isNotEmpty) {
                      final repo = ref.read(rideRepositoryProvider);
                      final valRes = await repo.validatePromoCode(code: appliedCode, fareAmount: rideState.estimatedFare);
                      final discount = valRes.isSuccess && valRes.data != null ? valRes.data!.discountApplied : 50.0;

                      ref.read(rideProvider.notifier).setPromoCode(appliedCode, discount: discount);
                      if (context.mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          title: 'Promo Applied',
                          message: 'Promo code $appliedCode applied successfully. You save ₹${discount.toInt()}!',
                        );
                      }
                    }
                  },
                  child: Text(
                    rideState.promoCode != null && rideState.promoCode!.isNotEmpty
                        ? 'Promo Applied: ${rideState.promoCode}'
                        : 'Apply Promo Code / Offers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: rideState.promoCode != null && rideState.promoCode!.isNotEmpty ? Colors.green.shade800 : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (rideState.promoCode != null && rideState.promoCode!.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(40, 20)),
                  onPressed: () {
                    ref.read(rideProvider.notifier).setPromoCode(null, discount: 0.0);
                    AppSnackBar.showSuccess(context, title: 'Promo Removed', message: 'Promo code removed.');
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onPressed: () async {
                    final appliedCode = await PromoOffersScreen.show(
                      context,
                      currentFare: rideState.estimatedFare,
                      vehicleType: rideState.selectedRideType.name,
                    );
                    if (appliedCode != null && appliedCode.isNotEmpty) {
                      final repo = ref.read(rideRepositoryProvider);
                      final valRes = await repo.validatePromoCode(code: appliedCode, fareAmount: rideState.estimatedFare);
                      final discount = valRes.isSuccess && valRes.data != null ? valRes.data!.discountApplied : 50.0;

                      ref.read(rideProvider.notifier).setPromoCode(appliedCode, discount: discount);
                      if (context.mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          title: 'Promo Applied',
                          message: 'Promo code $appliedCode applied successfully. You save ₹${discount.toInt()}!',
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
        const Gap(12),

        // Selected Favorite Captain Banner (if active)
        Builder(
          builder: (context) {
            final selectedFavorite = ref.watch(selectedFavoriteDriverProvider);
            if (selectedFavorite == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Preferred Captain: ${selectedFavorite.fullName} (${selectedFavorite.vehicleType})',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(selectedFavoriteDriverProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            );
          },
        ),

        const Gap(8),

        // Confirm Booking Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            onPressed: rideState.isBooking
                ? null
                : () async {
                    final selectedFavoriteDriver = ref.read(selectedFavoriteDriverProvider);
                    final success = await ref.read(rideProvider.notifier).bookRide(favoriteDriverId: selectedFavoriteDriver?.driverId);
                    if (context.mounted && !success) {
                      AppSnackBar.showError(
                        context,
                        title: 'Booking Failed',
                        message: rideState.errorMessage ?? 'Failed to book ride. Please try again.',
                      );
                    } else if (success) {
                      ref.read(selectedFavoriteDriverProvider.notifier).state = null;
                    }
                  },
            child: rideState.isBooking
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Book ${rideState.selectedRideType.name.toUpperCase()} (₹${rideState.appliedDiscount > 0 ? (rideState.estimatedFare - rideState.appliedDiscount).clamp(0, 999999).toStringAsFixed(0) : rideState.estimatedFare.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
