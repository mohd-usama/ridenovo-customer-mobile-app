import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/models/ride_models.dart';
import '../../data/repositories/ride_repository.dart';

final rideHistoryProvider = FutureProvider.family<RideHistoryResponse, String>((ref, type) async {
  final repo = ref.watch(rideRepositoryProvider);
  final response = await repo.getRideHistory(type: type);
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  return RideHistoryResponse(rides: [], totalRides: 0, currentPage: 1, totalPages: 1, limit: 10);
});

class MyRidesTab extends ConsumerStatefulWidget {
  const MyRidesTab({super.key});

  @override
  ConsumerState<MyRidesTab> createState() => _MyRidesTabState();
}

class _MyRidesTabState extends ConsumerState<MyRidesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getVehicleIcon(String vehicleType) {
    final type = vehicleType.toLowerCase();
    if (type.contains('auto')) return Icons.electric_rickshaw;
    if (type.contains('cab') || type.contains('car') || type.contains('sedan') || type.contains('suv')) return Icons.local_taxi;
    return Icons.two_wheeler;
  }

  @override
  Widget build(BuildContext context) {
    final completedAsync = ref.watch(rideHistoryProvider('complete'));
    final cancelledAsync = ref.watch(rideHistoryProvider('cancel'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Rides',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rideHistoryProvider('complete'));
            },
            child: completedAsync.when(
              data: (res) => _RidesList(rides: res.rides, getIcon: _getVehicleIcon),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rideHistoryProvider('cancel'));
            },
            child: cancelledAsync.when(
              data: (res) => _RidesList(rides: res.rides, getIcon: _getVehicleIcon),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
        ],
      ),
    );
  }
}

class _RidesList extends StatelessWidget {
  final List<RideHistoryItemModel> rides;
  final IconData Function(String) getIcon;

  const _RidesList({required this.rides, required this.getIcon});

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                const Gap(16),
                const Text(
                  'No rides found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        final isCompleted = ride.status.toLowerCase().contains('complete');
        final statusColor = isCompleted ? AppColors.success : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(getIcon(ride.vehicleType), color: AppColors.primary, size: 22),
                      ),
                      const Gap(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.vehicleType.isNotEmpty ? '${ride.vehicleType} Ride' : 'Ride',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          Text(
                            ride.createdAt,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      Container(width: 2, height: 24, color: Colors.grey.shade300),
                      const Icon(Icons.location_on, size: 14, color: AppColors.error),
                    ],
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickupAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(16),
                        Text(
                          ride.dropAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${ride.fare.toInt()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      AppSnackBar.showSuccess(context, title: 'Ride Details', message: 'Trip ID: ${ride.tripId.isNotEmpty ? ride.tripId : ride.id}');
                    },
                    child: const Text('View Details >', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
