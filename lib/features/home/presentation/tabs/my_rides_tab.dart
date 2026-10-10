import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';

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

  @override
  Widget build(BuildContext context) {
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
          _RidesList(
            rides: [
              _RideItem(
                rideId: 'RIDE_94821',
                type: 'Bike Ride',
                icon: Icons.two_wheeler,
                pickup: 'Gajapati Nagar, Bhubaneswar',
                drop: 'Railway Station, Unit 1',
                fare: '₹145',
                date: '12 Oct 2026, 04:30 PM',
                status: 'Completed',
                statusColor: AppColors.success,
              ),
              _RideItem(
                rideId: 'RIDE_83712',
                type: 'Auto Ride',
                icon: Icons.electric_rickshaw,
                pickup: 'Cyber Hub, Gurugram',
                drop: 'IGI Airport Terminal 3',
                fare: '₹280',
                date: '10 Oct 2026, 11:15 AM',
                status: 'Completed',
                statusColor: AppColors.success,
              ),
              _RideItem(
                rideId: 'RIDE_72651',
                type: 'Cab Economy',
                icon: Icons.local_taxi,
                pickup: 'Connaught Place, New Delhi',
                drop: 'Noida Sector 62',
                fare: '₹350',
                date: '05 Oct 2026, 09:00 AM',
                status: 'Completed',
                statusColor: AppColors.success,
              ),
            ],
          ),
          _RidesList(
            rides: [
              _RideItem(
                rideId: 'RIDE_51240',
                type: 'Bike Ride',
                icon: Icons.two_wheeler,
                pickup: 'Patia, Bhubaneswar',
                drop: 'KIIT University',
                fare: '₹85',
                date: '01 Oct 2026, 08:30 AM',
                status: 'Cancelled',
                statusColor: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RidesList extends StatelessWidget {
  final List<_RideItem> rides;

  const _RidesList({required this.rides});

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
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
                        child: Icon(ride.icon, color: AppColors.primary, size: 22),
                      ),
                      const Gap(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.type,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          Text(
                            ride.date,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.status,
                      style: TextStyle(color: ride.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
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
                          ride.pickup,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(16),
                        Text(
                          ride.drop,
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
                    ride.fare,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      AppSnackBar.showSuccess(context, title: 'Ride Details', message: 'Viewing receipt for ${ride.rideId}');
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

class _RideItem {
  final String rideId;
  final String type;
  final IconData icon;
  final String pickup;
  final String drop;
  final String fare;
  final String date;
  final String status;
  final Color statusColor;

  _RideItem({
    required this.rideId,
    required this.type,
    required this.icon,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.date,
    required this.status,
    required this.statusColor,
  });
}
