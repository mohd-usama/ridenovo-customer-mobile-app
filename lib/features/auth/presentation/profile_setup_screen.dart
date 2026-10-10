import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../home/presentation/main_dashboard_screen.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _selectedGender = 'male';
  DateTime? _selectedDate;
  String? _profilePhotoPath;
  String? _profilePhotoBase64;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final phone = ref.read(authProvider).phoneNumber ?? user?.phone ?? '';
      _phoneController.text = phone.startsWith('+91') ? phone : '+91 $phone';
      // Do NOT autofill name, email, or DOB for fresh login. User will fill them manually.
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _profilePhotoPath = pickedFile.path;
          _profilePhotoBase64 = base64String;
          _profilePhotoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, title: 'Error', message: 'Failed to pick image: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo from Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'fullName': _fullNameController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      'gender': _selectedGender,
      if (_dobController.text.trim().isNotEmpty) 'dateOfBirth': _dobController.text.trim(),
      if (_profilePhotoBase64 != null) ...{
        'profilePhoto': _profilePhotoBase64,
        'profilePhotoUrl': _profilePhotoBase64,
        'image': _profilePhotoBase64,
        'base64Image': _profilePhotoBase64,
      } else if (_profilePhotoUrl != null) ...{
        'profilePhoto': _profilePhotoUrl,
        'profilePhotoUrl': _profilePhotoUrl,
        'image': _profilePhotoUrl,
      },
    };

    final success = await ref.read(authProvider.notifier).updateProfile(body);

    if (success && mounted) {
      AppSnackBar.showSuccess(context, title: 'Profile Saved', message: 'Your profile details have been saved successfully!');

      // Navigate to Main Dashboard Screen
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainDashboardScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Personal Details',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Header with Camera Picker
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            image: _profilePhotoPath != null
                                ? DecorationImage(image: FileImage(File(_profilePhotoPath!)), fit: BoxFit.cover)
                                : (_profilePhotoUrl != null ? DecorationImage(image: NetworkImage(_profilePhotoUrl!), fit: BoxFit.cover) : null),
                          ),
                          child: (_profilePhotoPath == null && _profilePhotoUrl == null)
                              ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),

                const Text(
                  'Set up your profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Gap(4),
                const Text(
                  'Please provide your details to personalize your Ridonova account.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const Gap(28),

                // Full Name Input
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const Gap(20),

                // Email Address Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'e.g. rahul@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const Gap(20),

                // Phone Number (Disabled)
                TextFormField(
                  controller: _phoneController,
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                    suffixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const Gap(24),

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
                      onTap: () => setState(() => _selectedGender = 'male'),
                    ),
                    const Gap(12),
                    _GenderOptionChip(
                      label: 'Female',
                      icon: Icons.female,
                      isSelected: _selectedGender == 'female',
                      onTap: () => setState(() => _selectedGender = 'female'),
                    ),
                    const Gap(12),
                    _GenderOptionChip(
                      label: 'Other',
                      icon: Icons.transgender,
                      isSelected: _selectedGender == 'other',
                      onTap: () => setState(() => _selectedGender = 'other'),
                    ),
                  ],
                ),
                const Gap(24),

                // Date of Birth Field
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    hintText: 'Select your date of birth',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const Gap(32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: authState.isLoading ? null : _saveProfile,
                    child: authState.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const Gap(20),
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
  final VoidCallback onTap;

  const _GenderOptionChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
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
