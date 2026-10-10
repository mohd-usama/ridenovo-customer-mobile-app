import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/auth_provider.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  String _selectedGender = 'male';
  bool _isEditing = false;
  DateTime? _selectedDate;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    if (user?.gender != null && user!.gender!.isNotEmpty) {
      _selectedGender = user.gender!.toLowerCase();
    }
    if (user?.profilePhoto != null) {
      _profilePhotoUrl = user!.profilePhoto;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    if (!_isEditing) return;
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(1940);
    final lastDate = DateTime(now.year - 12, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'fullName': _fullNameController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      'gender': _selectedGender,
      if (_dobController.text.trim().isNotEmpty) 'dateOfBirth': _dobController.text.trim(),
      'profilePhotoUrl': _profilePhotoUrl ?? '',
      'profilePhoto': _profilePhotoUrl ?? '',
      'image': _profilePhotoUrl ?? '',
    };

    final success = await ref.read(authProvider.notifier).updateProfile(body);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      AppSnackBar.showSuccess(context, title: 'Profile Updated', message: 'Your profile details were updated successfully via PUT API!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isEditing
                            ? () {
                                setState(() {
                                  _profilePhotoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
                                });
                                AppSnackBar.showSuccess(context, title: 'Photo', message: 'Profile photo updated');
                              }
                            : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              backgroundImage: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
                              child: _profilePhotoUrl == null
                                  ? Text(
                                      user?.fullName != null && user!.fullName!.isNotEmpty ? user.fullName![0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    )
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Rahul Sharma',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Gap(4),
                            Text(user?.phone ?? '9876543210', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            const Gap(8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const Gap(4),
                                      Text(
                                        user?.averageRating ?? '4.90',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${user?.totalRides ?? 12} Rides',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Referral Code Card if available
                if (user?.referralCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, Color(0xFF1B498F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Referral Code', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const Gap(4),
                            Text(
                              user!.referralCode!,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(80, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            AppSnackBar.showSuccess(context, title: 'Copied', message: 'Referral code copied to clipboard!');
                          },
                          child: const Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                ],

                const Text(
                  'Account Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const Gap(12),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  enabled: _isEditing,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter full name' : null,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    filled: true,
                    fillColor: _isEditing ? Colors.white : AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const Gap(16),

                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: _isEditing ? Colors.white : AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const Gap(16),

                // Phone (Read Only)
                TextFormField(
                  controller: _phoneController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                    suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const Gap(20),

                // Gender Selection
                const Text(
                  'Gender',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Gap(10),
                Row(
                  children: [
                    _GenderOptionChip(
                      label: 'Male',
                      icon: Icons.male,
                      isSelected: _selectedGender == 'male',
                      enabled: _isEditing,
                      onTap: () => _isEditing ? setState(() => _selectedGender = 'male') : null,
                    ),
                    const Gap(12),
                    _GenderOptionChip(
                      label: 'Female',
                      icon: Icons.female,
                      isSelected: _selectedGender == 'female',
                      enabled: _isEditing,
                      onTap: () => _isEditing ? setState(() => _selectedGender = 'female') : null,
                    ),
                    const Gap(12),
                    _GenderOptionChip(
                      label: 'Other',
                      icon: Icons.transgender,
                      isSelected: _selectedGender == 'other',
                      enabled: _isEditing,
                      onTap: () => _isEditing ? setState(() => _selectedGender = 'other') : null,
                    ),
                  ],
                ),
                const Gap(20),

                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                    suffixIcon: _isEditing ? const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary) : null,
                    filled: true,
                    fillColor: _isEditing ? Colors.white : AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const Gap(32),

                // Save Changes Button (Visible only when editing)
                if (_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: authState.isLoading ? null : _updateProfile,
                      child: authState.isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text(
                              'Save Changes (PUT /api/users/me)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const Gap(20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _GenderOptionChip({required this.label, required this.icon, required this.isSelected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (enabled ? AppColors.background : Colors.grey.shade100),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
