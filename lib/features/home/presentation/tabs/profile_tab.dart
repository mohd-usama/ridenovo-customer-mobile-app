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
import '../spending_summary_screen.dart';
import '../favorite_drivers_screen.dart';
import '../referral_screen.dart';
import '../support/help_support_screen.dart';
import '../privacy_policy_screen.dart';
import '../payment_methods_screen.dart';

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
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'My Rides',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'My Rides', message: 'Opening My Rides'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.analytics_outlined,
                        title: 'Spending Summary',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpendingSummaryScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.star_outline_rounded,
                        title: 'Favorite Captains',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoriteDriversScreen()));
                        },
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
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralScreen()));
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        onTap: () => AppSnackBar.showSuccess(context, title: 'Notifications', message: 'Opening Notifications'),
                      ),
                      _ProfileMenuItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () => _showSettingsModal(context, ref)),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Privacy',
                        isLast: true,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                        },
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
                          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Gap(16),
            // Push Notifications option commented out for now
            /*
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Switch(value: true, activeTrackColor: AppColors.primary, onChanged: (val) {}),
            ),
            const Divider(),
            */
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Permanently delete your account and personal data',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context); // close modal
                _confirmAndDeleteAccount(context, ref);
              },
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to permanently delete your account? All your personal data, saved places, and active sessions will be purged.',
            ),
            const Gap(12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for leaving (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirm == true) {
      AppSnackBar.showSuccess(context, title: 'Processing', message: 'Requesting account deletion...');
      final success = await ref.read(authProvider.notifier).deleteAccount(reason: reasonController.text.trim());
      if (!context.mounted) return;
      if (success) {
        AppSnackBar.showSuccess(context, title: 'Account Deleted', message: 'Your account has been deleted permanently.');
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      } else {
        final errorMsg = ref.read(authProvider).errorMessage ?? 'Failed to delete account. Please ensure no active rides are running.';
        AppSnackBar.showError(context, title: 'Deletion Failed', message: errorMsg);
      }
    }
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
