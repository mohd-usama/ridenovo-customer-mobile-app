import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';

class AllServicesTab extends ConsumerWidget {
  const AllServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'All Services',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Daily Commute',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Bike Ride',
                    subtitle: 'Fastest & cheapest',
                    icon: Icons.two_wheeler,
                    color: AppColors.primary,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Bike Ride', message: 'Selected Bike service'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Auto Ride',
                    subtitle: 'At your doorstep',
                    icon: Icons.electric_rickshaw,
                    color: AppColors.secondary,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Auto Ride', message: 'Selected Auto service'),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Cab Economy',
                    subtitle: 'AC cars for comfort',
                    icon: Icons.local_taxi,
                    color: Colors.blueAccent,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Cab Economy', message: 'Selected Cab service'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Cab Premium',
                    subtitle: 'Luxury sedans & SUVs',
                    icon: Icons.car_rental,
                    color: Colors.purple,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Cab Premium', message: 'Selected Premium service'),
                  ),
                ),
              ],
            ),
            const Gap(28),
            const Text(
              'Package & Delivery',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const Gap(12),
            _ServiceBannerCard(
              title: 'Package Delivery',
              subtitle: 'Send parcels, documents & food anywhere in the city instantly',
              icon: Icons.inventory_2_outlined,
              badge: 'Fast Delivery',
              onTap: () => AppSnackBar.showSuccess(context, title: 'Delivery', message: 'Opening Package Delivery'),
            ),
            const Gap(28),
            const Text(
              'Outstation & Rentals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Intercity',
                    subtitle: 'Outstation cabs',
                    icon: Icons.location_city,
                    color: Colors.teal,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Intercity', message: 'Opening Intercity rides'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _ServiceItemCard(
                    title: 'Hourly Rentals',
                    subtitle: 'Cabs with driver',
                    icon: Icons.access_time,
                    color: Colors.indigo,
                    onTap: () => AppSnackBar.showSuccess(context, title: 'Rentals', message: 'Opening Hourly Rentals'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Gap(14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  const _ServiceBannerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, Color(0xFF1B498F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}
