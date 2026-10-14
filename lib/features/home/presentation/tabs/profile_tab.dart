import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../auth/presentation/profile_details_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../saved_places_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.fullName ?? 'Rahul Sharma';
    final userPhone = user?.phone ?? '9876543210';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
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
            // User Card (Tap to open Profile Details & PUT Update API Screen)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Gap(4),
                          Text(
                            userPhone.startsWith('+') ? userPhone : '+91 $userPhone',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Rating Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const Gap(10),
                      Text(
                        '${user?.averageRating ?? "4.90"} My Rating',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const Gap(20),

            // Menu Options Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Help', message: 'Opening Help & Support'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Payment', message: 'Opening Payment Methods'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'My Rides',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'My Rides', message: 'Opening My Rides'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.security_outlined,
                        title: 'Safety',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Safety', message: 'Opening Safety toolkit'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.bookmark_border,
                        title: 'Saved places',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.card_giftcard,
                        title: 'Refer and Earn',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Refer & Earn', message: 'Opening Refer & Earn'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Notifications', message: 'Opening Notifications'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Settings', message: 'Opening Settings'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Privacy',
                        isLast: true,
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Privacy', message: 'Opening Privacy policy'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(20),

            // Log out Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Log out',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Are you sure you want to log out? All active processes and timers will be stopped.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        ref.read(rideProvider.notifier).resetRide();
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const Gap(30),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _ProfileMenuItem({required this.icon, required this.title, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.textPrimary, size: 22),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}
