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
import '../../providers/ride_provider.dart';
import '../location_search_screen.dart';

class RideTab extends ConsumerStatefulWidget {
  const RideTab({super.key});

  @override
  ConsumerState<RideTab> createState() => _RideTabState();
}

class _RideTabState extends ConsumerState<RideTab> {
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
        AppSnackBar.showError(
          context,
          title: 'Location Notice',
          message: 'Could not fetch current GPS location. Please ensure GPS is enabled.',
        );
      }
      ref.read(rideProvider.notifier).updatePickupFromCoordinates(const LatLng(20.2961, 85.8245));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View with markers and polyline route
          const MapViewWidget(),

          // 2. Central Pickup Point Marker Pin (fixed to screen center - only show when no drop location selected)
          if (rideState.dropLocation == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Text(
                        'Pickup Point',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Gap(4),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
    final isSearching = ride.status == RideStatus.searching;
    final isInProgress = ride.status == RideStatus.inProgress || ride.status == RideStatus.arrived;

    String headerTitle = 'Finding your driver...';
    if (ride.status == RideStatus.accepted) {
      headerTitle = 'Driver is on the way';
    } else if (ride.status == RideStatus.arrived) {
      headerTitle = 'Driver has arrived';
    } else if (ride.status == RideStatus.inProgress) {
      headerTitle = 'Heading to destination';
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isInProgress ? AppColors.primary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isInProgress ? 'Trip Active 🟢' : '1 min away • 0.2 km',
                style: TextStyle(color: isInProgress ? AppColors.primary : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const Gap(20),
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

          // Dynamic Card: Destination Card if in progress, or OTP Card if waiting
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
          ] else if (ride.otp != null && ride.otp!.isNotEmpty) ...[
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
                        ride.otp!,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 4),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Share with\ndriver',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.2),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ],
        const Gap(20),

        // Cancel Ride Button (Only if not in progress)
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
              onPressed: () async {
                final success = await ref.read(rideProvider.notifier).cancelActiveRide(ride.rideId);
                if (context.mounted) {
                  if (success) {
                    AppSnackBar.showSuccess(context, title: 'Ride Status', message: 'Your ride has been cancelled successfully.');
                  } else {
                    AppSnackBar.showError(context, title: 'Cancel Failed', message: 'Could not cancel ride.');
                  }
                }
              },
              child: const Text('Cancel Ride', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  /// Initial Bottom Sheet: Current location, Search Card & Recent Places
  Widget _buildLocationSelectionContent(BuildContext context, RideState rideState, ScrollController scrollController) {
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
              const Icon(Icons.my_location, color: Colors.green, size: 20),
              const Gap(12),
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
        const Gap(14),

        // Where do you want to go? Search Card
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary, size: 24),
                const Gap(14),
                const Expanded(
                  child: Text(
                    'Where do you want to go?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                ),
              ],
            ),
          ),
        ),
        const Gap(20),

        // Recent Places List Header
        const Text(
          'Recent Places',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const Gap(12),

        // Recent Places List
        _RecentPlaceTile(
          title: 'Ratan Lal Market',
          subtitle: 'Kaseru Walan, Ajmer, Rajasthan',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
          },
        ),
        const Gap(10),
        _RecentPlaceTile(
          title: 'Gajapati Nagar',
          subtitle: 'Near Science Park, Bhubaneswar, Odisha',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
          },
        ),
        const Gap(10),
        _RecentPlaceTile(
          title: 'City Center Mall',
          subtitle: 'MG Road, Sector 14, Commercial Complex',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
          },
        ),
        const Gap(20),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7.5,
            child: Image.asset(
              'assets/images/home_screen_banner.png',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text(
                    'Special Ride Offers & Discounts',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rapido / Ola Style Vehicle Selection Bottom Sheet (Shown when drop location is selected)
  Widget _buildVehicleSelectionContent(BuildContext context, RideState rideState, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Gap(14),

        // Route Summary Header with Change Destination button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 18),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      rideState.pickupAddress ?? 'Pickup Location',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(height: 12, child: VerticalDivider(color: Colors.grey, thickness: 2)),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.error, size: 18),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      rideState.dropAddress ?? 'Drop Location',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(16),

        // Vehicle Estimates List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Rides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (rideState.isCalculatingFare) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const Gap(12),

        // Vehicle Estimates Options (Rapido / Ola style)
        if (rideState.fareEstimates.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: rideState.isCalculatingFare
                ? const CircularProgressIndicator(color: AppColors.primary)
                : const Text('Calculating best fares for your route...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ] else ...[
          ...rideState.fareEstimates.map((estimate) {
            final isSelected = estimate.vehicleTypeId == rideState.selectedVehicleTypeId;
            IconData iconData = Icons.two_wheeler;
            if (estimate.rideType == RideType.auto) {
              iconData = Icons.electric_rickshaw;
            } else if (estimate.rideType == RideType.cab) {
              iconData = Icons.local_taxi;
            }

            return GestureDetector(
              onTap: () => ref.read(rideProvider.notifier).selectVehicle(estimate.vehicleTypeId ?? '', estimate.rideType, estimate.fare),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 28, color: isSelected ? AppColors.primary : AppColors.secondary),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                estimate.vehicleTypeName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              const Gap(8),
                              const Icon(Icons.person, size: 12, color: AppColors.textSecondary),
                              Text(
                                ' ${estimate.availableDrivers} nearby',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const Gap(3),
                          Text(
                            '${estimate.etaMinutes} mins away • Drop in ${estimate.durationMinutes} mins',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${estimate.fare.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        if (estimate.distanceKm > 0)
                          Text(
                            '${estimate.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const Gap(16),

        // Promo Code Input Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: rideState.promoCode),
                  onChanged: (val) {
                    ref.read(rideProvider.notifier).setPromoCode(val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Enter promo code (e.g. RIDE50)',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              if (rideState.promoCode != null && rideState.promoCode!.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(rideProvider.notifier).setPromoCode(null);
                    AppSnackBar.showSuccess(context, title: 'Promo', message: 'Promo code removed');
                  },
                  child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
            ],
          ),
        ),
        const Gap(20),

        // Book Now Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: rideState.isBooking
                ? null
                : () async {
                    final success = await ref.read(rideProvider.notifier).bookRide();
                    if (context.mounted && success) {
                      final currentRide = ref.read(rideProvider).currentRide;
                      AppSnackBar.showSuccess(
                        context,
                        title: 'Ride Requested',
                        message: 'Ride #${currentRide?.rideId ?? ""} requested! Searching for nearby captain...',
                      );
                    } else if (context.mounted && rideState.errorMessage != null) {
                      AppSnackBar.showError(context, title: 'Booking Failed', message: rideState.errorMessage!);
                    }
                  },
            child: rideState.isBooking
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    'Book ${rideState.selectedRideType.name.toUpperCase()} (₹${rideState.estimatedFare.toInt()})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RecentPlaceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentPlaceTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.history, color: AppColors.textSecondary, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
