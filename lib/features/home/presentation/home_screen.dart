import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../map/presentation/map_view.dart';
import '../providers/ride_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndLocation();
    });
  }

  Future<void> _initPermissionsAndLocation() async {
    final permissionService = ref.read(permissionServiceProvider);

    // Request Notification permission
    await permissionService.requestNotificationPermission(context);

    // Request Location permission
    if (mounted) {
      final hasLocationPermission = await permissionService.requestLocationPermission(context);

      if (hasLocationPermission) {
        final locationService = ref.read(locationServiceProvider);
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          ref.read(rideProvider.notifier).setPickupLocation(
                LatLng(position.latitude, position.longitude),
                'Current Location',
              );
        }
      }
    }
  }

  String _getFareForType(RideState state, RideType type, String defaultFare) {
    final match = state.fareEstimates.where((e) => e.rideType == type).firstOrNull;
    if (match != null) {
      return '₹${match.fare.toInt()}';
    }
    return '₹$defaultFare';
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          const MapViewWidget(),

          // Top Header / Drawer button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {},
                ),
              ),
            ),
          ),

          // Bottom Ride Booking Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location Input Buttons
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.green),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                rideState.pickupAddress ?? 'Fetching current location...',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.error),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                rideState.dropAddress ?? 'Where are you going?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: rideState.dropAddress == null ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Ride Type Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RideOptionCard(
                        icon: Icons.two_wheeler,
                        title: 'Bike',
                        fare: _getFareForType(rideState, RideType.bike, '45'),
                        isSelected: rideState.selectedRideType == RideType.bike,
                        onTap: () => ref.read(rideProvider.notifier).selectRideType(RideType.bike),
                      ),
                      _RideOptionCard(
                        icon: Icons.electric_rickshaw,
                        title: 'Auto',
                        fare: _getFareForType(rideState, RideType.auto, '75'),
                        isSelected: rideState.selectedRideType == RideType.auto,
                        onTap: () => ref.read(rideProvider.notifier).selectRideType(RideType.auto),
                      ),
                      _RideOptionCard(
                        icon: Icons.local_taxi,
                        title: 'Cab',
                        fare: _getFareForType(rideState, RideType.cab, '120'),
                        isSelected: rideState.selectedRideType == RideType.cab,
                        onTap: () => ref.read(rideProvider.notifier).selectRideType(RideType.cab),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Book Button
                  ElevatedButton(
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
                              AppSnackBar.showError(
                                context,
                                title: 'Booking Failed',
                                message: rideState.errorMessage!,
                              );
                            }
                          },
                    child: rideState.isBooking
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Book ${rideState.selectedRideType.name.toUpperCase()} (${_getFareForType(rideState, rideState.selectedRideType, "45")})'),
                  ),
                  const Gap(16),

                  // Promotional Banner (Ola / Rapido style)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/home_screen_banner.png',
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String fare;
  final bool isSelected;
  final VoidCallback onTap;

  const _RideOptionCard({required this.icon, required this.title, required this.fare, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.secondary : Colors.grey),
            const Gap(4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(fare, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
